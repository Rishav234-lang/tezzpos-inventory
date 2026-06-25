const { handleError, NotFoundError } = require('../utils/errors');
const { getPaginationParams, createPaginatedResponse } = require('../utils/pagination');

async function inventoryRoutes(fastify) {
  fastify.addHook('preHandler', fastify.authenticateOwner);
  fastify.addHook('preHandler', fastify.checkSubscription);

  // Current Stock View (aggregated by product)
  fastify.get('/stock', async (request, reply) => {
    try {
      const { page, limit, skip } = getPaginationParams(request.query);
      const { search, categoryId, lowStock } = request.query;
      const companyId = request.user.companyId;

      const where = { companyId, status: 'ACTIVE' };
      if (categoryId) where.categoryId = categoryId;
      if (search) {
        where.OR = [
          { name: { contains: search, mode: 'insensitive' } },
          { sku: { contains: search, mode: 'insensitive' } },
          { barcode: { contains: search, mode: 'insensitive' } },
        ];
      }

      const [products, total] = await Promise.all([
        fastify.prisma.product.findMany({
          where,
          include: {
            category: { select: { name: true } },
            batches: {
              where: { status: 'ACTIVE' },
              select: { availableQuantity: true, purchasePrice: true, mrp: true },
            },
          },
          skip,
          take: limit,
          orderBy: { name: 'asc' },
        }),
        fastify.prisma.product.count({ where }),
      ]);

      let stockData = products.map((p) => {
        const totalStock = p.batches.reduce((sum, b) => sum + b.availableQuantity, 0);
        const stockValue = p.batches.reduce((sum, b) => sum + b.availableQuantity * Number(b.purchasePrice), 0);
        return {
          id: p.id,
          name: p.name,
          sku: p.sku,
          barcode: p.barcode,
          category: p.category?.name,
          unit: p.unit,
          sellingPrice: p.sellingPrice,
          minStockLevel: p.minStockLevel,
          totalStock,
          stockValue,
          isLowStock: totalStock <= p.minStockLevel,
        };
      });

      if (lowStock === 'true') {
        stockData = stockData.filter((s) => s.isLowStock);
      }

      return createPaginatedResponse(stockData, total, page, limit);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Batch-wise Stock View
  fastify.get('/batches', async (request, reply) => {
    try {
      const { page, limit, skip } = getPaginationParams(request.query);
      const { productId, status } = request.query;
      const companyId = request.user.companyId;

      const where = { companyId };
      if (productId) where.productId = productId;
      if (status) where.status = status;

      const { sortBy, sortOrder } = request.query;
      const orderBy = {};
      if (sortBy === 'expiryDate') {
        orderBy[sortBy] = sortOrder || 'asc';
      } else if (sortBy === 'purchasePrice') {
        orderBy[sortBy] = sortOrder || 'asc';
      } else {
        orderBy.purchaseDate = 'desc';
      }

      const [batches, total] = await Promise.all([
        fastify.prisma.batch.findMany({
          where,
          include: {
            product: { select: { id: true, name: true, sku: true } },
            vendor: { select: { id: true, name: true } },
          },
          skip,
          take: limit,
          orderBy,
        }),
        fastify.prisma.batch.count({ where }),
      ]);

      return createPaginatedResponse(batches, total, page, limit);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Stock Adjustment
  fastify.post('/adjust', async (request, reply) => {
    try {
      const { productId, adjustmentType, quantity, reason } = request.body;
      const companyId = request.user.companyId;

      const product = await fastify.prisma.product.findFirst({
        where: { id: productId, companyId },
      });
      if (!product) throw new NotFoundError('Product');

      await fastify.prisma.$transaction(async (tx) => {
        // Record adjustment
        await tx.stockAdjustment.create({
          data: { companyId, productId, adjustmentType, quantity, reason },
        });

        if (adjustmentType === 'INCREASE') {
          // Add to most recent active batch
          const batch = await tx.batch.findFirst({
            where: { companyId, productId, status: 'ACTIVE' },
            orderBy: { purchaseDate: 'desc' },
          });
          if (batch) {
            await tx.batch.update({
              where: { id: batch.id },
              data: { availableQuantity: { increment: quantity } },
            });
          }
        } else {
          // Deduct from oldest batch (FIFO)
          const batches = await tx.batch.findMany({
            where: { companyId, productId, status: 'ACTIVE', availableQuantity: { gt: 0 } },
            orderBy: { purchaseDate: 'asc' },
          });

          let remaining = quantity;
          for (const batch of batches) {
            if (remaining <= 0) break;
            const deduct = Math.min(remaining, batch.availableQuantity);
            await tx.batch.update({
              where: { id: batch.id },
              data: {
                availableQuantity: { decrement: deduct },
                status: batch.availableQuantity - deduct === 0 ? 'DEPLETED' : 'ACTIVE',
              },
            });
            remaining -= deduct;
          }
        }
      });

      return { message: 'Stock adjusted successfully' };
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Stock History (adjustments)
  fastify.get('/adjustments', async (request, reply) => {
    try {
      const { page, limit, skip } = getPaginationParams(request.query);
      const companyId = request.user.companyId;

      const where = { companyId };
      const [adjustments, total] = await Promise.all([
        fastify.prisma.stockAdjustment.findMany({
          where,
          include: { product: { select: { id: true, name: true } } },
          skip,
          take: limit,
          orderBy: { createdAt: 'desc' },
        }),
        fastify.prisma.stockAdjustment.count({ where }),
      ]);

      return createPaginatedResponse(adjustments, total, page, limit);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Low Stock Alert
  fastify.get('/low-stock', async (request, reply) => {
    try {
      const companyId = request.user.companyId;

      const products = await fastify.prisma.product.findMany({
        where: { companyId, status: 'ACTIVE' },
        include: {
          batches: {
            where: { status: 'ACTIVE' },
            select: { availableQuantity: true },
          },
        },
      });

      const lowStockProducts = products
        .map((p) => {
          const totalStock = p.batches.reduce((sum, b) => sum + b.availableQuantity, 0);
          return { id: p.id, name: p.name, sku: p.sku, totalStock, minStockLevel: p.minStockLevel };
        })
        .filter((p) => p.totalStock <= p.minStockLevel)
        .sort((a, b) => a.totalStock - b.totalStock);

      return lowStockProducts;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Near Expiry Products (within 30 days)
  fastify.get('/near-expiry', async (request, reply) => {
    try {
      const { days } = request.query;
      const companyId = request.user.companyId;
      const daysAhead = parseInt(days) || 30;
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + daysAhead);

      const batches = await fastify.prisma.batch.findMany({
        where: {
          companyId,
          status: 'ACTIVE',
          availableQuantity: { gt: 0 },
          expiryDate: { lte: futureDate, gte: new Date() },
        },
        include: {
          product: { select: { id: true, name: true, sku: true } },
          vendor: { select: { name: true } },
        },
        orderBy: { expiryDate: 'asc' },
      });

      return batches;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Inventory Statistics
  fastify.get('/stats', async (request, reply) => {
    try {
      const companyId = request.user.companyId;

      const [totalProducts, activeBatches] = await Promise.all([
        fastify.prisma.product.count({ where: { companyId, status: 'ACTIVE' } }),
        fastify.prisma.batch.findMany({
          where: { companyId, status: 'ACTIVE', availableQuantity: { gt: 0 } },
          select: { availableQuantity: true, purchasePrice: true },
        }),
      ]);

      const totalStockQuantity = activeBatches.reduce((sum, b) => sum + b.availableQuantity, 0);
      const inventoryValue = activeBatches.reduce((sum, b) => sum + b.availableQuantity * Number(b.purchasePrice), 0);

      // Low stock count
      const products = await fastify.prisma.product.findMany({
        where: { companyId, status: 'ACTIVE' },
        include: {
          batches: { where: { status: 'ACTIVE' }, select: { availableQuantity: true } },
        },
      });
      const lowStockCount = products.filter((p) => {
        const stock = p.batches.reduce((sum, b) => sum + b.availableQuantity, 0);
        return stock <= p.minStockLevel;
      }).length;

      return { totalProducts, totalStockQuantity, inventoryValue, lowStockCount };
    } catch (error) {
      handleError(reply, error);
    }
  });
}

module.exports = inventoryRoutes;
