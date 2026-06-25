class ApiConstants {
  static const String baseUrl = 'http://localhost:4000/api';
  
  // Auth
  static const String login = '/auth/login';
  static const String superAdminLogin = '/auth/super-admin/login';
  static const String changePassword = '/auth/change-password';
  static const String me = '/auth/me';

  // Vendors
  static const String vendors = '/vendors';
  
  // Products
  static const String products = '/products';
  static const String categories = '/products/categories';
  
  // Purchases
  static const String purchases = '/purchases';
  
  // Customers
  static const String customers = '/customers';
  
  // Sales
  static const String sales = '/sales';
  
  // Sale Returns
  static const String saleReturns = '/sale-returns';
  
  // Payments
  static const String customerPayments = '/payments/customer';
  static const String vendorPayments = '/payments/vendor';
  static const String paymentsCustomer = '/payments/customer';
  static const String paymentsVendor = '/payments/vendor';
  static const String outstandingCustomers = '/payments/outstanding/customers';
  static const String outstandingVendors = '/payments/outstanding/vendors';
  
  // Inventory
  static const String inventoryStock = '/inventory/stock';
  static const String inventoryBatches = '/inventory/batches';
  static const String inventoryAdjust = '/inventory/adjust';
  static const String inventoryAdjustments = '/inventory/adjustments';
  static const String inventoryLowStock = '/inventory/low-stock';
  static const String inventoryNearExpiry = '/inventory/near-expiry';
  static const String inventoryStats = '/inventory/stats';
  
  // Dashboard
  static const String dashboard = '/dashboard';
  static const String dashboardLowStock = '/dashboard/low-stock';
  static const String dashboardRecentSales = '/dashboard/recent-sales';
  static const String dashboardRecentPurchases = '/dashboard/recent-purchases';
  static const String dashboardDailySales = '/dashboard/charts/daily-sales';
  static const String dashboardDailyPurchases = '/dashboard/charts/daily-purchases';
  static const String dashboardTopProducts = '/dashboard/charts/top-products';
  
  // Reports
  static const String reportSales = '/reports/sales/daily';
  static const String reportPurchases = '/reports/purchases/vendor-wise';
  static const String reportInventory = '/reports/inventory/stock';
  static const String reportFinancial = '/reports/financial/profit';
  static const String reportPurchaseVendor = '/reports/purchases/vendor-wise';
  static const String reportPurchaseProduct = '/reports/purchases/product-wise';
  static const String reportSalesCustomer = '/reports/sales/customer-wise';
  static const String reportSalesProduct = '/reports/sales/product-wise';
  static const String reportSalesDaily = '/reports/sales/daily';
  static const String reportSalesMonthly = '/reports/sales/monthly';
  static const String reportInventoryStock = '/reports/inventory/stock';
  static const String reportInventoryExpiry = '/reports/inventory/expiry';
  static const String reportFinancialProfit = '/reports/financial/profit';

  // Subscriptions
  static const String subscriptionPlans = '/subscriptions/plans';
  static const String subscriptionMe = '/subscriptions/me';
  static const String subscriptionPayments = '/subscriptions/payments';

  // Super Admin
  static const String superAdminDashboard = '/super-admin/dashboard';
  static const String superAdminCompanies = '/super-admin/companies';
  static const String superAdminPlans = '/super-admin/plans';

  static String superAdminCompanyDetail(String id) => '/super-admin/companies/$id';
  static String superAdminCompanyAction(String id, String action) => '/super-admin/companies/$id/$action';
  static String superAdminCompanyPlan(String id) => '/super-admin/companies/$id/plan';
  static String superAdminLoginAs(String id) => '/super-admin/companies/$id/login-as';
  static String superAdminCompanyResetPassword(String id) => '/super-admin/companies/$id/reset-password';
}
