const { handleError, NotFoundError, ValidationError, UnauthorizedError } = require('../utils/errors');
const { razorpay, verifyWebhookSignature, verifyPaymentSignature } = require('../utils/razorpay');

async function subscriptionRoutes(fastify) {
  // Get available plans (public)
  fastify.get('/plans', async (request, reply) => {
    try {
      const plans = await fastify.prisma.plan.findMany({
        where: { status: 'ACTIVE' },
        orderBy: { monthlyPrice: 'asc' },
      });
      return plans;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Get own subscription (Owner)
  fastify.get('/me', { preHandler: [fastify.authenticateOwner] }, async (request, reply) => {
    try {
      const subscription = await fastify.prisma.companySubscription.findUnique({
        where: { companyId: request.user.companyId },
        include: { plan: true },
      });
      if (!subscription) throw new NotFoundError('Subscription');
      return {
        ...subscription,
        razorpayKeyId: process.env.RAZORPAY_KEY_ID,
      };
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Create Razorpay Order for subscription renewal/upgrade
  fastify.post('/create-order', { preHandler: [fastify.authenticateOwner] }, async (request, reply) => {
    try {
      const { planId, billingCycle } = request.body;
      if (!planId || !billingCycle) throw new ValidationError('planId and billingCycle are required');

      const plan = await fastify.prisma.plan.findFirst({ where: { id: planId, status: 'ACTIVE' } });
      if (!plan) throw new NotFoundError('Plan');

      const amount = billingCycle === 'YEARLY'
        ? Number(plan.yearlyPrice)
        : Number(plan.monthlyPrice);

      const order = await razorpay.orders.create({
        amount: Math.round(amount * 100), // paise
        currency: 'INR',
        receipt: `sub_${request.user.companyId}_${Date.now()}`,
        notes: {
          companyId: request.user.companyId,
          planId,
          billingCycle,
        },
      });

      return {
        orderId: order.id,
        amount: order.amount,
        currency: order.currency,
        keyId: process.env.RAZORPAY_KEY_ID,
        planName: plan.name,
        billingCycle,
      };
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Verify payment and activate subscription
  fastify.post('/verify-payment', { preHandler: [fastify.authenticateOwner] }, async (request, reply) => {
    try {
      const { razorpay_order_id, razorpay_payment_id, razorpay_signature, planId, billingCycle } = request.body;

      if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
        throw new ValidationError('Missing payment verification fields');
      }

      const isValid = verifyPaymentSignature({ razorpay_order_id, razorpay_payment_id, razorpay_signature });
      if (!isValid) throw new UnauthorizedError('Payment signature verification failed');

      const plan = await fastify.prisma.plan.findUnique({ where: { id: planId } });
      if (!plan) throw new NotFoundError('Plan');

      const amount = billingCycle === 'YEARLY' ? Number(plan.yearlyPrice) : Number(plan.monthlyPrice);
      const companyId = request.user.companyId;

      const now = new Date();
      const endDate = billingCycle === 'YEARLY'
        ? new Date(now.getFullYear() + 1, now.getMonth(), now.getDate())
        : new Date(now.getFullYear(), now.getMonth() + 1, now.getDate());

      const subscription = await fastify.prisma.$transaction(async (tx) => {
        const sub = await tx.companySubscription.upsert({
          where: { companyId },
          create: {
            companyId,
            planId,
            billingCycle,
            startDate: now,
            endDate,
            status: 'ACTIVE',
            autoRenew: true,
          },
          update: {
            planId,
            billingCycle,
            startDate: now,
            endDate,
            status: 'ACTIVE',
          },
        });

        await tx.subscriptionPayment.create({
          data: {
            companyId,
            subscriptionId: sub.id,
            amount,
            paymentDate: now,
            razorpayPaymentId: razorpay_payment_id,
            status: 'SUCCESS',
          },
        });

        await tx.company.update({ where: { id: companyId }, data: { status: 'ACTIVE' } });

        return sub;
      });

      // Invalidate subscription cache
      if (fastify.subscriptionCache) fastify.subscriptionCache.delete(companyId);

      return { success: true, subscription, message: 'Subscription activated successfully' };
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Get payment history (Owner)
  fastify.get('/payments', { preHandler: [fastify.authenticateOwner] }, async (request, reply) => {
    try {
      const payments = await fastify.prisma.subscriptionPayment.findMany({
        where: { companyId: request.user.companyId },
        include: { subscription: { include: { plan: true } } },
        orderBy: { paymentDate: 'desc' },
      });
      return payments;
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Razorpay Webhook — MUST verify signature before processing
  fastify.post('/webhook/razorpay', {
    config: { rawBody: true },
  }, async (request, reply) => {
    try {
      const signature = request.headers['x-razorpay-signature'];
      if (!signature) {
        return reply.status(400).send({ error: 'Missing webhook signature' });
      }

      const rawBody = request.rawBody || JSON.stringify(request.body);
      if (!verifyWebhookSignature(rawBody, signature)) {
        return reply.status(401).send({ error: 'Invalid webhook signature' });
      }

      const { event, payload } = request.body;

      switch (event) {
        case 'payment.captured': {
          const paymentId = payload.payment.entity.id;
          const notes = payload.payment.entity.notes || {};
          const { companyId, planId, billingCycle } = notes;

          if (companyId && planId) {
            const plan = await fastify.prisma.plan.findUnique({ where: { id: planId } });
            if (plan) {
              const amount = payload.payment.entity.amount / 100;
              const now = new Date();
              const endDate = billingCycle === 'YEARLY'
                ? new Date(now.getFullYear() + 1, now.getMonth(), now.getDate())
                : new Date(now.getFullYear(), now.getMonth() + 1, now.getDate());

              await fastify.prisma.$transaction(async (tx) => {
                const sub = await tx.companySubscription.upsert({
                  where: { companyId },
                  create: { companyId, planId, billingCycle: billingCycle || 'MONTHLY', startDate: now, endDate, status: 'ACTIVE', autoRenew: true },
                  update: { planId, endDate, status: 'ACTIVE' },
                });
                await tx.subscriptionPayment.create({
                  data: { companyId, subscriptionId: sub.id, amount, paymentDate: now, razorpayPaymentId: paymentId, status: 'SUCCESS' },
                });
                await tx.company.update({ where: { id: companyId }, data: { status: 'ACTIVE' } });
              });

              if (fastify.subscriptionCache) fastify.subscriptionCache.delete(companyId);
            }
          }
          break;
        }

        case 'subscription.charged': {
          const razorpaySubId = payload.subscription.entity.id;
          const paymentId = payload.payment.entity.id;
          const amount = payload.payment.entity.amount / 100;

          const subscription = await fastify.prisma.companySubscription.findFirst({
            where: { razorpaySubscriptionId: razorpaySubId },
          });

          if (subscription) {
            const currentEnd = new Date(subscription.endDate);
            const newEnd = subscription.billingCycle === 'MONTHLY'
              ? new Date(currentEnd.setMonth(currentEnd.getMonth() + 1))
              : new Date(currentEnd.setFullYear(currentEnd.getFullYear() + 1));

            await fastify.prisma.$transaction(async (tx) => {
              await tx.subscriptionPayment.create({
                data: { companyId: subscription.companyId, subscriptionId: subscription.id, amount, paymentDate: new Date(), razorpayPaymentId: paymentId, status: 'SUCCESS' },
              });
              await tx.companySubscription.update({ where: { id: subscription.id }, data: { endDate: newEnd, status: 'ACTIVE' } });
            });

            if (fastify.subscriptionCache) fastify.subscriptionCache.delete(subscription.companyId);
          }
          break;
        }

        case 'subscription.halted':
        case 'subscription.cancelled': {
          const razorpaySubId = payload.subscription.entity.id;
          const subscription = await fastify.prisma.companySubscription.findFirst({
            where: { razorpaySubscriptionId: razorpaySubId },
          });

          if (subscription) {
            await fastify.prisma.$transaction(async (tx) => {
              await tx.companySubscription.update({ where: { id: subscription.id }, data: { status: 'SUSPENDED' } });
              await tx.company.update({ where: { id: subscription.companyId }, data: { status: 'SUSPENDED' } });
            });
            if (fastify.subscriptionCache) fastify.subscriptionCache.delete(subscription.companyId);
          }
          break;
        }
      }

      return { status: 'ok' };
    } catch (error) {
      handleError(reply, error);
    }
  });
}

module.exports = subscriptionRoutes;
