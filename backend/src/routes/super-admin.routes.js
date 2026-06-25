const bcrypt = require('bcrypt');
const { companySchema, planSchema } = require('../utils/validators');
const { handleError, NotFoundError, ValidationError } = require('../utils/errors');
const { getPaginationParams, createPaginatedResponse } = require('../utils/pagination');

async function superAdminRoutes(fastify) {
  // All routes require super admin auth
  fastify.addHook('preHandler', fastify.authenticateSuperAdmin);

  // ==================== PLAN MANAGEMENT ====================

  // Create Plan
  fastify.post('/plans', async (request, reply) => {
    try {
      const data = planSchema.parse(request.body);
      const plan = await fastify.prisma.plan.create({ data });
      return reply.status(201).send(plan);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Get All Plans
  fastify.get('/plans', async (request, reply) => {
    try {
      const plans = await fastify.prisma.plan.findMany({
        orderBy: { monthlyPrice: 'asc' },
      });
      return plans;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Update Plan
  fastify.put('/plans/:id', async (request, reply) => {
    try {
      const data = planSchema.parse(request.body);
      const plan = await fastify.prisma.plan.update({
        where: { id: request.params.id },
        data,
      });
      return plan;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // ==================== COMPANY MANAGEMENT ====================

  // Create Company
  fastify.post('/companies', async (request, reply) => {
    try {
      const data = companySchema.parse(request.body);
      console.log('[DEBUG] Create company request:', { name: data.name, email: data.email, ownerEmail: data.ownerEmail });

      const existingCompany = await fastify.prisma.company.findUnique({ where: { email: data.email } });
      if (existingCompany) throw new ValidationError('Company email already exists');

      const existingOwner = await fastify.prisma.owner.findUnique({ where: { email: data.ownerEmail } });
      if (existingOwner) throw new ValidationError('Owner email already exists');

      const hashedPassword = await bcrypt.hash(data.ownerPassword, 10);

      const company = await fastify.prisma.company.create({
        data: {
          name: data.name,
          email: data.email,
          phone: data.phone,
          address: data.address,
          gstNumber: data.gstNumber,
          status: 'ACTIVE',
          owner: {
            create: {
              name: data.ownerName,
              email: data.ownerEmail,
              password: hashedPassword,
            },
          },
        },
        include: { owner: { select: { id: true, name: true, email: true } } },
      });

      console.log('[DEBUG] Company created:', company.id, 'Owner:', company.owner);
      return reply.status(201).send(company);
    } catch (error) {
      console.log('[DEBUG] Company creation error:', error.message);
      handleError(reply, error);
    }
  });

  // Get All Companies
  fastify.get('/companies', async (request, reply) => {
    try {
      const { page, limit, skip } = getPaginationParams(request.query);
      const { status, search } = request.query;

      const where = {};
      if (status) where.status = status;
      if (search) {
        where.OR = [
          { name: { contains: search, mode: 'insensitive' } },
          { email: { contains: search, mode: 'insensitive' } },
        ];
      }

      const [companies, total] = await Promise.all([
        fastify.prisma.company.findMany({
          where,
          include: {
            owner: { select: { id: true, name: true, email: true } },
            subscription: { include: { plan: true } },
          },
          skip,
          take: limit,
          orderBy: { createdAt: 'desc' },
        }),
        fastify.prisma.company.count({ where }),
      ]);

      return createPaginatedResponse(companies, total, page, limit);
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Update Company
  fastify.put('/companies/:id', async (request, reply) => {
    try {
      const { name, email, phone, address, gstNumber, ownerName, ownerEmail } = request.body;
      const company = await fastify.prisma.company.update({
        where: { id: request.params.id },
        data: {
          ...(name != null && { name }),
          ...(email != null && { email }),
          ...(phone !== undefined && { phone }),
          ...(address !== undefined && { address }),
          ...(gstNumber !== undefined && { gstNumber }),
        },
        include: { owner: { select: { id: true, name: true, email: true } } },
      });
      if (ownerName != null || ownerEmail != null) {
        const owner = await fastify.prisma.owner.findUnique({
          where: { companyId: request.params.id },
        });
        if (owner) {
          await fastify.prisma.owner.update({
            where: { id: owner.id },
            data: {
              ...(ownerName != null && { name: ownerName }),
              ...(ownerEmail != null && { email: ownerEmail }),
            },
          });
        }
      }
      return company;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Get Company Details
  fastify.get('/companies/:id', async (request, reply) => {
    try {
      const company = await fastify.prisma.company.findUnique({
        where: { id: request.params.id },
        include: {
          owner: { select: { id: true, name: true, email: true, phone: true } },
          subscription: { include: { plan: true } },
        },
      });
      if (!company) throw new NotFoundError('Company');
      return company;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Approve Company
  fastify.put('/companies/:id/approve', async (request, reply) => {
    try {
      const company = await fastify.prisma.company.update({
        where: { id: request.params.id },
        data: { status: 'ACTIVE' },
      });
      return company;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Suspend Company
  fastify.put('/companies/:id/suspend', async (request, reply) => {
    try {
      const company = await fastify.prisma.company.update({
        where: { id: request.params.id },
        data: { status: 'SUSPENDED' },
      });
      return company;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Activate Company
  fastify.put('/companies/:id/activate', async (request, reply) => {
    try {
      const company = await fastify.prisma.company.update({
        where: { id: request.params.id },
        data: { status: 'ACTIVE' },
      });
      return company;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Reset Owner Password
  fastify.put('/companies/:id/reset-password', async (request, reply) => {
    try {
      const { newPassword } = request.body;
      if (!newPassword || newPassword.length < 6) {
        throw new ValidationError('Password must be at least 6 characters');
      }

      const owner = await fastify.prisma.owner.findUnique({
        where: { companyId: request.params.id },
      });
      if (!owner) throw new NotFoundError('Owner');

      const hashedPassword = await bcrypt.hash(newPassword, 10);
      await fastify.prisma.owner.update({
        where: { id: owner.id },
        data: { password: hashedPassword },
      });

      return { message: 'Password reset successfully' };
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Login As Company (Generate token for company owner)
  fastify.post('/companies/:id/login-as', async (request, reply) => {
    try {
      const owner = await fastify.prisma.owner.findUnique({
        where: { companyId: request.params.id },
        include: { company: true },
      });
      if (!owner) throw new NotFoundError('Owner');

      const token = fastify.jwt.sign({
        id: owner.id,
        email: owner.email,
        companyId: owner.companyId,
        role: 'owner',
        impersonated: true,
      });

      return { token, user: { id: owner.id, email: owner.email, name: owner.name, companyId: owner.companyId } };
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Assign/Change Plan
  fastify.put('/companies/:id/plan', async (request, reply) => {
    try {
      const { planId, billingCycle, customPrice, startDate, endDate } = request.body;

      const plan = await fastify.prisma.plan.findUnique({ where: { id: planId } });
      if (!plan) throw new NotFoundError('Plan');

      const subscription = await fastify.prisma.companySubscription.upsert({
        where: { companyId: request.params.id },
        update: {
          planId,
          billingCycle: billingCycle || 'MONTHLY',
          customPrice: customPrice || null,
          startDate: new Date(startDate || new Date()),
          endDate: new Date(endDate),
          status: 'ACTIVE',
        },
        create: {
          companyId: request.params.id,
          planId,
          billingCycle: billingCycle || 'MONTHLY',
          customPrice: customPrice || null,
          startDate: new Date(startDate || new Date()),
          endDate: new Date(endDate),
          status: 'ACTIVE',
        },
      });

      return subscription;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Super Admin Dashboard Stats
  fastify.get('/dashboard', async (request, reply) => {
    try {
      const [
        totalCompanies,
        activeCompanies,
        trialCompanies,
        suspendedCompanies,
        subscriptionPayments,
      ] = await Promise.all([
        fastify.prisma.company.count(),
        fastify.prisma.company.count({ where: { status: 'ACTIVE' } }),
        fastify.prisma.companySubscription.count({ where: { status: 'TRIAL' } }),
        fastify.prisma.company.count({ where: { status: 'SUSPENDED' } }),
        fastify.prisma.subscriptionPayment.aggregate({
          where: { status: 'SUCCESS' },
          _sum: { amount: true },
        }),
      ]);

      const now = new Date();
      const expiringSubscriptions = await fastify.prisma.companySubscription.count({
        where: {
          endDate: { lte: new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000) },
          status: 'ACTIVE',
        },
      });

      return {
        totalCompanies,
        activeCompanies,
        trialCompanies,
        suspendedCompanies,
        totalRevenue: subscriptionPayments._sum.amount || 0,
        expiringSubscriptions,
      };
    } catch (error) {
      handleError(reply, error);
    }
  });
}

module.exports = superAdminRoutes;
