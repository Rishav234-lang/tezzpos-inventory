class ApiConstants {
  // Change this to your backend URL
  static const String baseUrl = 'https://switch-leslie-province-wanna.trycloudflare.com';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Auth
  static const String ownerLogin = '/api/auth/login';
  static const String superAdminLogin = '/api/auth/super-admin/login';
  static const String changePassword = '/api/auth/change-password';
  static const String me = '/api/auth/me';

  // Super Admin
  static const String superAdminDashboard = '/api/super-admin/dashboard';
  static const String companies = '/api/super-admin/companies';
  static const String plans = '/api/super-admin/plans';

  // Company
  static const String companyProfile = '/api/companies/profile';

  // Dashboard
  static const String dashboard = '/api/dashboard';
  static const String lowStock = '/api/dashboard/low-stock';
  static const String recentSales = '/api/dashboard/recent-sales';
  static const String recentPurchases = '/api/dashboard/recent-purchases';

  // Inventory
  static const String inventoryStock = '/api/inventory/stock';
  static const String inventoryBatches = '/api/inventory/batches';
  static const String inventoryAdjust = '/api/inventory/adjust';
  static const String inventoryLowStock = '/api/inventory/low-stock';
  static const String inventoryNearExpiry = '/api/inventory/near-expiry';
  static const String inventoryStats = '/api/inventory/stats';

  // Products
  static const String products = '/api/products';
  static const String productImageUpload = '/api/products/upload';

  // Categories
  static const String categories = '/api/categories';
  static const String categoryImageUpload = '/api/categories/upload';

  // Sales
  static const String sales = '/api/sales';
  static const String saleReturns = '/api/sale-returns';

  // Purchases
  static const String purchases = '/api/purchases';
  static const String purchaseReturns = '/api/purchase-returns';

  // Vendors
  static const String vendors = '/api/vendors';

  // Customers
  static const String customers = '/api/customers';

  // Payments
  static const String customerPayments = '/api/payments/customers';
  static const String vendorPayments = '/api/payments/vendors';

  // Reports
  static const String reports = '/api/reports';

  // Subscriptions
  static const String subscriptionPlans = '/api/subscriptions/plans';
  static const String mySubscription = '/api/subscriptions/me';
  static const String createOrder = '/api/subscriptions/create-order';
  static const String verifyPayment = '/api/subscriptions/verify-payment';

  // Invoices
  static const String invoices = '/api/invoices';
}
