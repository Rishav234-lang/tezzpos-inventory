const { purchaseReturnSchema } = require('../utils/validators');
const { handleError, NotFoundError, ValidationError } = require('../utils/errors');
const { getPaginationParams, createPaginatedResponse } = require('../utils/pagination');
const { convertPrismaToJson } = require('../utils/convertPrisma');

async function purchaseReturnRoutes(fastify) {
  fastify.addHook('preHandler', fastify.authenticateOwner);
  fastify.addHook('preHandler', fastify.checkSubscription);

  // Create Purchase Return (deduct stock from batches)
  fastify.post('/', async (request, reply) => {
    try {
      const data = purchaseReturnSchema.parse(request.body);
      const companyId = request.user.companyId;

      const result = await fastify.prisma.$transaction(async (tx) => {
        const purchase = await tx.purchase.findFirst({
          where: { id: data.purchaseId, companyId },
          include: { items: true },
        });
        if (!purchase) throw new NotFoundError('Purchase');

        const returnCount = await tx.purchaseReturn.count({ where: { companyId } });
        const returnNumber = `PRET${String(returnCount + 1).padStart(6, '0')}`;

        // Validate return quantities
        for (const item of data.items) {
          const purchaseItem = purchase.items.find((pi) => pi.id === item.purchaseItemId);
          if (!purchaseItem) throw new ValidationError(`Purchase item ${item.purchaseItemId} not found`);
          if (item.quantity > purchaseItem.quantity) {
            throw new ValidationError(`Return quantity exceeds purchased quantity for ${purchaseItem.productId}`);
          }
        }

        const totalAmount = data.items.reduce((sum, item) => sum + item.quantity * item.price, 0);

        const purchaseReturn = await tx.purchaseReturn.create({
          data: {
            companyId,
            purchaseId: data.purchaseId,
            vendorId: purchase.vendorId,
            returnNumber,
            returnDate: new Date(data.returnDate),
            totalAmount,
            refundAmount: data.refundAmount,
            reason: data.reason,
            status: 'COMPLETED',
            items: {
              create: data.items.map((item) => ({
                purchaseItemId: item.purchaseItemId,
                productId: item.productId,
                quantity: item.quantity,
                price: item.price,
                totalAmount: item.quantity * item.price,
              })),
            },
          },
        });

        // Deduct stock from purchase batches (most recent first) using FIFO
        for (const item of data.items) {
          const purchaseItem = purchase.items.find((pi) => pi.id === item.purchaseItemId);
          const batches = await tx.batch.findMany({
            where: { companyId, productId: item.productId, purchaseId: purchase.id, status: 'ACTIVE', availableQuantity: { gt: 0 } },
            orderBy: { purchaseDate: 'desc' },
          });

          let remaining = item.quantity;
          for (const batch of batches) {
            if (remaining <= 0) break;
            const deduct = Math.min(remaining, batch.availableQuantity);
            const newAvailable = batch.availableQuantity - deduct;
            await tx.batch.update({
              where: { id: batch.id },
              data: {
                availableQuantity: newAvailable,
                status: newAvailable === 0 ? 'DEPLETED' : 'ACTIVE',
              },
            });
            remaining -= deduct;
          }

          if (remaining > 0) {
            throw new ValidationError(`Insufficient stock to return ${item.quantity} of ${purchaseItem.productId}. Available: ${item.quantity - remaining}`);
          }
        }

        return tx.purchaseReturn.findUnique({
          where: { id: purchaseReturn.id },
          include: {
            purchase: { select: { invoiceNumber: true } },
            vendor: { select: { id: true, name: true } },
            items: { include: { product: { select: { id: true, name: true } } } },
          },
        });
      });

      return reply.status(201).send(convertPrismaToJson(result));
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Get All Purchase Returns
  fastify.get('/', async (request, reply) => {
    try {
      const { page, limit, skip } = getPaginationParams(request.query);
      const companyId = request.user.companyId;

      const where = { companyId };
      const [returns, total] = await Promise.all([
        fastify.prisma.purchaseReturn.findMany({
          where,
          include: {
            purchase: { select: { invoiceNumber: true } },
            vendor: { select: { id: true, name: true } },
            _count: { select: { items: true } },
          },
          skip,
          take: limit,
          orderBy: { returnDate: 'desc' },
        }),
        fastify.prisma.purchaseReturn.count({ where }),
      ]);

      return createPaginatedResponse(convertPrismaToJson(returns), total, page, limit);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Get Purchase Return by ID
  fastify.get('/:id', async (request, reply) => {
    try {
      const purchaseReturn = await fastify.prisma.purchaseReturn.findFirst({
        where: { id: request.params.id, companyId: request.user.companyId },
        include: {
          purchase: { select: { id: true, invoiceNumber: true } },
          vendor: true,
          items: { include: { product: { select: { id: true, name: true, sku: true } }, purchaseItem: true } },
        },
      });
      if (!purchaseReturn) throw new NotFoundError('Purchase Return');
      return convertPrismaToJson(purchaseReturn);
    } catch (error) {
      handleError(reply, error);
    }
  });
}

module.exports = purchaseReturnRoutes;
