const { purchaseSchema } = require('../utils/validators');
const { handleError, NotFoundError } = require('../utils/errors');
const { getPaginationParams, createPaginatedResponse } = require('../utils/pagination');
const { convertPrismaToJson } = require('../utils/convertPrisma');

async function purchaseRoutes(fastify) {
  fastify.addHook('preHandler', fastify.authenticateOwner);
  fastify.addHook('preHandler', fastify.checkSubscription);

  // Create Purchase (with auto batch creation)
  fastify.post('/', async (request, reply) => {
    try {
      const data = purchaseSchema.parse(request.body);
      const companyId = request.user.companyId;

      const totalAmount = data.items.reduce((sum, item) => sum + item.quantity * item.purchasePrice, 0);
      const balanceAmount = totalAmount - data.paidAmount;
      let status = 'UNPAID';
      if (data.paidAmount >= totalAmount) status = 'PAID';
      else if (data.paidAmount > 0) status = 'PARTIAL';

      const result = await fastify.prisma.$transaction(async (tx) => {
        // Create purchase
        const purchase = await tx.purchase.create({
          data: {
            companyId,
            vendorId: data.vendorId,
            invoiceNumber: data.invoiceNumber,
            purchaseDate: new Date(data.purchaseDate),
            totalAmount,
            paidAmount: data.paidAmount,
            balanceAmount,
            status,
            notes: data.notes,
          },
        });

        // Create purchase items and batches
        for (const item of data.items) {
          const itemTotal = item.quantity * item.purchasePrice;

          await tx.purchaseItem.create({
            data: {
              purchaseId: purchase.id,
              productId: item.productId,
              quantity: item.quantity,
              purchasePrice: item.purchasePrice,
              mrp: item.mrp,
              expiryDate: item.expiryDate ? new Date(item.expiryDate) : null,
              totalAmount: itemTotal,
            },
          });

          // Update product cost price to latest purchase price
          await tx.product.update({
            where: { id: item.productId },
            data: { costPrice: item.purchasePrice },
          });

          // Auto create batch
          const batchCount = await tx.batch.count({ where: { companyId } });
          const batchNumber = `B${String(batchCount + 1).padStart(6, '0')}`;

          await tx.batch.create({
            data: {
              companyId,
              productId: item.productId,
              vendorId: data.vendorId,
              purchaseId: purchase.id,
              batchNumber,
              purchaseDate: new Date(data.purchaseDate),
              purchasePrice: item.purchasePrice,
              mrp: item.mrp,
              expiryDate: item.expiryDate ? new Date(item.expiryDate) : null,
              purchasedQuantity: item.quantity,
              availableQuantity: item.quantity,
              status: 'ACTIVE',
            },
          });
        }

        return tx.purchase.findUnique({
          where: { id: purchase.id },
          include: {
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

  // Get All Purchases
  fastify.get('/', async (request, reply) => {
    try {
      const { page, limit, skip } = getPaginationParams(request.query);
      const { vendorId, status, startDate, endDate, sortOrder } = request.query;
      const companyId = request.user.companyId;

      const where = { companyId };
      if (vendorId) where.vendorId = vendorId;
      if (status) where.status = status;
      if (startDate || endDate) {
        where.purchaseDate = {};
        if (startDate) where.purchaseDate.gte = new Date(startDate);
        if (endDate) where.purchaseDate.lte = new Date(endDate);
      }

      const orderDirection = sortOrder === 'asc' ? 'asc' : 'desc';

      const [purchases, total] = await Promise.all([
        fastify.prisma.purchase.findMany({
          where,
          include: {
            vendor: { select: { id: true, name: true } },
            _count: { select: { items: true } },
          },
          skip,
          take: limit,
          orderBy: { purchaseDate: orderDirection },
        }),
        fastify.prisma.purchase.count({ where }),
      ]);

      return createPaginatedResponse(convertPrismaToJson(purchases), total, page, limit);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Get Purchase by ID
  fastify.get('/:id', async (request, reply) => {
    try {
      const rawPurchase = await fastify.prisma.purchase.findFirst({
        where: { id: request.params.id, companyId: request.user.companyId },
        include: {
          vendor: true,
          items: { include: { product: { select: { id: true, name: true, sku: true } } } },
          batches: true,
          vendorPayments: {
            orderBy: { paymentDate: 'desc' },
          },
        },
      });
      if (!rawPurchase) throw new NotFoundError('Purchase');

      // Convert Decimal fields to numbers for JSON serialization
      return convertPrismaToJson(rawPurchase);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Update Purchase Status/Payment
  fastify.patch('/:id', async (request, reply) => {
    try {
      const { paidAmount, status, notes } = request.body;
      const companyId = request.user.companyId;

      const existing = await fastify.prisma.purchase.findFirst({
        where: { id: request.params.id, companyId },
      });
      if (!existing) throw new NotFoundError('Purchase');

      const newPaid = paidAmount !== undefined ? Number(paidAmount) : existing.paidAmount;
      const newStatus = status || (newPaid >= existing.totalAmount ? 'PAID' : newPaid > 0 ? 'PARTIAL' : 'UNPAID');
      const newBalance = existing.totalAmount - newPaid;

      const updated = await fastify.prisma.purchase.update({
        where: { id: request.params.id },
        data: {
          paidAmount: newPaid,
          status: newStatus,
          balanceAmount: newBalance,
          notes: notes !== undefined ? notes : existing.notes,
        },
        include: {
          vendor: true,
          items: { include: { product: { select: { id: true, name: true, sku: true } } } },
        },
      });

      return convertPrismaToJson(updated);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Search Purchases by Invoice Number
  fastify.get('/search/:invoiceNumber', async (request, reply) => {
    try {
      const purchases = await fastify.prisma.purchase.findMany({
        where: {
          companyId: request.user.companyId,
          invoiceNumber: { contains: request.params.invoiceNumber, mode: 'insensitive' },
        },
        include: { vendor: { select: { id: true, name: true } } },
        take: 10,
      });
      return convertPrismaToJson(purchases);
    } catch (error) {
      handleError(reply, error);
    }
  });
}

module.exports = purchaseRoutes;
