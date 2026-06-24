const { handleError } = require('../utils/errors');

/**
 * Convert an array of flat objects to a CSV string.
 * Headers are derived from the keys of the first row.
 */
function toCSV(rows) {
  if (!rows || rows.length === 0) return '';
  const headers = Object.keys(rows[0]);
  const escape = (val) => {
    if (val === null || val === undefined) return '';
    const str = String(val);
    return str.includes(',') || str.includes('"') || str.includes('\n')
      ? `"${str.replace(/"/g, '""')}"`
      : str;
  };
  const lines = [
    headers.join(','),
    ...rows.map((row) => headers.map((h) => escape(row[h])).join(',')),
  ];
  return lines.join('\r\n');
}

function sendCSV(reply, filename, data) {
  const csv = toCSV(data);
  reply
    .header('Content-Type', 'text/csv; charset=utf-8')
    .header('Content-Disposition', `attachment; filename="${filename}"`)
    .send(csv);
}

async function reportRoutes(fastify) {
  fastify.addHook('preHandler', fastify.authenticateOwner);
  fastify.addHook('preHandler', fastify.checkSubscription);

  // ==================== PURCHASE REPORTS ====================

  // Vendor-wise Purchase Report
  fastify.get('/purchases/vendor-wise', async (request, reply) => {
    try {
      const { startDate, endDate, export: exportFmt } = request.query;
      const companyId = request.user.companyId;

      const where = { companyId };
      if (startDate || endDate) {
        where.purchaseDate = {};
        if (startDate) where.purchaseDate.gte = new Date(startDate);
        if (endDate) where.purchaseDate.lte = new Date(endDate);
      }

      const purchases = await fastify.prisma.purchase.groupBy({
        by: ['vendorId'],
        where,
        _sum: { totalAmount: true, paidAmount: true },
        _count: { id: true },
      });

      const vendorIds = purchases.map((p) => p.vendorId);
      const vendors = await fastify.prisma.vendor.findMany({
        where: { id: { in: vendorIds } },
        select: { id: true, name: true },
      });

      const vendorMap = Object.fromEntries(vendors.map((v) => [v.id, v.name]));

      const data = purchases.map((p) => ({
        vendorId: p.vendorId,
        vendorName: vendorMap[p.vendorId],
        totalPurchases: p._count.id,
        totalAmount: p._sum.totalAmount,
        totalPaid: p._sum.paidAmount,
        outstanding: Number(p._sum.totalAmount) - Number(p._sum.paidAmount),
      }));

      if (exportFmt === 'csv') return sendCSV(reply, 'purchases-vendor-wise.csv', data);
      return data;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Product-wise Purchase Report
  fastify.get('/purchases/product-wise', async (request, reply) => {
    try {
      const { startDate, endDate } = request.query;
      const companyId = request.user.companyId;

      const where = { purchase: { companyId } };
      if (startDate || endDate) {
        where.purchase.purchaseDate = {};
        if (startDate) where.purchase.purchaseDate.gte = new Date(startDate);
        if (endDate) where.purchase.purchaseDate.lte = new Date(endDate);
      }

      const items = await fastify.prisma.purchaseItem.groupBy({
        by: ['productId'],
        where,
        _sum: { quantity: true, totalAmount: true },
        _count: { id: true },
      });

      const productIds = items.map((i) => i.productId);
      const products = await fastify.prisma.product.findMany({
        where: { id: { in: productIds } },
        select: { id: true, name: true, sku: true },
      });

      const productMap = Object.fromEntries(products.map((p) => [p.id, p]));

      const data = items.map((i) => ({
        productId: i.productId,
        productName: productMap[i.productId]?.name,
        sku: productMap[i.productId]?.sku,
        totalQuantity: i._sum.quantity,
        totalAmount: i._sum.totalAmount,
        purchaseCount: i._count.id,
      }));

      if (request.query.export === 'csv') return sendCSV(reply, 'purchases-product-wise.csv', data);
      return data;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // ==================== SALES REPORTS ====================

  // Customer-wise Sales Report
  fastify.get('/sales/customer-wise', async (request, reply) => {
    try {
      const { startDate, endDate } = request.query;
      const companyId = request.user.companyId;

      const where = { companyId, customerId: { not: null } };
      if (startDate || endDate) {
        where.invoiceDate = {};
        if (startDate) where.invoiceDate.gte = new Date(startDate);
        if (endDate) where.invoiceDate.lte = new Date(endDate);
      }

      const sales = await fastify.prisma.sale.groupBy({
        by: ['customerId'],
        where,
        _sum: { totalAmount: true, paidAmount: true },
        _count: { id: true },
      });

      const customerIds = sales.map((s) => s.customerId).filter(Boolean);
      const customers = await fastify.prisma.customer.findMany({
        where: { id: { in: customerIds } },
        select: { id: true, name: true },
      });

      const customerMap = Object.fromEntries(customers.map((c) => [c.id, c.name]));

      const data = sales.map((s) => ({
        customerId: s.customerId,
        customerName: customerMap[s.customerId],
        totalSales: s._count.id,
        totalAmount: s._sum.totalAmount,
        totalPaid: s._sum.paidAmount,
        outstanding: Number(s._sum.totalAmount) - Number(s._sum.paidAmount),
      }));

      if (request.query.export === 'csv') return sendCSV(reply, 'sales-customer-wise.csv', data);
      return data;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Product-wise Sales Report
  fastify.get('/sales/product-wise', async (request, reply) => {
    try {
      const { startDate, endDate } = request.query;
      const companyId = request.user.companyId;

      const where = { sale: { companyId } };
      if (startDate || endDate) {
        where.sale.invoiceDate = {};
        if (startDate) where.sale.invoiceDate.gte = new Date(startDate);
        if (endDate) where.sale.invoiceDate.lte = new Date(endDate);
      }

      const items = await fastify.prisma.saleItem.groupBy({
        by: ['productId'],
        where,
        _sum: { quantity: true, totalAmount: true },
        _count: { id: true },
      });

      const productIds = items.map((i) => i.productId);
      const products = await fastify.prisma.product.findMany({
        where: { id: { in: productIds } },
        select: { id: true, name: true, sku: true },
      });

      const productMap = Object.fromEntries(products.map((p) => [p.id, p]));

      const data = items
        .map((i) => ({
          productId: i.productId,
          productName: productMap[i.productId]?.name,
          sku: productMap[i.productId]?.sku,
          totalQuantitySold: i._sum.quantity,
          totalRevenue: i._sum.totalAmount,
          salesCount: i._count.id,
        }))
        .sort((a, b) => Number(b.totalRevenue) - Number(a.totalRevenue));

      if (request.query.export === 'csv') return sendCSV(reply, 'sales-product-wise.csv', data);
      return data;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Daily Sales Report
  fastify.get('/sales/daily', async (request, reply) => {
    try {
      const { startDate, endDate } = request.query;
      const companyId = request.user.companyId;

      const start = startDate ? new Date(startDate) : new Date(new Date().setDate(new Date().getDate() - 30));
      const end = endDate ? new Date(endDate) : new Date();

      const sales = await fastify.prisma.sale.findMany({
        where: {
          companyId,
          invoiceDate: { gte: start, lte: end },
        },
        select: { invoiceDate: true, totalAmount: true },
        orderBy: { invoiceDate: 'asc' },
      });

      // Group by date
      const dailyMap = {};
      sales.forEach((s) => {
        const dateKey = s.invoiceDate.toISOString().split('T')[0];
        if (!dailyMap[dateKey]) dailyMap[dateKey] = { date: dateKey, totalSales: 0, count: 0 };
        dailyMap[dateKey].totalSales += Number(s.totalAmount);
        dailyMap[dateKey].count += 1;
      });

      const data = Object.values(dailyMap);
      if (request.query.export === 'csv') return sendCSV(reply, 'sales-daily.csv', data);
      return data;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Monthly Sales Report
  fastify.get('/sales/monthly', async (request, reply) => {
    try {
      const { year } = request.query;
      const companyId = request.user.companyId;
      const targetYear = parseInt(year) || new Date().getFullYear();

      const sales = await fastify.prisma.sale.findMany({
        where: {
          companyId,
          invoiceDate: {
            gte: new Date(`${targetYear}-01-01`),
            lte: new Date(`${targetYear}-12-31T23:59:59`),
          },
        },
        select: { invoiceDate: true, totalAmount: true },
      });

      const monthlyData = Array.from({ length: 12 }, (_, i) => ({
        month: i + 1,
        totalSales: 0,
        count: 0,
      }));

      sales.forEach((s) => {
        const month = s.invoiceDate.getMonth();
        monthlyData[month].totalSales += Number(s.totalAmount);
        monthlyData[month].count += 1;
      });

      if (request.query.export === 'csv') return sendCSV(reply, 'sales-monthly.csv', monthlyData);
      return monthlyData;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // ==================== INVENTORY REPORTS ====================

  // Current Stock Report
  fastify.get('/inventory/stock', async (request, reply) => {
    try {
      const companyId = request.user.companyId;

      const products = await fastify.prisma.product.findMany({
        where: { companyId, status: 'ACTIVE' },
        include: {
          category: { select: { name: true } },
          batches: {
            where: { status: 'ACTIVE' },
            select: { availableQuantity: true, purchasePrice: true, mrp: true },
          },
        },
        orderBy: { name: 'asc' },
      });

      const data = products.map((p) => {
        const totalStock = p.batches.reduce((sum, b) => sum + b.availableQuantity, 0);
        const stockValue = p.batches.reduce((sum, b) => sum + b.availableQuantity * Number(b.purchasePrice), 0);
        return {
          id: p.id,
          name: p.name,
          sku: p.sku,
          category: p.category?.name,
          unit: p.unit,
          totalStock,
          stockValue: stockValue.toFixed(2),
          sellingPrice: p.sellingPrice,
          minStockLevel: p.minStockLevel,
          isLowStock: totalStock <= p.minStockLevel,
        };
      });

      if (request.query.export === 'csv') return sendCSV(reply, 'inventory-stock.csv', data);
      return data;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Expiry Report
  fastify.get('/inventory/expiry', async (request, reply) => {
    try {
      const companyId = request.user.companyId;

      const expired = await fastify.prisma.batch.findMany({
        where: {
          companyId,
          availableQuantity: { gt: 0 },
          expiryDate: { lte: new Date() },
        },
        include: {
          product: { select: { name: true, sku: true } },
          vendor: { select: { name: true } },
        },
        orderBy: { expiryDate: 'asc' },
      });

      const data = expired.map((b) => ({
        batchNumber: b.batchNumber,
        productName: b.product?.name,
        sku: b.product?.sku,
        vendorName: b.vendor?.name,
        availableQuantity: b.availableQuantity,
        expiryDate: b.expiryDate ? new Date(b.expiryDate).toLocaleDateString('en-IN') : '',
        purchasePrice: b.purchasePrice,
        mrp: b.mrp,
      }));

      if (request.query.export === 'csv') return sendCSV(reply, 'inventory-expiry.csv', data);
      return expired;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // ==================== FINANCIAL REPORTS ====================

  // Profit Summary
  fastify.get('/financial/profit', async (request, reply) => {
    try {
      const { startDate, endDate } = request.query;
      const companyId = request.user.companyId;

      const dateFilter = {};
      if (startDate) dateFilter.gte = new Date(startDate);
      if (endDate) dateFilter.lte = new Date(endDate);

      const [salesAgg, purchaseAgg] = await Promise.all([
        fastify.prisma.sale.aggregate({
          where: { companyId, ...(Object.keys(dateFilter).length && { invoiceDate: dateFilter }) },
          _sum: { totalAmount: true, discount: true },
        }),
        fastify.prisma.purchase.aggregate({
          where: { companyId, ...(Object.keys(dateFilter).length && { purchaseDate: dateFilter }) },
          _sum: { totalAmount: true },
        }),
      ]);

      const totalSales = Number(salesAgg._sum.totalAmount || 0);
      const totalPurchases = Number(purchaseAgg._sum.totalAmount || 0);
      const totalDiscounts = Number(salesAgg._sum.discount || 0);
      const grossProfit = totalSales - totalPurchases;

      const data = { totalSales, totalPurchases, totalDiscounts, grossProfit };
      if (request.query.export === 'csv') return sendCSV(reply, 'financial-profit.csv', [data]);
      return data;
    } catch (error) {
      handleError(reply, error);
    }
  });
}

module.exports = reportRoutes;
