const authRoutes = require('./auth.routes');
const superAdminRoutes = require('./super-admin.routes');
const companyRoutes = require('./company.routes');
const vendorRoutes = require('./vendor.routes');
const categoryRoutes = require('./category.routes');
const productRoutes = require('./product.routes');
const purchaseRoutes = require('./purchase.routes');
const customerRoutes = require('./customer.routes');
const saleRoutes = require('./sale.routes');
const saleReturnRoutes = require('./sale-return.routes');
const purchaseReturnRoutes = require('./purchase-return.routes');
const paymentRoutes = require('./payment.routes');
const inventoryRoutes = require('./inventory.routes');
const reportRoutes = require('./report.routes');
const dashboardRoutes = require('./dashboard.routes');
const subscriptionRoutes = require('./subscription.routes');
const invoiceRoutes = require('./invoice.routes');

const registerRoutes = async (app) => {
  app.get('/health', async () => ({ status: 'ok', timestamp: new Date().toISOString() }));

  app.register(authRoutes, { prefix: '/api/auth' });
  app.register(superAdminRoutes, { prefix: '/api/super-admin' });
  app.register(companyRoutes, { prefix: '/api/companies' });
  app.register(vendorRoutes, { prefix: '/api/vendors' });
  app.register(categoryRoutes, { prefix: '/api/categories' });
  app.register(productRoutes, { prefix: '/api/products' });
  app.register(purchaseRoutes, { prefix: '/api/purchases' });
  app.register(customerRoutes, { prefix: '/api/customers' });
  app.register(saleRoutes, { prefix: '/api/sales' });
  app.register(saleReturnRoutes, { prefix: '/api/sale-returns' });
  app.register(purchaseReturnRoutes, { prefix: '/api/purchase-returns' });
  app.register(paymentRoutes, { prefix: '/api/payments' });
  app.register(inventoryRoutes, { prefix: '/api/inventory' });
  app.register(reportRoutes, { prefix: '/api/reports' });
  app.register(dashboardRoutes, { prefix: '/api/dashboard' });
  app.register(subscriptionRoutes, { prefix: '/api/subscriptions' });
  app.register(invoiceRoutes, { prefix: '/api/invoices' });
};

module.exports = { registerRoutes };
