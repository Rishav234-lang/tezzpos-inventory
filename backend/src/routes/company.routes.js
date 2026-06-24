const { handleError } = require('../utils/errors');

async function companyRoutes(fastify) {
  fastify.addHook('preHandler', fastify.authenticateOwner);

  // Get own company details
  fastify.get('/me', async (request, reply) => {
    try {
      const company = await fastify.prisma.company.findUnique({
        where: { id: request.user.companyId },
        include: {
          owner: { select: { id: true, name: true, email: true, phone: true } },
          subscription: { include: { plan: true } },
        },
      });
      return company;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Update company details
  fastify.put('/me', async (request, reply) => {
    try {
      const { name, phone, address, gstNumber } = request.body;
      const company = await fastify.prisma.company.update({
        where: { id: request.user.companyId },
        data: { name, phone, address, gstNumber },
      });
      return company;
    } catch (error) {
      handleError(reply, error);
    }
  });
}

module.exports = companyRoutes;
