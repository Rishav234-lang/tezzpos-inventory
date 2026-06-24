const { productSchema, categorySchema } = require('../utils/validators');
const { handleError, NotFoundError, ValidationError } = require('../utils/errors');
const { getPaginationParams, createPaginatedResponse } = require('../utils/pagination');

async function productRoutes(fastify) {
  fastify.addHook('preHandler', fastify.authenticateOwner);
  fastify.addHook('preHandler', fastify.checkSubscription);

  // ==================== CATEGORIES ====================

  fastify.post('/categories', async (request, reply) => {
    try {
      const data = categorySchema.parse(request.body);
      const category = await fastify.prisma.category.create({
        data: { ...data, companyId: request.user.companyId },
      });
      return reply.status(201).send(category);
    } catch (error) {
      handleError(reply, error);
    }
  });

  fastify.get('/categories', async (request, reply) => {
    try {
      const categories = await fastify.prisma.category.findMany({
        where: { companyId: request.user.companyId },
        orderBy: { name: 'asc' },
      });
      return categories;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // ==================== PRODUCTS ====================

  // Create Product
  fastify.post('/', async (request, reply) => {
    try {
      const data = productSchema.parse(request.body);
      const companyId = request.user.companyId;

      // Check SKU uniqueness
      if (data.sku) {
        const existingSku = await fastify.prisma.product.findUnique({
          where: { companyId_sku: { companyId, sku: data.sku } },
        });
        if (existingSku) throw new ValidationError('SKU already exists');
      }

      // Check barcode uniqueness
      if (data.barcode) {
        const existingBarcode = await fastify.prisma.product.findUnique({
          where: { companyId_barcode: { companyId, barcode: data.barcode } },
        });
        if (existingBarcode) throw new ValidationError('Barcode already exists');
      }

      const product = await fastify.prisma.product.create({
        data: { ...data, companyId },
        include: { category: true },
      });
      return reply.status(201).send(product);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Get All Products (optimized with cursor-based pagination option)
  fastify.get('/', async (request, reply) => {
    try {
      const { page, limit, skip } = getPaginationParams(request.query);
      const { search, categoryId, status } = request.query;
      const companyId = request.user.companyId;

      const where = { companyId };
      if (categoryId) where.categoryId = categoryId;
      if (status) where.status = status;
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
          include: { category: { select: { id: true, name: true } } },
          skip,
          take: limit,
          orderBy: { name: 'asc' },
        }),
        fastify.prisma.product.count({ where }),
      ]);

      return createPaginatedResponse(products, total, page, limit);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Get Product by ID
  fastify.get('/:id', async (request, reply) => {
    try {
      const product = await fastify.prisma.product.findFirst({
        where: { id: request.params.id, companyId: request.user.companyId },
        include: {
          category: true,
          batches: {
            where: { status: 'ACTIVE', availableQuantity: { gt: 0 } },
            orderBy: { purchaseDate: 'asc' },
          },
        },
      });
      if (!product) throw new NotFoundError('Product');
      return product;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Get Product by Barcode
  fastify.get('/barcode/:barcode', async (request, reply) => {
    try {
      const product = await fastify.prisma.product.findUnique({
        where: {
          companyId_barcode: {
            companyId: request.user.companyId,
            barcode: request.params.barcode,
          },
        },
        include: { category: true },
      });
      if (!product) throw new NotFoundError('Product');
      return product;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Update Product
  fastify.put('/:id', async (request, reply) => {
    try {
      const data = productSchema.parse(request.body);
      const companyId = request.user.companyId;

      const existing = await fastify.prisma.product.findFirst({
        where: { id: request.params.id, companyId },
      });
      if (!existing) throw new NotFoundError('Product');

      // Check SKU uniqueness (exclude current product)
      if (data.sku && data.sku !== existing.sku) {
        const existingSku = await fastify.prisma.product.findUnique({
          where: { companyId_sku: { companyId, sku: data.sku } },
        });
        if (existingSku) throw new ValidationError('SKU already exists');
      }

      const product = await fastify.prisma.product.update({
        where: { id: request.params.id },
        data,
        include: { category: true },
      });
      return product;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Delete Product
  fastify.delete('/:id', async (request, reply) => {
    try {
      const existing = await fastify.prisma.product.findFirst({
        where: { id: request.params.id, companyId: request.user.companyId },
      });
      if (!existing) throw new NotFoundError('Product');

      // Soft delete - set status to INACTIVE
      await fastify.prisma.product.update({
        where: { id: request.params.id },
        data: { status: 'INACTIVE' },
      });
      return { message: 'Product deactivated successfully' };
    } catch (error) {
      handleError(reply, error);
    }
  });
}

module.exports = productRoutes;
