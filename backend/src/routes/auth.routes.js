const bcrypt = require('bcrypt');
const { loginSchema, changePasswordSchema } = require('../utils/validators');
const { handleError, UnauthorizedError } = require('../utils/errors');

async function authRoutes(fastify) {
  // Super Admin Login
  fastify.post('/super-admin/login', async (request, reply) => {
    try {
      const { email, password } = loginSchema.parse(request.body);

      const admin = await fastify.prisma.superAdmin.findUnique({ where: { email } });
      if (!admin) throw new UnauthorizedError('Invalid credentials');

      const valid = await bcrypt.compare(password, admin.password);
      if (!valid) throw new UnauthorizedError('Invalid credentials');

      const token = fastify.jwt.sign({
        id: admin.id,
        email: admin.email,
        role: 'super_admin',
      });

      return { token, user: { id: admin.id, email: admin.email, name: admin.name, role: 'super_admin' } };
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Owner Login
  fastify.post('/login', async (request, reply) => {
    try {
      const { email, password } = loginSchema.parse(request.body);
      console.log('[DEBUG] Owner login attempt:', email);

      const owner = await fastify.prisma.owner.findUnique({
        where: { email },
        include: { company: true },
      });
      if (!owner) {
        console.log('[DEBUG] Owner not found for email:', email);
        throw new UnauthorizedError('Invalid credentials');
      }
      console.log('[DEBUG] Owner found:', owner.id, 'Company status:', owner.company.status);

      if (owner.company.status === 'PENDING') {
        console.log('[DEBUG] Company is PENDING');
        throw new UnauthorizedError('Company is pending approval');
      }

      const valid = await bcrypt.compare(password, owner.password);
      if (!valid) {
        console.log('[DEBUG] Password mismatch for owner:', owner.id);
        throw new UnauthorizedError('Invalid credentials');
      }
      console.log('[DEBUG] Owner login successful:', owner.id);

      const token = fastify.jwt.sign({
        id: owner.id,
        email: owner.email,
        companyId: owner.companyId,
        role: 'owner',
      });

      return {
        token,
        user: {
          id: owner.id,
          email: owner.email,
          name: owner.name,
          companyId: owner.companyId,
          companyName: owner.company.name,
          companyStatus: owner.company.status,
          role: 'owner',
        },
      };
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Change Password (Owner)
  fastify.put('/change-password', { preHandler: [fastify.authenticateOwner] }, async (request, reply) => {
    try {
      const { currentPassword, newPassword } = changePasswordSchema.parse(request.body);

      const owner = await fastify.prisma.owner.findUnique({ where: { id: request.user.id } });
      if (!owner) throw new UnauthorizedError('User not found');

      const valid = await bcrypt.compare(currentPassword, owner.password);
      if (!valid) throw new UnauthorizedError('Current password is incorrect');

      const hashedPassword = await bcrypt.hash(newPassword, 10);
      await fastify.prisma.owner.update({
        where: { id: request.user.id },
        data: { password: hashedPassword },
      });

      return { message: 'Password changed successfully' };
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Get current user profile
  fastify.get('/me', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    try {
      if (request.user.role === 'super_admin') {
        const admin = await fastify.prisma.superAdmin.findUnique({
          where: { id: request.user.id },
          select: { id: true, email: true, name: true },
        });
        return { ...admin, role: 'super_admin' };
      }

      const owner = await fastify.prisma.owner.findUnique({
        where: { id: request.user.id },
        include: { company: { select: { id: true, name: true, status: true } } },
      });
      return { ...owner, password: undefined, role: 'owner' };
    } catch (error) {
      handleError(reply, error);
    }
  });
}

module.exports = authRoutes;
