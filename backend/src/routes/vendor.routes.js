const { vendorSchema } = require('../utils/validators');
const { handleError, NotFoundError } = require('../utils/errors');
const { getPaginationParams, createPaginatedResponse } = require('../utils/pagination');

async function vendorRoutes(fastify) {
  fastify.addHook('preHandler', fastify.authenticateOwner);
  fastify.addHook('preHandler', fastify.checkSubscription);

  // Create Vendor
  fastify.post('/', async (request, reply) => {
    try {
      const data = vendorSchema.parse(request.body);
      const vendor = await fastify.prisma.vendor.create({
        data: { ...data, companyId: request.user.companyId },
      });
      return reply.status(201).send(vendor);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Get All Vendors
  fastify.get('/', async (request, reply) => {
    try {
      const { page, limit, skip } = getPaginationParams(request.query);
      const { search } = request.query;
      const companyId = request.user.companyId;

      const where = { companyId };
      if (search) {
        where.OR = [
          { name: { contains: search, mode: 'insensitive' } },
          { mobile: { contains: search, mode: 'insensitive' } },
          { gstNumber: { contains: search, mode: 'insensitive' } },
        ];
      }

      const [vendors, total] = await Promise.all([
        fastify.prisma.vendor.findMany({
          where,
          skip,
          take: limit,
          orderBy: { name: 'asc' },
        }),
        fastify.prisma.vendor.count({ where }),
      ]);

      return createPaginatedResponse(vendors, total, page, limit);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Get Vendor by ID
  fastify.get('/:id', async (request, reply) => {
    try {
      const vendor = await fastify.prisma.vendor.findFirst({
        where: { id: request.params.id, companyId: request.user.companyId },
      });
      if (!vendor) throw new NotFoundError('Vendor');
      return vendor;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Update Vendor
  fastify.put('/:id', async (request, reply) => {
    try {
      const data = vendorSchema.parse(request.body);
      const existing = await fastify.prisma.vendor.findFirst({
        where: { id: request.params.id, companyId: request.user.companyId },
      });
      if (!existing) throw new NotFoundError('Vendor');

      const vendor = await fastify.prisma.vendor.update({
        where: { id: request.params.id },
        data,
      });
      return vendor;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Delete Vendor
  fastify.delete('/:id', async (request, reply) => {
    try {
      const existing = await fastify.prisma.vendor.findFirst({
        where: { id: request.params.id, companyId: request.user.companyId },
      });
      if (!existing) throw new NotFoundError('Vendor');

      await fastify.prisma.vendor.delete({ where: { id: request.params.id } });
      return { message: 'Vendor deleted successfully' };
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Vendor Purchase History
  fastify.get('/:id/purchases', async (request, reply) => {
    try {
      const { page, limit, skip } = getPaginationParams(request.query);
      const companyId = request.user.companyId;
      const vendorId = request.params.id;

      const where = { companyId, vendorId };
      const [purchases, total] = await Promise.all([
        fastify.prisma.purchase.findMany({
          where,
          include: { items: { include: { product: { select: { name: true } } } } },
          skip,
          take: limit,
          orderBy: { purchaseDate: 'desc' },
        }),
        fastify.prisma.purchase.count({ where }),
      ]);

      return createPaginatedResponse(purchases, total, page, limit);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Vendor Ledger (payments + purchases)
  fastify.get('/:id/ledger', async (request, reply) => {
    try {
      const companyId = request.user.companyId;
      const vendorId = request.params.id;

      const [purchases, payments] = await Promise.all([
        fastify.prisma.purchase.findMany({
          where: { companyId, vendorId },
          select: { id: true, invoiceNumber: true, purchaseDate: true, totalAmount: true, paidAmount: true, status: true },
          orderBy: { purchaseDate: 'desc' },
        }),
        fastify.prisma.vendorPayment.findMany({
          where: { companyId, vendorId },
          orderBy: { paymentDate: 'desc' },
        }),
      ]);

      const totalPurchaseAmount = purchases.reduce((sum, p) => sum + Number(p.totalAmount), 0);
      const totalPaidAmount = payments.reduce((sum, p) => sum + Number(p.amount), 0);
      const outstandingBalance = totalPurchaseAmount - totalPaidAmount;

      return { purchases, payments, totalPurchaseAmount, totalPaidAmount, outstandingBalance };
    } catch (error) {
      handleError(reply, error);
    }
  });
}

module.exports = vendorRoutes;
