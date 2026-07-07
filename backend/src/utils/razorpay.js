const Razorpay = require('razorpay');
const crypto = require('crypto');

const hasRazorpayConfig =
  Boolean(process.env.RAZORPAY_KEY_ID) &&
  Boolean(process.env.RAZORPAY_KEY_SECRET);

const razorpay = hasRazorpayConfig
  ? new Razorpay({
      key_id: process.env.RAZORPAY_KEY_ID,
      key_secret: process.env.RAZORPAY_KEY_SECRET,
    })
  : null;

/**
 * Verify Razorpay webhook signature.
 * Razorpay signs the raw body with HMAC-SHA256 using RAZORPAY_WEBHOOK_SECRET.
 */
const verifyWebhookSignature = (rawBody, signature) => {
  if (!process.env.RAZORPAY_WEBHOOK_SECRET) return false;
  const expected = crypto
    .createHmac('sha256', process.env.RAZORPAY_WEBHOOK_SECRET)
    .update(rawBody)
    .digest('hex');
  return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(signature));
};

/**
 * Verify Razorpay payment signature after successful checkout.
 * razorpay_order_id + '|' + razorpay_payment_id signed with key_secret.
 */
const verifyPaymentSignature = ({ razorpay_order_id, razorpay_payment_id, razorpay_signature }) => {
  if (!process.env.RAZORPAY_KEY_SECRET) return false;
  const body = `${razorpay_order_id}|${razorpay_payment_id}`;
  const expected = crypto
    .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
    .update(body)
    .digest('hex');
  return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(razorpay_signature));
};

module.exports = {
  razorpay,
  hasRazorpayConfig,
  verifyWebhookSignature,
  verifyPaymentSignature,
};
