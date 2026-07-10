const { customerSchema } = require('../utils/validators');
const { handleError, NotFoundError } = require('../utils/errors');
const { getPaginationParams, createPaginatedResponse } = require('../utils/pagination');
const { convertPrismaToJson } = require('../utils/convertPrisma');

async function customerRoutes(fastify) {
  fastify.addHook('preHandler', fastify.authenticateOwner);
  fastify.addHook('preHandler', fastify.checkSubscription);

  // Create Customer
  fastify.post('/', async (request, reply) => {
    try {
      const data = customerSchema.parse(request.body);
      const customer = await fastify.prisma.customer.create({
        data: { ...data, companyId: request.user.companyId },
      });
      return reply.status(201).send(convertPrismaToJson(customer));
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Get All Customers
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

      const [customers, total] = await Promise.all([
        fastify.prisma.customer.findMany({
          where,
          skip,
          take: limit,
          orderBy: { name: 'asc' },
        }),
        fastify.prisma.customer.count({ where }),
      ]);

      const customerIds = customers.map((c) => c.id);
      const sales = await fastify.prisma.sale.findMany({
        where: { companyId, customerId: { in: customerIds } },
        select: { customerId: true, totalAmount: true, paidAmount: true, invoiceDate: true },
      });

      const salesByCustomer = {};
      for (const s of sales) {
        if (!salesByCustomer[s.customerId]) salesByCustomer[s.customerId] = [];
        salesByCustomer[s.customerId].push(s);
      }

      const enrichedCustomers = customers.map((c) => {
        const customerSales = salesByCustomer[c.id] || [];
        const totalPurchaseAmount = customerSales.reduce((sum, s) => sum + Number(s.totalAmount), 0);
        const totalPaidAmount = customerSales.reduce((sum, s) => sum + Number(s.paidAmount), 0);
        const outstandingBalance = totalPurchaseAmount - totalPaidAmount;
        const lastPurchaseDate = customerSales.length > 0
          ? customerSales.sort((a, b) => new Date(b.invoiceDate) - new Date(a.invoiceDate))[0].invoiceDate
          : null;

        return {
          ...c,
          totalPurchaseAmount,
          totalPaidAmount,
          outstandingBalance,
          lastPurchaseDate,
        };
      });

      return createPaginatedResponse(convertPrismaToJson(enrichedCustomers), total, page, limit);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Get Customer by ID
  fastify.get('/:id', async (request, reply) => {
    try {
      const { companyId } = request.user;
      const customer = await fastify.prisma.customer.findFirst({
        where: { id: request.params.id, companyId },
      });
      if (!customer) throw new NotFoundError('Customer');

      const sales = await fastify.prisma.sale.findMany({
        where: { companyId, customerId: request.params.id },
        select: { totalAmount: true, paidAmount: true, invoiceDate: true },
      });

      const totalPurchaseAmount = sales.reduce((sum, s) => sum + Number(s.totalAmount), 0);
      const totalPaidAmount = sales.reduce((sum, s) => sum + Number(s.paidAmount), 0);
      const outstandingBalance = totalPurchaseAmount - totalPaidAmount;
      const lastPurchaseDate = sales.length > 0
        ? sales.sort((a, b) => new Date(b.invoiceDate) - new Date(a.invoiceDate))[0].invoiceDate
        : null;

      return convertPrismaToJson({
        ...customer,
        totalPurchaseAmount,
        totalPaidAmount,
        outstandingBalance,
        lastPurchaseDate,
      });
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Update Customer
  fastify.put('/:id', async (request, reply) => {
    try {
      const data = customerSchema.parse(request.body);
      const existing = await fastify.prisma.customer.findFirst({
        where: { id: request.params.id, companyId: request.user.companyId },
      });
      if (!existing) throw new NotFoundError('Customer');

      const customer = await fastify.prisma.customer.update({
        where: { id: request.params.id },
        data,
      });
      return convertPrismaToJson(customer);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Delete Customer
  fastify.delete('/:id', async (request, reply) => {
    try {
      const existing = await fastify.prisma.customer.findFirst({
        where: { id: request.params.id, companyId: request.user.companyId },
      });
      if (!existing) throw new NotFoundError('Customer');

      await fastify.prisma.customer.delete({ where: { id: request.params.id } });
      return { message: 'Customer deleted successfully' };
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Customer Sales History
  fastify.get('/:id/sales', async (request, reply) => {
    try {
      const { page, limit, skip } = getPaginationParams(request.query);
      const companyId = request.user.companyId;
      const customerId = request.params.id;

      const where = { companyId, customerId };
      const [sales, total] = await Promise.all([
        fastify.prisma.sale.findMany({
          where,
          include: { _count: { select: { items: true } } },
          skip,
          take: limit,
          orderBy: { invoiceDate: 'desc' },
        }),
        fastify.prisma.sale.count({ where }),
      ]);

      return createPaginatedResponse(convertPrismaToJson(sales), total, page, limit);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Customer Ledger
  fastify.get('/:id/ledger', async (request, reply) => {
    try {
      const companyId = request.user.companyId;
      const customerId = request.params.id;

      const [sales, payments] = await Promise.all([
        fastify.prisma.sale.findMany({
          where: { companyId, customerId },
          select: { id: true, invoiceNumber: true, invoiceDate: true, totalAmount: true, paidAmount: true, status: true },
          orderBy: { invoiceDate: 'desc' },
        }),
        fastify.prisma.customerPayment.findMany({
          where: { companyId, customerId },
          orderBy: { paymentDate: 'desc' },
        }),
      ]);

      const totalSalesAmount = sales.reduce((sum, s) => sum + Number(s.totalAmount), 0);
      const totalPaidAmount = sales.reduce((sum, s) => sum + Number(s.paidAmount), 0);
      const outstandingBalance = totalSalesAmount - totalPaidAmount;

      return convertPrismaToJson({
        sales,
        payments,
        totalSalesAmount,
        totalPaidAmount,
        outstandingBalance,
      });
    } catch (error) {
      handleError(reply, error);
    }
  });
}

module.exports = customerRoutes;
