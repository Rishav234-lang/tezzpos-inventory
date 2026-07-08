// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TezzPOS';

  @override
  String get appName => 'TezzPOS';

  @override
  String get tagline => 'Manage. Track. Analyze. Grow.';

  @override
  String get profile => 'Profile';

  @override
  String get profileDetails => 'Profile Details';

  @override
  String get logout => 'Logout';

  @override
  String get name => 'Name';

  @override
  String get email => 'Email';

  @override
  String get company => 'Company';

  @override
  String get role => 'Role';

  @override
  String get license => 'License';

  @override
  String get licenseAndSubscription => 'License & Subscription';

  @override
  String get accountStatus => 'Account status';

  @override
  String get validTill => 'Valid till';

  @override
  String get subscription => 'Subscription';

  @override
  String get currentSubscriptionData => 'Current Subscription Data';

  @override
  String get subscriptionId => 'Subscription ID';

  @override
  String get plan => 'Plan';

  @override
  String get billingCycle => 'Billing cycle';

  @override
  String get autoRenew => 'Auto renew';

  @override
  String get viewSubscriptionDetails => 'View Subscription Details';

  @override
  String get notAvailable => 'Not available';

  @override
  String get companyNotAvailable => 'Company not available';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get hindi => 'Hindi';

  @override
  String get marathi => 'Marathi';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get continueText => 'Continue';

  @override
  String get getStarted => 'Get Started';

  @override
  String get skip => 'Skip';

  @override
  String get onboardingTitle1 => 'Smart Inventory';

  @override
  String get onboardingDesc1 =>
      'Track every product with batch-level precision. FIFO stock management ensures you never lose track of expiry dates or stock levels.';

  @override
  String get onboardingTitle2 => 'GST Billing';

  @override
  String get onboardingDesc2 =>
      'Generate GST-compliant invoices with auto-calculated CGST, SGST & IGST. Export PDFs instantly and stay tax-ready all year.';

  @override
  String get onboardingTitle3 => 'Grow Your Business';

  @override
  String get onboardingDesc3 =>
      'Real-time dashboards, vendor & customer insights, profit reports, and low-stock alerts — everything to scale smarter.';

  @override
  String get submit => 'Submit';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get search => 'Search';

  @override
  String get noResults => 'No results found';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get loading => 'Loading...';

  @override
  String get retry => 'Retry';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get done => 'Done';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get ok => 'OK';

  @override
  String get welcome => 'Welcome';

  @override
  String welcomeToApp(Object appName) {
    return 'Welcome to $appName';
  }

  @override
  String get selectRoleToContinue => 'Select your role to continue';

  @override
  String get login => 'Login';

  @override
  String get companyLogin => 'Company Login';

  @override
  String get companyLoginSubtitle =>
      'Sign in to manage your store inventory and billing.';

  @override
  String get superAdminLogin => 'Super Admin Login';

  @override
  String get superAdminLoginSubtitle => 'Platform administration access.';

  @override
  String get adminEmailHint => 'admin@tezzpos.com';

  @override
  String get loginAsCompanyOwner => 'Login as Company Owner';

  @override
  String get emailHint => 'owner@company.com';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Enter a valid email';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String passwordMinLength(Object count) {
    return 'Password must be at least $count characters';
  }

  @override
  String get or => 'OR';

  @override
  String get createNewAccount => 'Create New Account';

  @override
  String get loginAsSuperAdmin => 'Login as Super Admin';

  @override
  String get register => 'Register';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get signUp => 'Sign Up';

  @override
  String get signIn => 'Sign In';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get home => 'Home';

  @override
  String get products => 'Products';

  @override
  String get sales => 'Sales';

  @override
  String get purchases => 'Purchases';

  @override
  String get inventory => 'Inventory';

  @override
  String get reports => 'Reports';

  @override
  String get customers => 'Customers';

  @override
  String get vendors => 'Vendors';

  @override
  String get settings => 'Settings';

  @override
  String get about => 'About';

  @override
  String get help => 'Help';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get version => 'Version';

  @override
  String get logoutConfirmation => 'Are you sure you want to logout?';

  @override
  String get subscriptionExpired => 'Subscription Expired';

  @override
  String get subscriptionExpiredMessage =>
      'Your subscription has expired. Renew now to continue using TezzPOS.';

  @override
  String get renewSubscription => 'Renew Subscription';

  @override
  String get enableAutoPay => 'Enable Auto-Pay';

  @override
  String get autoPayAuthorizedSuccessfully =>
      'Auto-pay authorized successfully!';

  @override
  String get autoPaySetupOnlyMobile =>
      'Auto-pay setup is only available on the mobile app.';

  @override
  String get signOut => 'Sign Out';

  @override
  String get needHelp => 'Need help?';

  @override
  String get currentPlan => 'Current Plan';

  @override
  String get unknownPlan => 'Unknown Plan';

  @override
  String billingLabel(Object cycle) {
    return 'Billing: $cycle';
  }

  @override
  String get autoRenewEnabled => 'Auto-renew enabled';

  @override
  String subscriptionEndedOn(Object date) {
    return 'Your subscription ended on $date. Renew now to continue using TezzPOS.';
  }

  @override
  String oneDayOverdue(Object days) {
    return '$days day overdue';
  }

  @override
  String daysOverdue(Object days) {
    return '$days days overdue';
  }

  @override
  String get paymentVerificationFailed =>
      'Payment verification failed. Please contact support.';

  @override
  String get noSubscriptionPlanFound =>
      'No subscription plan found. Please contact support.';

  @override
  String get failedToCreatePaymentOrder =>
      'Failed to create payment order. Please try again.';

  @override
  String get couldNotOpenPaymentPage => 'Could not open payment page.';

  @override
  String get failedToCreateAutoPaySubscription =>
      'Failed to create auto-pay subscription. Please try again.';

  @override
  String get oneTimePayment => 'One-time payment';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get paymentSuccessful => 'Payment successful! Redirecting...';

  @override
  String paymentFailed(Object message) {
    return 'Payment failed: $message';
  }

  @override
  String get paymentCancelled => 'Payment was cancelled.';

  @override
  String get noSubscriptionData => 'No subscription data';

  @override
  String get trial => 'Trial';

  @override
  String get expired => 'Expired';

  @override
  String get suspended => 'Suspended';

  @override
  String get pending => 'Pending';

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get owner => 'Owner';

  @override
  String get superAdmin => 'Super Admin';

  @override
  String get user => 'User';

  @override
  String get companyOwner => 'Company Owner';

  @override
  String get companyOwnerDescription =>
      'Manage inventory, sales, purchases & billing for your store.';

  @override
  String get superAdminDescription =>
      'Manage companies, plans, subscriptions & platform analytics.';

  @override
  String get totalSales => 'Total Sales';

  @override
  String get totalPurchases => 'Total Purchases';

  @override
  String get totalProducts => 'Total Products';

  @override
  String get lowStock => 'Low Stock';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get viewAll => 'View All';

  @override
  String get date => 'Date';

  @override
  String get amount => 'Amount';

  @override
  String get status => 'Status';

  @override
  String get actions => 'Actions';

  @override
  String get category => 'Category';

  @override
  String get price => 'Price';

  @override
  String get quantity => 'Quantity';

  @override
  String get stock => 'Stock';

  @override
  String get addNew => 'Add New';

  @override
  String get create => 'Create';

  @override
  String get update => 'Update';

  @override
  String get remove => 'Remove';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get thisActionCannotBeUndone => 'This action cannot be undone.';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get languageChanged => 'Language changed successfully';
}
