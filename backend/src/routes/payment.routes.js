const { customerPaymentSchema, vendorPaymentSchema } = require('../utils/validators');
const { handleError, NotFoundError, ValidationError } = require('../utils/errors');
const { getPaginationParams, createPaginatedResponse } = require('../utils/pagination');

const PAYMENT_TOLERANCE = 0.01;

const toNumber = (value) => Number(value || 0);

const getInvoiceStatus = (totalAmount, paidAmount) => {
  if (paidAmount >= totalAmount) return 'PAID';
  if (paidAmount > 0) return 'PARTIAL';
  return 'UNPAID';
};

async function applyCustomerPaymentToSales(tx, { companyId, customerId, amount }) {
  const sales = await tx.sale.findMany({
    where: {
      companyId,
      customerId,
      balanceAmount: { gt: 0 },
    },
    orderBy: [{ invoiceDate: 'asc' }, { createdAt: 'asc' }],
  });

  const totalOutstanding = sales.reduce(
    (sum, sale) => sum + Math.max(0, toNumber(sale.balanceAmount)),
    0,
  );

  if (totalOutstanding <= PAYMENT_TOLERANCE) {
    throw new ValidationError('No outstanding sale invoices found for this customer');
  }

  if (amount - totalOutstanding > PAYMENT_TOLERANCE) {
    throw new ValidationError(
      `Payment amount exceeds outstanding balance of Rs ${totalOutstanding.toFixed(2)}`,
    );
  }

  let remainingAmount = amount;

  for (const sale of sales) {
    if (remainingAmount <= PAYMENT_TOLERANCE) break;

    const currentPaid = toNumber(sale.paidAmount);
    const totalAmount = toNumber(sale.totalAmount);
    const currentBalance = Math.max(0, toNumber(sale.balanceAmount));
    const amountToApply = Math.min(currentBalance, remainingAmount);
    const newPaidAmount = currentPaid + amountToApply;
    const newBalanceAmount = Math.max(0, totalAmount - newPaidAmount);

    await tx.sale.update({
      where: { id: sale.id },
      data: {
        paidAmount: newPaidAmount,
        balanceAmount: newBalanceAmount,
        status: getInvoiceStatus(totalAmount, newPaidAmount),
      },
    });

    remainingAmount -= amountToApply;
  }
}

async function applyVendorPaymentToPurchases(tx, { companyId, vendorId, purchaseId, amount }) {
  if (purchaseId) {
    const purchase = await tx.purchase.findFirst({
      where: { id: purchaseId, companyId, vendorId },
    });

    if (!purchase) throw new NotFoundError('Purchase');

    const currentBalance = Math.max(0, toNumber(purchase.balanceAmount));
    if (currentBalance <= PAYMENT_TOLERANCE) {
      throw new ValidationError('This purchase invoice is already fully paid');
    }

    if (amount - currentBalance > PAYMENT_TOLERANCE) {
      throw new ValidationError(
        `Payment amount exceeds purchase balance of Rs ${currentBalance.toFixed(2)}`,
      );
    }

    const newPaidAmount = toNumber(purchase.paidAmount) + amount;
    const totalAmount = toNumber(purchase.totalAmount);

    await tx.purchase.update({
      where: { id: purchase.id },
      data: {
        paidAmount: newPaidAmount,
        balanceAmount: Math.max(0, totalAmount - newPaidAmount),
        status: getInvoiceStatus(totalAmount, newPaidAmount),
      },
    });
    return;
  }

  const purchases = await tx.purchase.findMany({
    where: {
      companyId,
      vendorId,
      balanceAmount: { gt: 0 },
    },
    orderBy: [{ purchaseDate: 'asc' }, { createdAt: 'asc' }],
  });

  const totalOutstanding = purchases.reduce(
    (sum, purchase) => sum + Math.max(0, toNumber(purchase.balanceAmount)),
    0,
  );

  if (totalOutstanding <= PAYMENT_TOLERANCE) {
    throw new ValidationError('No outstanding purchase invoices found for this supplier');
  }

  if (amount - totalOutstanding > PAYMENT_TOLERANCE) {
    throw new ValidationError(
      `Payment amount exceeds outstanding balance of Rs ${totalOutstanding.toFixed(2)}`,
    );
  }

  let remainingAmount = amount;

  for (const purchase of purchases) {
    if (remainingAmount <= PAYMENT_TOLERANCE) break;

    const currentPaid = toNumber(purchase.paidAmount);
    const totalAmount = toNumber(purchase.totalAmount);
    const currentBalance = Math.max(0, toNumber(purchase.balanceAmount));
    const amountToApply = Math.min(currentBalance, remainingAmount);
    const newPaidAmount = currentPaid + amountToApply;
    const newBalanceAmount = Math.max(0, totalAmount - newPaidAmount);

    await tx.purchase.update({
      where: { id: purchase.id },
      data: {
        paidAmount: newPaidAmount,
        balanceAmount: newBalanceAmount,
        status: getInvoiceStatus(totalAmount, newPaidAmount),
      },
    });

    remainingAmount -= amountToApply;
  }
}

async function paymentRoutes(fastify) {
  fastify.addHook('preHandler', fastify.authenticateOwner);
  fastify.addHook('preHandler', fastify.checkSubscription);

  // ==================== CUSTOMER PAYMENTS ====================

  // Receive Payment from Customer
  fastify.post('/customers', async (request, reply) => {
    try {
      const data = customerPaymentSchema.parse(request.body);
      const payment = await fastify.prisma.$transaction(async (tx) => {
        const customer = await tx.customer.findFirst({
          where: { id: data.customerId, companyId: request.user.companyId },
          select: { id: true, name: true },
        });

        if (!customer) throw new NotFoundError('Customer');

        await applyCustomerPaymentToSales(tx, {
          companyId: request.user.companyId,
          customerId: data.customerId,
          amount: toNumber(data.amount),
        });

        return tx.customerPayment.create({
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
      });

      return reply.status(201).send(payment);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Get Customer Payments
  fastify.get('/customers', async (request, reply) => {
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
  fastify.post('/vendors', async (request, reply) => {
    try {
      const data = vendorPaymentSchema.parse(request.body);
      const payment = await fastify.prisma.$transaction(async (tx) => {
        const vendor = await tx.vendor.findFirst({
          where: { id: data.vendorId, companyId: request.user.companyId },
          select: { id: true, name: true },
        });

        if (!vendor) throw new NotFoundError('Vendor');

        await applyVendorPaymentToPurchases(tx, {
          companyId: request.user.companyId,
          vendorId: data.vendorId,
          purchaseId: data.purchaseId,
          amount: toNumber(data.amount),
        });

        return tx.vendorPayment.create({
          data: {
            companyId: request.user.companyId,
            vendorId: data.vendorId,
            purchaseId: data.purchaseId,
            amount: data.amount,
            paymentDate: new Date(data.paymentDate),
            paymentMethod: data.paymentMethod,
            referenceNo: data.referenceNo,
            notes: data.notes,
          },
          include: { vendor: { select: { id: true, name: true } } },
        });
      });

      return reply.status(201).send(payment);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Get Vendor Payments
  fastify.get('/vendors', async (request, reply) => {
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
            select: { totalAmount: true, paidAmount: true, status: true, invoiceNumber: true },
          },
        },
      });

      const outstandingCustomers = customers
        .map((c) => {
          const totalSales = c.sales.reduce((sum, s) => sum + Number(s.totalAmount), 0);
          const totalPaid = c.sales.reduce((sum, s) => sum + Number(s.paidAmount), 0);
          const outstanding = totalSales - totalPaid;
          const unpaidInvoices = c.sales.filter(s => s.status !== 'PAID').map(s => ({ invoiceNumber: s.invoiceNumber, totalAmount: Number(s.totalAmount), paidAmount: Number(s.paidAmount) }));
          return { id: c.id, name: c.name, mobile: c.mobile, totalSales, totalPaid, outstanding, unpaidInvoices };
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
            select: { totalAmount: true, paidAmount: true, status: true, invoiceNumber: true },
          },
        },
      });

      const outstandingVendors = vendors
        .map((v) => {
          const totalPurchases = v.purchases.reduce((sum, p) => sum + Number(p.totalAmount), 0);
          const totalPaid = v.purchases.reduce((sum, p) => sum + Number(p.paidAmount), 0);
          const outstanding = totalPurchases - totalPaid;
          const unpaidInvoices = v.purchases.filter(p => p.status !== 'PAID').map(p => ({ invoiceNumber: p.invoiceNumber, totalAmount: Number(p.totalAmount), paidAmount: Number(p.paidAmount) }));
          return { id: v.id, name: v.name, mobile: v.mobile, totalPurchases, totalPaid, outstanding, unpaidInvoices };
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
