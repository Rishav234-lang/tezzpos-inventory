const { Prisma } = require('@prisma/client');
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

      // Fetch purchase aggregates for returned vendors
      const vendorIds = vendors.map(v => v.id);
      let aggregates = [];
      if (vendorIds.length > 0) {
        aggregates = await fastify.prisma.$queryRaw`
          SELECT
            p.vendor_id AS vendor_id,
            COALESCE(SUM(p.total_amount), 0)::float AS total_purchase_amount,
            COALESCE(SUM(p.paid_amount), 0)::float AS total_paid_amount,
            MAX(p.purchase_date) AS last_purchase_date
          FROM purchases p
          WHERE p.vendor_id IN (${Prisma.join(vendorIds)})
            AND p.company_id = ${companyId}
          GROUP BY p.vendor_id
        `;
      }

      const aggMap = new Map(aggregates.map(a => [a.vendor_id, a]));
      const vendorData = vendors.map(v => {
        const agg = aggMap.get(v.id);
        return {
          ...v,
          totalPurchaseAmount: agg?.total_purchase_amount ?? 0,
          outstandingBalance: (agg?.total_purchase_amount ?? 0) - (agg?.total_paid_amount ?? 0),
          lastPurchaseDate: agg?.last_purchase_date ?? null,
        };
      });

      return createPaginatedResponse(vendorData, total, page, limit);
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
          include: { items: { include: { product: { select: { name: true, sku: true } } } }, batches: { select: { batchNumber: true, expiryDate: true, availableQuantity: true } } },
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

      const [purchasesRaw, paymentsRaw] = await Promise.all([
        fastify.prisma.purchase.findMany({
          where: { companyId, vendorId },
          include: {
            batches: {
              select: { id: true, batchNumber: true, expiryDate: true, availableQuantity: true, purchasePrice: true, status: true },
            },
          },
          orderBy: { purchaseDate: 'desc' },
        }),
        fastify.prisma.vendorPayment.findMany({
          where: { companyId, vendorId },
          orderBy: { paymentDate: 'desc' },
        }),
      ]);

      // Convert Decimal fields to numbers for JSON serialization
      const purchases = purchasesRaw.map(p => ({
        ...p,
        totalAmount: Number(p.totalAmount),
        paidAmount: Number(p.paidAmount),
        balanceAmount: Number(p.balanceAmount),
        batches: p.batches.map(b => ({
          ...b,
          purchasePrice: Number(b.purchasePrice),
        })),
      }));

      const payments = paymentsRaw.map(p => ({
        ...p,
        amount: Number(p.amount),
      }));

      const totalPurchaseAmount = purchases.reduce((sum, p) => sum + p.totalAmount, 0);
      const totalPaidAmount = purchases.reduce((sum, p) => sum + p.paidAmount, 0);
      const outstandingBalance = totalPurchaseAmount - totalPaidAmount;

      return { purchases, payments, totalPurchaseAmount, totalPaidAmount, outstandingBalance };
    } catch (error) {
      handleError(reply, error);
    }
  });
}

module.exports = vendorRoutes;
