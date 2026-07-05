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
        receipt: `sub_${Date.now()}`.substring(0, 40),
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

  // Create Razorpay Subscription for auto-pay
  fastify.post('/create-subscription', { preHandler: [fastify.authenticateOwner] }, async (request, reply) => {
    try {
      const { planId, billingCycle } = request.body;
      if (!planId || !billingCycle) throw new ValidationError('planId and billingCycle are required');

      const plan = await fastify.prisma.plan.findFirst({ where: { id: planId, status: 'ACTIVE' } });
      if (!plan) throw new NotFoundError('Plan');

      const companyId = request.user.companyId;
      const existingSub = await fastify.prisma.companySubscription.findUnique({
        where: { companyId },
        include: { plan: true },
      });
      if (!existingSub) throw new NotFoundError('Subscription');

      // Create Razorpay Plan
      const amount = billingCycle === 'YEARLY'
        ? Number(plan.yearlyPrice)
        : Number(plan.monthlyPrice);

      const period = billingCycle === 'YEARLY' ? 'yearly' : 'monthly';
      const interval = billingCycle === 'YEARLY' ? 1 : 1;
      const totalCount = billingCycle === 'YEARLY' ? 1 : 12;

      const razorpayPlan = await razorpay.plans.create({
        period,
        interval,
        item: {
          name: plan.name,
          amount: Math.round(amount * 100),
          currency: 'INR',
          description: plan.description || `${plan.name} - ${billingCycle}`,
        },
      });

      // Create Razorpay Subscription
      const now = new Date();
      const endDate = billingCycle === 'YEARLY'
        ? new Date(now.getFullYear() + 1, now.getMonth(), now.getDate())
        : new Date(now.getFullYear(), now.getMonth() + 1, now.getDate());

      const razorpaySubscription = await razorpay.subscriptions.create({
        plan_id: razorpayPlan.id,
        customer_notify: 1,
        total_count: totalCount,
        quantity: 1,
        notes: {
          companyId,
          localPlanId: planId,
          billingCycle,
        },
      });

      // Update local subscription
      await fastify.prisma.companySubscription.update({
        where: { companyId },
        data: {
          planId,
          billingCycle,
          razorpaySubscriptionId: razorpaySubscription.id,
          autoRenew: true,
          startDate: now,
          endDate,
          status: 'ACTIVE',
        },
      });

      await fastify.prisma.company.update({
        where: { id: companyId },
        data: { status: 'ACTIVE' },
      });

      // Invalidate cache
      if (fastify.subscriptionCache) fastify.subscriptionCache.delete(companyId);

      return {
        subscriptionId: razorpaySubscription.id,
        status: razorpaySubscription.status,
        shortUrl: razorpaySubscription.short_url,
        keyId: process.env.RAZORPAY_KEY_ID,
        amount: Math.round(amount * 100),
        currency: 'INR',
        planName: plan.name,
        billingCycle,
      };
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Cancel Razorpay Subscription (auto-pay)
  fastify.post('/cancel-subscription', { preHandler: [fastify.authenticateOwner] }, async (request, reply) => {
    try {
      const companyId = request.user.companyId;
      const subscription = await fastify.prisma.companySubscription.findUnique({
        where: { companyId },
      });
      if (!subscription) throw new NotFoundError('Subscription');

      if (subscription.razorpaySubscriptionId) {
        try {
          await razorpay.subscriptions.cancel(subscription.razorpaySubscriptionId);
        } catch (e) {
          console.log('[WARN] Failed to cancel Razorpay subscription:', e.message);
        }
      }

      const updated = await fastify.prisma.companySubscription.update({
        where: { companyId },
        data: { autoRenew: false },
      });

      if (fastify.subscriptionCache) fastify.subscriptionCache.delete(companyId);

      return { success: true, message: 'Auto-pay cancelled successfully', subscription: updated };
    } catch (error) {
      handleError(reply, error);
    }
  });

  // Toggle auto-renew
  fastify.put('/auto-renew', { preHandler: [fastify.authenticateOwner] }, async (request, reply) => {
    try {
      const { autoRenew } = request.body;
      const companyId = request.user.companyId;

      const subscription = await fastify.prisma.companySubscription.update({
        where: { companyId },
        data: { autoRenew: autoRenew ?? true },
      });

      return subscription;
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

        case 'subscription.authorized': {
          const razorpaySubId = payload.subscription.entity.id;
          const subscription = await fastify.prisma.companySubscription.findFirst({
            where: { razorpaySubscriptionId: razorpaySubId },
          });

          if (subscription) {
            await fastify.prisma.$transaction(async (tx) => {
              await tx.companySubscription.update({
                where: { id: subscription.id },
                data: { status: 'ACTIVE' },
              });
              await tx.company.update({
                where: { id: subscription.companyId },
                data: { status: 'ACTIVE' },
              });
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

  // Web checkout page for Flutter web / desktop
  fastify.get('/web-checkout', async (request, reply) => {
    const { orderId, keyId, amount, name, description, email, callbackUrl, billingCycle } = request.query;
    if (!orderId || !keyId) {
      return reply.status(400).send({ error: 'Missing orderId or keyId' });
    }

    const safeCallback = callbackUrl || `${process.env.FRONTEND_URL || 'http://localhost:4000'}/subscription-callback`;

    const html = `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>TezzPOS - Payment</title>
  <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; background: #f5f5f5; }
    .box { text-align: center; background: white; padding: 40px 32px; border-radius: 16px; box-shadow: 0 4px 24px rgba(0,0,0,0.08); max-width: 380px; width: 90%; }
    .logo { width: 56px; height: 56px; background: #1565C0; border-radius: 14px; display: flex; align-items: center; justify-content: center; margin: 0 auto 20px; color: white; font-weight: bold; font-size: 22px; }
    .title { font-size: 20px; font-weight: 700; margin-bottom: 6px; color: #111; }
    .subtitle { color: #666; font-size: 14px; margin-bottom: 24px; }
    .amount { font-size: 32px; font-weight: 700; color: #1565C0; margin-bottom: 4px; }
    .amount-desc { color: #888; font-size: 13px; margin-bottom: 28px; }
    .btn { background: #1565C0; color: white; border: none; padding: 16px; border-radius: 12px; font-size: 16px; font-weight: 600; cursor: pointer; width: 100%; }
    .btn:hover { background: #0d47a1; }
    .btn:disabled { background: #9ca3af; cursor: not-allowed; }
    .secure { margin-top: 16px; font-size: 12px; color: #888; display: flex; align-items: center; justify-content: center; gap: 6px; }
    .error { color: #dc2626; font-size: 14px; margin-top: 12px; padding: 10px; background: #fee2e2; border-radius: 8px; }
  </style>
</head>
<body>
  <div class="box">
    <div class="logo">T</div>
    <div class="title">Complete Payment</div>
    <div class="subtitle">${name || 'TezzPOS'} - ${description || 'Subscription'}</div>
    <div class="amount">₹${Number(amount / 100).toFixed(2)}</div>
    <div class="amount-desc">${billingCycle || 'One-time payment'}</div>
    <button id="payBtn" class="btn" onclick="payNow()">Pay Securely</button>
    <div id="errorBox" style="display:none;"></div>
    <div class="secure">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></svg>
      Secured by Razorpay
    </div>
  </div>
  <script>
    function payNow() {
      var btn = document.getElementById('payBtn');
      btn.disabled = true;
      btn.textContent = 'Please wait...';
      try {
        if (typeof Razorpay === 'undefined') {
          showError('Payment script not loaded. Please check your internet connection and refresh.');
          return;
        }
        var options = {
          key: '${keyId}',
          amount: '${amount}',
          currency: 'INR',
          name: '${name || 'TezzPOS'}',
          description: '${description || 'Subscription'}',
          order_id: '${orderId}',
          prefill: { email: '${email || ''}' },
          theme: { color: '#0D47A1' },
          handler: function(response) {
            var params = new URLSearchParams();
            params.set('razorpay_payment_id', response.razorpay_payment_id);
            params.set('razorpay_order_id', response.razorpay_order_id);
            params.set('razorpay_signature', response.razorpay_signature);
            params.set('status', 'success');
            window.location.href = '${safeCallback}?' + params.toString();
          },
          modal: {
            ondismiss: function() {
              window.location.href = '${safeCallback}?status=cancelled';
            }
          }
        };
        var rzp = new Razorpay(options);
        rzp.open();
      } catch (err) {
        showError('Error: ' + err.message);
      }
    }
    function showError(msg) {
      var box = document.getElementById('errorBox');
      box.textContent = msg;
      box.className = 'error';
      box.style.display = 'block';
      var btn = document.getElementById('payBtn');
      btn.disabled = false;
      btn.textContent = 'Pay Securely';
    }
  </script>
</body>
</html>`;
    reply.type('text/html').send(html);
  });
}

module.exports = subscriptionRoutes;
