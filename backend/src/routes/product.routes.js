const path = require('path');
const fs = require('fs');
const { pipeline } = require('stream/promises');
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
      const companyId = request.user.companyId;
      const categories = await fastify.prisma.category.findMany({
        where: { companyId },
        orderBy: { name: 'asc' },
        include: {
          _count: { select: { products: true } },
        },
      });
      // Flatten _count into itemCount for frontend
      return categories.map((c) => ({
        ...c,
        itemCount: c._count.products,
        _count: undefined,
      }));
    } catch (error) {
      handleError(reply, error);
    }
  });

  fastify.get('/categories/:id', async (request, reply) => {
    try {
      const companyId = request.user.companyId;
      const category = await fastify.prisma.category.findFirst({
        where: { id: request.params.id, companyId },
        include: {
          _count: { select: { products: true } },
        },
      });
      if (!category) throw new NotFoundError('Category');
      return {
        ...category,
        itemCount: category._count.products,
        _count: undefined,
      };
    } catch (error) {
      handleError(reply, error);
    }
  });

  fastify.put('/categories/:id', async (request, reply) => {
    try {
      const companyId = request.user.companyId;
      const data = categorySchema.partial().parse(request.body);
      const category = await fastify.prisma.category.updateMany({
        where: { id: request.params.id, companyId },
        data,
      });
      if (category.count === 0) throw new NotFoundError('Category');
      return { message: 'Category updated' };
    } catch (error) {
      handleError(reply, error);
    }
  });

  fastify.delete('/categories/:id', async (request, reply) => {
    try {
      const companyId = request.user.companyId;
      // Check if category has products
      const productsCount = await fastify.prisma.product.count({
        where: { categoryId: request.params.id, companyId },
      });
      if (productsCount > 0) {
        return reply.status(409).send({
          message: 'Cannot delete category with existing products. Please remove or reassign products first.',
        });
      }
      await fastify.prisma.category.deleteMany({
        where: { id: request.params.id, companyId },
      });
      return { message: 'Category deleted' };
    } catch (error) {
      handleError(reply, error);
    }
  });

  // ==================== PRODUCTS ====================

  // Create Product
  fastify.post('/', async (request, reply) => {
    try {
      let data;
      try {
        data = productSchema.parse(request.body);
      } catch (zodError) {
        const issues = zodError.issues?.map((i) => `${i.path.join('.')}: ${i.message}`).join('; ');
        throw new ValidationError(issues || zodError.message);
      }
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

  // Get All Products
  fastify.get('/', async (request, reply) => {
    try {
      const { page, limit, skip } = getPaginationParams(request.query);
      const { search, categoryId, status, stockFilter } = request.query;
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

      let finalProducts;
      let finalTotal;

      if (stockFilter === 'LOW' || stockFilter === 'OUT_OF_STOCK') {
        // Fetch all matching products (no pagination) so we can filter by computed stock
        const allProducts = await fastify.prisma.product.findMany({
          where,
          include: {
            category: { select: { id: true, name: true } },
            batches: {
              where: { status: 'ACTIVE' },
              select: { availableQuantity: true, purchasePrice: true },
              orderBy: { purchaseDate: 'desc' },
            },
          },
          orderBy: { name: 'asc' },
        });

        const enriched = allProducts.map((p) => {
          const totalStock = p.batches.reduce((sum, b) => sum + b.availableQuantity, 0);
          const latestPurchasePrice = p.batches.length > 0 ? Number(p.batches[0].purchasePrice) : 0;
          return { ...p, totalStock, purchasePrice: latestPurchasePrice, batches: undefined };
        });

        const filtered = stockFilter === 'LOW'
          ? enriched.filter((p) => p.totalStock > 0 && p.totalStock <= p.minStockLevel)
          : enriched.filter((p) => p.totalStock === 0);

        finalTotal = filtered.length;
        finalProducts = filtered.slice(skip, skip + limit);
      } else {
        // Normal pagination when no stock filter
        const [products, total] = await Promise.all([
          fastify.prisma.product.findMany({
            where,
            include: {
              category: { select: { id: true, name: true } },
              batches: {
                where: { status: 'ACTIVE' },
                select: { availableQuantity: true, purchasePrice: true },
                orderBy: { purchaseDate: 'desc' },
              },
            },
            skip,
            take: limit,
            orderBy: { name: 'asc' },
          }),
          fastify.prisma.product.count({ where }),
        ]);

        finalTotal = total;
        finalProducts = products.map((p) => {
          const totalStock = p.batches.reduce((sum, b) => sum + b.availableQuantity, 0);
          const latestPurchasePrice = p.batches.length > 0 ? Number(p.batches[0].purchasePrice) : 0;
          return { ...p, totalStock, purchasePrice: latestPurchasePrice, batches: undefined };
        });
      }

      return createPaginatedResponse(finalProducts, finalTotal, page, limit);
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
      let data;
      try {
        data = productSchema.partial().parse(request.body);
      } catch (zodError) {
        const issues = zodError.issues?.map((i) => `${i.path.join('.')}: ${i.message}`).join('; ');
        throw new ValidationError(issues || zodError.message);
      }
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

  // Upload product image
  fastify.post('/upload', async (request, reply) => {
    try {
      const data = await request.file();
      if (!data) {
        reply.status(400).send({ error: 'No file uploaded' });
        return;
      }

      const allowedTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/jpg'];
      if (!allowedTypes.includes(data.mimetype)) {
        reply.status(400).send({ error: 'Invalid file type. Only JPG, PNG, WEBP allowed' });
        return;
      }

      const uploadsDir = path.join(process.cwd(), 'uploads', 'products');
      if (!fs.existsSync(uploadsDir)) {
        fs.mkdirSync(uploadsDir, { recursive: true });
      }

      const ext = path.extname(data.filename) || '.jpg';
      const filename = `${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`;
      const filepath = path.join(uploadsDir, filename);
      const relativePath = `/uploads/products/${filename}`;

      await pipeline(data.file, fs.createWriteStream(filepath));

      return { path: relativePath };
    } catch (error) {
      console.error('Upload error:', error);
      handleError(reply, error);
    }
  });
}

module.exports = productRoutes;
