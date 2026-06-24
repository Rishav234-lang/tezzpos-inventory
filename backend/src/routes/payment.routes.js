const { customerPaymentSchema, vendorPaymentSchema } = require('../utils/validators');
const { handleError, NotFoundError } = require('../utils/errors');
const { getPaginationParams, createPaginatedResponse } = require('../utils/pagination');

async function paymentRoutes(fastify) {
  fastify.addHook('preHandler', fastify.authenticateOwner);
  fastify.addHook('preHandler', fastify.checkSubscription);

  // ==================== CUSTOMER PAYMENTS ====================

  // Receive Payment from Customer
  fastify.post('/customer', async (request, reply) => {
    try {
      const data = customerPaymentSchema.parse(request.body);
      const payment = await fastify.prisma.customerPayment.create({
        data: {
          companyId: request.user.companyId,
          customerId: data.customerId,
          amount: data.amount,
          paymentDate: new Date(data.paymentDate),
          paymentMethod: data.paymentMethod,
          notes: data.notes,
        },
        include: { customer: { select: { id: true, name: true } } },
      });
      return reply.status(201).send(payment);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Get Customer Payments
  fastify.get('/customer', async (request, reply) => {
    try {
      const { page, limit, skip } = getPaginationParams(request.query);
      const { customerId, startDate, endDate } = request.query;
      const companyId = request.user.companyId;

      const where = { companyId };
      if (customerId) where.customerId = customerId;
      if (startDate || endDate) {
        where.paymentDate = {};
        if (startDate) where.paymentDate.gte = new Date(startDate);
        if (endDate) where.paymentDate.lte = new Date(endDate);
      }

      const [payments, total] = await Promise.all([
        fastify.prisma.customerPayment.findMany({
          where,
          include: { customer: { select: { id: true, name: true } } },
          skip,
          take: limit,
          orderBy: { paymentDate: 'desc' },
        }),
        fastify.prisma.customerPayment.count({ where }),
      ]);

      return createPaginatedResponse(payments, total, page, limit);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // ==================== VENDOR PAYMENTS ====================

  // Make Payment to Vendor
  fastify.post('/vendor', async (request, reply) => {
    try {
      const data = vendorPaymentSchema.parse(request.body);
      const payment = await fastify.prisma.vendorPayment.create({
        data: {
          companyId: request.user.companyId,
          vendorId: data.vendorId,
          amount: data.amount,
          paymentDate: new Date(data.paymentDate),
          paymentMethod: data.paymentMethod,
          notes: data.notes,
        },
        include: { vendor: { select: { id: true, name: true } } },
      });
      return reply.status(201).send(payment);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Get Vendor Payments
  fastify.get('/vendor', async (request, reply) => {
    try {
      const { page, limit, skip } = getPaginationParams(request.query);
      const { vendorId, startDate, endDate } = request.query;
      const companyId = request.user.companyId;

      const where = { companyId };
      if (vendorId) where.vendorId = vendorId;
      if (startDate || endDate) {
        where.paymentDate = {};
        if (startDate) where.paymentDate.gte = new Date(startDate);
        if (endDate) where.paymentDate.lte = new Date(endDate);
      }

      const [payments, total] = await Promise.all([
        fastify.prisma.vendorPayment.findMany({
          where,
          include: { vendor: { select: { id: true, name: true } } },
          skip,
          take: limit,
          orderBy: { paymentDate: 'desc' },
        }),
        fastify.prisma.vendorPayment.count({ where }),
      ]);

      return createPaginatedResponse(payments, total, page, limit);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // ==================== OUTSTANDING TRACKING ====================

  // Customer Outstanding
  fastify.get('/outstanding/customers', async (request, reply) => {
    try {
      const companyId = request.user.companyId;

      const customers = await fastify.prisma.customer.findMany({
        where: { companyId },
        select: {
          id: true,
          name: true,
          mobile: true,
          sales: {
            select: { totalAmount: true },
          },
          payments: {
            select: { amount: true },
          },
        },
      });

      const outstandingCustomers = customers
        .map((c) => {
          const totalSales = c.sales.reduce((sum, s) => sum + Number(s.totalAmount), 0);
          const totalPaid = c.payments.reduce((sum, p) => sum + Number(p.amount), 0);
          const outstanding = totalSales - totalPaid;
          return { id: c.id, name: c.name, mobile: c.mobile, totalSales, totalPaid, outstanding };
        })
        .filter((c) => c.outstanding > 0)
        .sort((a, b) => b.outstanding - a.outstanding);

      return outstandingCustomers;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Vendor Outstanding
  fastify.get('/outstanding/vendors', async (request, reply) => {
    try {
      const companyId = request.user.companyId;

      const vendors = await fastify.prisma.vendor.findMany({
        where: { companyId },
        select: {
          id: true,
          name: true,
          mobile: true,
          purchases: {
            select: { totalAmount: true },
          },
          payments: {
            select: { amount: true },
          },
        },
      });

      const outstandingVendors = vendors
        .map((v) => {
          const totalPurchases = v.purchases.reduce((sum, p) => sum + Number(p.totalAmount), 0);
          const totalPaid = v.payments.reduce((sum, p) => sum + Number(p.amount), 0);
          const outstanding = totalPurchases - totalPaid;
          return { id: v.id, name: v.name, mobile: v.mobile, totalPurchases, totalPaid, outstanding };
        })
        .filter((v) => v.outstanding > 0)
        .sort((a, b) => b.outstanding - a.outstanding);

      return outstandingVendors;
    } catch (error) {
      handleError(reply, error);
    }
  });
}

module.exports = paymentRoutes;
