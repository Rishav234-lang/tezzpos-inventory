const { categorySchema } = require('../utils/validators');
const { handleError, NotFoundError } = require('../utils/errors');

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

      return categories.map((c) => ({
        id: c.id,
        name: c.name,
        description: c.description,
        imageUrl: c.imageUrl,
        status: c.status,
        itemCount: c._count.products,
        createdAt: c.createdAt,
        updatedAt: c.updatedAt,
      }));
    } catch (error) {
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
      return category;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Create category
  fastify.post('/', async (request, reply) => {
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

  // Update category
  fastify.put('/:id', async (request, reply) => {
    try {
      const data = categorySchema.partial().parse(request.body);
      const existing = await fastify.prisma.category.findFirst({
        where: { id: request.params.id, companyId: request.user.companyId },
      });
      if (!existing) throw new NotFoundError('Category');

      const category = await fastify.prisma.category.update({
        where: { id: request.params.id },
        data,
      });
      return category;
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
}

module.exports = categoryRoutes;
