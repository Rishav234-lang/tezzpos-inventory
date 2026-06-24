const { handleError } = require('../utils/errors');

async function dashboardRoutes(fastify) {
  fastify.addHook('preHandler', fastify.authenticateOwner);
  fastify.addHook('preHandler', fastify.checkSubscription);

  // Main Dashboard
  fastify.get('/', async (request, reply) => {
    try {
      const companyId = request.user.companyId;
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);
      const monthStart = new Date(today.getFullYear(), today.getMonth(), 1);

      const [
        totalProducts,
        totalVendors,
        totalCustomers,
        todaySales,
        monthlySales,
        pendingReceivables,
        pendingPayables,
      ] = await Promise.all([
        fastify.prisma.product.count({ where: { companyId, status: 'ACTIVE' } }),
        fastify.prisma.vendor.count({ where: { companyId } }),
        fastify.prisma.customer.count({ where: { companyId } }),
        fastify.prisma.sale.aggregate({
          where: { companyId, invoiceDate: { gte: today, lt: tomorrow } },
          _sum: { totalAmount: true },
          _count: { id: true },
        }),
        fastify.prisma.sale.aggregate({
          where: { companyId, invoiceDate: { gte: monthStart } },
          _sum: { totalAmount: true },
          _count: { id: true },
        }),
        fastify.prisma.sale.aggregate({
          where: { companyId, status: { in: ['UNPAID', 'PARTIAL'] } },
          _sum: { balanceAmount: true },
        }),
        fastify.prisma.purchase.aggregate({
          where: { companyId, status: { in: ['UNPAID', 'PARTIAL'] } },
          _sum: { balanceAmount: true },
        }),
      ]);

      // Inventory value
      const activeBatches = await fastify.prisma.batch.findMany({
        where: { companyId, status: 'ACTIVE', availableQuantity: { gt: 0 } },
        select: { availableQuantity: true, purchasePrice: true },
      });
      const inventoryValue = activeBatches.reduce(
        (sum, b) => sum + b.availableQuantity * Number(b.purchasePrice),
        0
      );

      return {
        stats: {
          totalProducts,
          totalVendors,
          totalCustomers,
          inventoryValue,
          todaySales: Number(todaySales._sum.totalAmount || 0),
          todaySalesCount: todaySales._count.id,
          monthlySales: Number(monthlySales._sum.totalAmount || 0),
          monthlySalesCount: monthlySales._count.id,
          pendingReceivables: Number(pendingReceivables._sum.balanceAmount || 0),
          pendingPayables: Number(pendingPayables._sum.balanceAmount || 0),
        },
      };
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Quick Overview - Low Stock Products (optimized: DB-level aggregation, no N+1)
  fastify.get('/low-stock', async (request, reply) => {
    try {
      const companyId = request.user.companyId;

      // Aggregate available stock per product at DB level
      const stockByProduct = await fastify.prisma.batch.groupBy({
        by: ['productId'],
        where: { companyId, status: 'ACTIVE' },
        _sum: { availableQuantity: true },
      });

      // Build a productId → stock map
      const stockMap = Object.fromEntries(
        stockByProduct.map((r) => [r.productId, r._sum.availableQuantity ?? 0])
      );

      // Fetch only products whose stock is at or below minStockLevel using raw filter
      const productIds = Object.keys(stockMap);
      if (productIds.length === 0) return [];

      const products = await fastify.prisma.product.findMany({
        where: { companyId, status: 'ACTIVE', id: { in: productIds } },
        select: { id: true, name: true, sku: true, unit: true, minStockLevel: true },
      });

      const lowStock = products
        .map((p) => ({ ...p, stock: stockMap[p.id] ?? 0 }))
        .filter((p) => p.stock <= p.minStockLevel)
        .sort((a, b) => a.stock - b.stock)
        .slice(0, 15);

      return lowStock;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Recent Sales
  fastify.get('/recent-sales', async (request, reply) => {
    try {
      const sales = await fastify.prisma.sale.findMany({
        where: { companyId: request.user.companyId },
        include: { customer: { select: { name: true } } },
        orderBy: { createdAt: 'desc' },
        take: 10,
      });
      return sales;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Recent Purchases
  fastify.get('/recent-purchases', async (request, reply) => {
    try {
      const purchases = await fastify.prisma.purchase.findMany({
        where: { companyId: request.user.companyId },
        include: { vendor: { select: { name: true } } },
        orderBy: { createdAt: 'desc' },
        take: 10,
      });
      return purchases;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Daily Sales Chart (last 30 days)
  fastify.get('/charts/daily-sales', async (request, reply) => {
    try {
      const companyId = request.user.companyId;
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const sales = await fastify.prisma.sale.findMany({
        where: { companyId, invoiceDate: { gte: thirtyDaysAgo } },
        select: { invoiceDate: true, totalAmount: true },
        orderBy: { invoiceDate: 'asc' },
      });

      const dailyMap = {};
      for (let i = 0; i < 30; i++) {
        const date = new Date();
        date.setDate(date.getDate() - 29 + i);
        const key = date.toISOString().split('T')[0];
        dailyMap[key] = { date: key, amount: 0, count: 0 };
      }

      sales.forEach((s) => {
        const key = s.invoiceDate.toISOString().split('T')[0];
        if (dailyMap[key]) {
          dailyMap[key].amount += Number(s.totalAmount);
          dailyMap[key].count += 1;
        }
      });

      return Object.values(dailyMap);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Top Selling Products
  fastify.get('/charts/top-products', async (request, reply) => {
    try {
      const companyId = request.user.companyId;

      const items = await fastify.prisma.saleItem.groupBy({
        by: ['productId'],
        where: { sale: { companyId } },
        _sum: { quantity: true, totalAmount: true },
        orderBy: { _sum: { totalAmount: 'desc' } },
        take: 10,
      });

      const productIds = items.map((i) => i.productId);
      const products = await fastify.prisma.product.findMany({
        where: { id: { in: productIds } },
        select: { id: true, name: true },
      });
      const productMap = Object.fromEntries(products.map((p) => [p.id, p.name]));

      return items.map((i) => ({
        productId: i.productId,
        productName: productMap[i.productId],
        totalQuantity: i._sum.quantity,
        totalRevenue: i._sum.totalAmount,
      }));
    } catch (error) {
      handleError(reply, error);
    }
  });
}

module.exports = dashboardRoutes;
