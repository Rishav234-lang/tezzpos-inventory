const { handleError } = require('../utils/errors');

async function dashboardRoutes(fastify) {
  fastify.addHook('preHandler', fastify.authenticateOwner);
  fastify.addHook('preHandler', fastify.checkSubscription);

  // Main Dashboard
  fastify.get('/', async (request, reply) => {
    try {
      const companyId = request.user.companyId;

      // Use UTC-based dates so Prisma comparisons are reliable
      const now = new Date();
      const today = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate()));
      const tomorrow = new Date(today);
      tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);
      const monthStart = new Date(Date.UTC(now.getFullYear(), now.getMonth(), 1));

      fastify.log.info(`[Dashboard] companyId=${companyId} today=${today.toISOString()} tomorrow=${tomorrow.toISOString()} monthStart=${monthStart.toISOString()}`);

      const [
        totalProducts,
        totalVendors,
        totalCustomers,
        todaySales,
        monthlySales,
        todayPurchases,
        monthlyPurchases,
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
        fastify.prisma.purchase.aggregate({
          where: { companyId, purchaseDate: { gte: today, lt: tomorrow } },
          _sum: { totalAmount: true },
        }),
        fastify.prisma.purchase.aggregate({
          where: { companyId, purchaseDate: { gte: monthStart } },
          _sum: { totalAmount: true },
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

      fastify.log.info(`[Dashboard] Results for ${companyId}: products=${totalProducts} vendors=${totalVendors} customers=${totalCustomers} todaySales=${JSON.stringify(todaySales)} monthlySales=${JSON.stringify(monthlySales)} todayPurchases=${JSON.stringify(todayPurchases)}`);

      // Expiring soon count
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + 30);
      const expiringSoonCount = await fastify.prisma.batch.count({
        where: {
          companyId,
          status: 'ACTIVE',
          availableQuantity: { gt: 0 },
          expiryDate: { lte: futureDate, gte: new Date() },
        },
      });

      // Inventory value + low stock count (batch-level stock vs product minStockLevel)
      const [activeBatches, stockByProduct, allActiveProducts] = await Promise.all([
        fastify.prisma.batch.findMany({
          where: { companyId, status: 'ACTIVE', availableQuantity: { gt: 0 } },
          select: { availableQuantity: true, purchasePrice: true },
        }),
        fastify.prisma.batch.groupBy({
          by: ['productId'],
          where: { companyId, status: 'ACTIVE' },
          _sum: { availableQuantity: true },
        }),
        fastify.prisma.product.findMany({
          where: { companyId, status: 'ACTIVE' },
          select: { id: true, minStockLevel: true },
        }),
      ]);

      const stockMap = Object.fromEntries(
        stockByProduct.map((r) => [r.productId, r._sum.availableQuantity ?? 0])
      );
      const lowStockCount = allActiveProducts.filter(
        (p) => (stockMap[p.id] ?? 0) <= (p.minStockLevel ?? 0)
      ).length;

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
          todayPurchases: Number(todayPurchases._sum.totalAmount || 0),
          monthlyPurchases: Number(monthlyPurchases._sum.totalAmount || 0),
          grossProfit: Number(monthlySales._sum.totalAmount || 0) - Number(monthlyPurchases._sum.totalAmount || 0),
          pendingReceivables: Number(pendingReceivables._sum.balanceAmount || 0),
          pendingPayables: Number(pendingPayables._sum.balanceAmount || 0),
          expiringSoonCount,
          lowStockCount,
          todaySalesTarget: 100000,
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
      const now = new Date();
      const thirtyDaysAgo = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate() - 30));

      fastify.log.info(`[Chart/daily-sales] companyId=${companyId} thirtyDaysAgo=${thirtyDaysAgo.toISOString()}`);

      const sales = await fastify.prisma.sale.findMany({
        where: { companyId, invoiceDate: { gte: thirtyDaysAgo } },
        select: { invoiceDate: true, totalAmount: true },
        orderBy: { invoiceDate: 'asc' },
      });

      fastify.log.info(`[Chart/daily-sales] Found ${sales.length} sales for ${companyId}`);

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

  // Daily Purchase Chart (last 30 days)
  fastify.get('/charts/daily-purchases', async (request, reply) => {
    try {
      const companyId = request.user.companyId;
      const now = new Date();
      const thirtyDaysAgo = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate() - 30));

      fastify.log.info(`[Chart/daily-purchases] companyId=${companyId} thirtyDaysAgo=${thirtyDaysAgo.toISOString()}`);

      const purchases = await fastify.prisma.purchase.findMany({
        where: { companyId, purchaseDate: { gte: thirtyDaysAgo } },
        select: { purchaseDate: true, totalAmount: true },
        orderBy: { purchaseDate: 'asc' },
      });

      fastify.log.info(`[Chart/daily-purchases] Found ${purchases.length} purchases for ${companyId}`);

      const dailyMap = {};
      for (let i = 0; i < 30; i++) {
        const date = new Date();
        date.setDate(date.getDate() - 29 + i);
        const key = date.toISOString().split('T')[0];
        dailyMap[key] = { date: key, amount: 0, count: 0 };
      }

      purchases.forEach((p) => {
        const key = p.purchaseDate.toISOString().split('T')[0];
        if (dailyMap[key]) {
          dailyMap[key].amount += Number(p.totalAmount);
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
