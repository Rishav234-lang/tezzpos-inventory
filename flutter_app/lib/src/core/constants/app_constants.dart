class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String chooseRole = '/choose-role';
  static const String companyLogin = '/company-login';
  static const String superAdminLogin = '/super-admin-login';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String categories = '/categories';
  static const String categoryDetail = '/categories/detail';
  static const String addCategory = '/categories/add';
  static const String editCategory = '/categories/edit';

  static const String products = '/products';
  static const String productDetail = '/products/detail';
  static const String addProduct = '/products/add';
  static const String editProduct = '/products/edit';

  static const String vendors = '/vendors';
  static const String vendorDetail = '/vendors/detail';
  static const String addVendor = '/vendors/add';
  static const String editVendor = '/vendors/edit';

  static const String purchases = '/purchases';
  static const String purchaseDetail = '/purchases/detail';
  static const String addPurchase = '/purchases/add';
  static const String editPurchase = '/purchases/edit';
  static const String duplicatePurchase = '/purchases/duplicate';
  static const String purchaseReturn = '/purchases/return';

  static const String customers = '/customers';
  static const String customerDetail = '/customers/detail';
  static const String addCustomer = '/customers/add';
  static const String editCustomer = '/customers/edit';
  static const String receivePayment = '/customers/payment';

  static const String sales = '/sales';
  static const String salesHistory = '/sales/history';
  static const String saleDetail = '/sales/detail';
  static const String billInvoice = '/sales/bill';
  static const String selectSaleCustomer = '/sales/select-customer';
  static const String saleReturn = '/sales/return';
  static const String saleReturnDetail = '/sales/return-detail';

  static const String inventory = '/inventory';
  static const String inventoryDetail = '/inventory/detail';
  static const String stockAdjustment = '/inventory/adjust';
  static const String batchDetail = '/inventory/batch';
  static const String productBatches = '/inventory/batches';
}

class AppStrings {
  static const String appName = 'TezzPOS';
  static const String tagline = 'Manage. Track. Analyze. Grow.';
  static const String companyLoginTitle = 'Company Login';
  static const String superAdminLoginTitle = 'Super Admin Login';
  static const String emailHint = 'Email Address';
  static const String passwordHint = 'Password';
  static const String loginButton = 'Login';
  static const String forgotPassword = 'Forgot Password?';
  static const String continueButton = 'Continue';
  static const String getStarted = 'Get Started';
  static const String skip = 'Skip';
  static const String next = 'Next';
  static const String back = 'Back';
  static const String chooseRoleTitle = 'Welcome to TezzPOS';
  static const String chooseRoleSubtitle = 'Select your role to continue';
  static const String companyOwner = 'Company Owner';
  static const String superAdmin = 'Super Admin';
}

class AppAssets {
  static const String logo = 'assets/logo/tezzpos_logo.png';
  static const String onboarding1 = 'assets/images/onboarding_1.png';
  static const String onboarding2 = 'assets/images/onboarding_2.png';
  static const String onboarding3 = 'assets/images/onboarding_3.png';
}
