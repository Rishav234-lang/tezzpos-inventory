const { saleReturnSchema } = require('../utils/validators');
const { handleError, NotFoundError, ValidationError } = require('../utils/errors');
const { getPaginationParams, createPaginatedResponse } = require('../utils/pagination');

async function saleReturnRoutes(fastify) {
  fastify.addHook('preHandler', fastify.authenticateOwner);
  fastify.addHook('preHandler', fastify.checkSubscription);

  // Create Sale Return (with stock restoration)
  fastify.post('/', async (request, reply) => {
    try {
      const data = saleReturnSchema.parse(request.body);
      const companyId = request.user.companyId;

      const result = await fastify.prisma.$transaction(async (tx) => {
        // Verify sale exists
        const sale = await tx.sale.findFirst({
          where: { id: data.saleId, companyId },
          include: { items: true },
        });
        if (!sale) throw new NotFoundError('Sale');

        // Generate return number
        const returnCount = await tx.saleReturn.count({ where: { companyId } });
        const returnNumber = `RET${String(returnCount + 1).padStart(6, '0')}`;

        // Validate return quantities
        for (const item of data.items) {
          const saleItem = sale.items.find((si) => si.productId === item.productId);
          if (!saleItem) throw new ValidationError(`Product ${item.productId} not found in original sale`);
          if (item.quantity > saleItem.quantity) {
            throw new ValidationError(`Return quantity exceeds sold quantity for product ${item.productId}`);
          }
        }

        const totalAmount = data.items.reduce((sum, item) => sum + item.quantity * item.price, 0);

        // Create return
        const saleReturn = await tx.saleReturn.create({
          data: {
            companyId,
            saleId: data.saleId,
            customerId: sale.customerId,
            returnNumber,
            returnDate: new Date(data.returnDate),
            totalAmount,
            refundAmount: data.refundAmount,
            reason: data.reason,
            status: 'COMPLETED',
            items: {
              create: data.items.map((item) => ({
                productId: item.productId,
                quantity: item.quantity,
                price: item.price,
                totalAmount: item.quantity * item.price,
              })),
            },
          },
        });

        // Restore stock to batches (restore to most recent batch with that product)
        for (const item of data.items) {
          const batch = await tx.batch.findFirst({
            where: { companyId, productId: item.productId },
            orderBy: { purchaseDate: 'desc' },
          });

          if (batch) {
            await tx.batch.update({
              where: { id: batch.id },
              data: {
                availableQuantity: { increment: item.quantity },
                status: 'ACTIVE',
              },
            });
          }
        }

        return tx.saleReturn.findUnique({
          where: { id: saleReturn.id },
          include: {
            sale: { select: { invoiceNumber: true } },
            customer: { select: { id: true, name: true } },
            items: { include: { product: { select: { id: true, name: true } } } },
          },
        });
      });

      return reply.status(201).send(result);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Get All Sale Returns
  fastify.get('/', async (request, reply) => {
    try {
      const { page, limit, skip } = getPaginationParams(request.query);
      const companyId = request.user.companyId;

      const where = { companyId };
      const [returns, total] = await Promise.all([
        fastify.prisma.saleReturn.findMany({
          where,
          include: {
            sale: { select: { invoiceNumber: true } },
            customer: { select: { id: true, name: true } },
            _count: { select: { items: true } },
          },
          skip,
          take: limit,
          orderBy: { returnDate: 'desc' },
        }),
        fastify.prisma.saleReturn.count({ where }),
      ]);

      return createPaginatedResponse(returns, total, page, limit);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Get Sale Return by ID
  fastify.get('/:id', async (request, reply) => {
    try {
      const saleReturn = await fastify.prisma.saleReturn.findFirst({
        where: { id: request.params.id, companyId: request.user.companyId },
        include: {
          sale: { select: { id: true, invoiceNumber: true } },
          customer: true,
          items: { include: { product: { select: { id: true, name: true, sku: true } } } },
        },
      });
      if (!saleReturn) throw new NotFoundError('Sale Return');
      return saleReturn;
    } catch (error) {
      handleError(reply, error);
    }
  });
}

module.exports = saleReturnRoutes;
