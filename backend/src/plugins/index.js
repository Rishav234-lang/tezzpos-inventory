const cors = require('@fastify/cors');
const helmet = require('@fastify/helmet');
const jwt = require('@fastify/jwt');
const rateLimit = require('@fastify/rate-limit');
const swagger = require('@fastify/swagger');
const swaggerUi = require('@fastify/swagger-ui');
const multipart = require('@fastify/multipart');
const staticPlugin = require('@fastify/static');
const path = require('path');
const fs = require('fs');
const prismaPlugin = require('./prisma');

const registerPlugins = async (app) => {
  // In-memory subscription cache: Map<companyId, { status, expiresAt (epoch ms) }>
  const subscriptionCache = new Map();
  const CACHE_TTL_MS = 60_000; // 60 seconds
  app.decorate('subscriptionCache', subscriptionCache);

  await app.register(cors, {
    origin: true,
    credentials: true,
  });

  await app.register(helmet);

  await app.register(rateLimit, {
    max: 100,
    timeWindow: '1 minute',
  });

  await app.register(jwt, {
    secret: process.env.JWT_SECRET || 'fallback-secret-key',
    sign: { expiresIn: process.env.JWT_EXPIRES_IN || '7d' },
  });

  await app.register(swagger, {
    openapi: {
      info: {
        title: 'TezzPOS Inventory API',
        version: '1.0.0',
        description: 'Inventory & Billing Management System API',
      },
      components: {
        securitySchemes: {
          bearerAuth: {
            type: 'http',
            scheme: 'bearer',
            bearerFormat: 'JWT',
          },
        },
      },
    },
  });

  await app.register(swaggerUi, {
    routePrefix: '/docs',
  });

  await app.register(multipart, {
    limits: {
      fileSize: 2 * 1024 * 1024, // 2MB
      files: 1,
    },
  });

  // Ensure uploads directory exists
  const uploadsDir = path.join(process.cwd(), 'uploads');
  if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
  }

  await app.register(staticPlugin, {
    root: uploadsDir,
    prefix: '/uploads/',
    decorateReply: false,
  });

  await app.register(prismaPlugin);

  app.decorate('authenticate', async (request, reply) => {
    try {
      await request.jwtVerify();
    } catch (err) {
      reply.status(401).send({ error: 'Unauthorized' });
    }
  });

  app.decorate('authenticateSuperAdmin', async (request, reply) => {
    try {
      await request.jwtVerify();
      if (request.user.role !== 'super_admin') {
        reply.status(403).send({ error: 'Forbidden: Super Admin access required' });
      }
    } catch (err) {
      reply.status(401).send({ error: 'Unauthorized' });
    }
  });

  app.decorate('authenticateOwner', async (request, reply) => {
    try {
      await request.jwtVerify();
      if (request.user.role !== 'owner') {
        reply.status(403).send({ error: 'Forbidden: Owner access required' });
      }
    } catch (err) {
      reply.status(401).send({ error: 'Unauthorized' });
    }
  });

  app.decorate('checkSubscription', async (request, reply) => {
    try {
      const companyId = request.user.companyId;
      if (!companyId) return;

      const now = Date.now();
      const cached = subscriptionCache.get(companyId);

      let status;
      if (cached && cached.expiresAt > now) {
        status = cached.status;
      } else {
        const subscription = await app.prisma.companySubscription.findUnique({
          where: { companyId },
          select: { status: true, endDate: true },
        });

        // No subscription = grace period / trial mode, allow access
        if (!subscription) {
          subscriptionCache.set(companyId, { status: 'TRIAL', expiresAt: now + CACHE_TTL_MS });
          return;
        }

        // Auto-expire if end date passed
        const effectiveStatus = subscription.endDate < new Date() && subscription.status === 'ACTIVE'
          ? 'EXPIRED'
          : subscription.status;

        subscriptionCache.set(companyId, { status: effectiveStatus, expiresAt: now + CACHE_TTL_MS });
        status = effectiveStatus;
      }

      if (status === 'SUSPENDED' || status === 'EXPIRED') {
        reply.status(403).send({
          error: 'Subscription expired or suspended. Please renew your subscription.',
          subscriptionStatus: status,
        });
      }
    } catch (err) {
      reply.status(500).send({ error: 'Subscription check failed' });
    }
  });
};

module.exports = { registerPlugins };
