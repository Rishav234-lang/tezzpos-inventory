const path = require('path');
const fs = require('fs');
const { pipeline } = require('stream/promises');
const { categorySchema } = require('../utils/validators');
const { handleError, NotFoundError, ValidationError } = require('../utils/errors');
const { convertPrismaToJson } = require('../utils/convertPrisma');

async function categoryRoutes(fastify, options) {
  fastify.addHook('onRequest', fastify.authenticate);

  // List all categories for company
  fastify.get('/', async (request, reply) => {
    try {
      const { search, status } = request.query;
      const companyId = request.user.companyId;

      const where = { companyId };
      if (search) {
        where.name = { contains: search, mode: 'insensitive' };
      }
      if (status) {
        where.status = status;
      }

      const categories = await fastify.prisma.category.findMany({
        where,
        orderBy: { name: 'asc' },
        include: {
          _count: { select: { products: true } },
        },
      });

      return convertPrismaToJson(categories.map((c) => ({
        id: c.id,
        name: c.name,
        description: c.description,
        imageUrl: c.imageUrl,
        status: c.status,
        itemCount: c._count.products,
        createdAt: c.createdAt,
        updatedAt: c.updatedAt,
      })));
    } catch (error) {
      console.error('GET /api/categories error:', error);
      handleError(reply, error);
    }
  });

  // Get single category with products
  fastify.get('/:id', async (request, reply) => {
    try {
      const category = await fastify.prisma.category.findFirst({
        where: { id: request.params.id, companyId: request.user.companyId },
        include: {
          products: {
            select: {
              id: true,
              name: true,
              sku: true,
              barcode: true,
              sellingPrice: true,
              status: true,
            },
            orderBy: { name: 'asc' },
          },
        },
      });
      if (!category) throw new NotFoundError('Category');
      return convertPrismaToJson({
        ...category,
        itemCount: category.products.length,
      });
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Create category
  fastify.post('/', async (request, reply) => {
    try {
      let data;
      try {
        data = categorySchema.parse(request.body);
      } catch (zodError) {
        const issues = zodError.issues?.map((i) => `${i.path.join('.')}: ${i.message}`).join('; ');
        throw new ValidationError(issues || zodError.message);
      }
      const category = await fastify.prisma.category.create({
        data: { ...data, companyId: request.user.companyId },
      });
      return reply.status(201).send(convertPrismaToJson(category));
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Update category
  fastify.put('/:id', async (request, reply) => {
    try {
      let data;
      try {
        data = categorySchema.partial().parse(request.body);
      } catch (zodError) {
        const issues = zodError.issues?.map((i) => `${i.path.join('.')}: ${i.message}`).join('; ');
        throw new ValidationError(issues || zodError.message);
      }
      const existing = await fastify.prisma.category.findFirst({
        where: { id: request.params.id, companyId: request.user.companyId },
      });
      if (!existing) throw new NotFoundError('Category');

      const category = await fastify.prisma.category.update({
        where: { id: request.params.id },
        data,
      });
      return convertPrismaToJson(category);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Delete category
  fastify.delete('/:id', async (request, reply) => {
    try {
      const existing = await fastify.prisma.category.findFirst({
        where: { id: request.params.id, companyId: request.user.companyId },
      });
      if (!existing) throw new NotFoundError('Category');

      await fastify.prisma.category.delete({
        where: { id: request.params.id },
      });
      return reply.status(204).send();
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Upload category image
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

      const uploadsDir = path.join(process.cwd(), 'uploads', 'categories');
      if (!fs.existsSync(uploadsDir)) {
        fs.mkdirSync(uploadsDir, { recursive: true });
      }

      const ext = path.extname(data.filename) || '.jpg';
      const filename = `${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`;
      const filepath = path.join(uploadsDir, filename);
      const relativePath = `/uploads/categories/${filename}`;

      await pipeline(data.file, fs.createWriteStream(filepath));

      return { path: relativePath };
    } catch (error) {
      console.error('Upload error:', error);
      handleError(reply, error);
    }
  });
}

module.exports = categoryRoutes;
