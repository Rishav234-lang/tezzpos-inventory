import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../features/auth/presentation/screens/company_login_screen.dart';
import '../features/auth/presentation/screens/company_registration_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/subscription/presentation/screens/subscription_expired_screen.dart';
import '../features/subscription/presentation/screens/subscription_management_screen.dart';
import '../features/category/presentation/screens/add_edit_category_screen.dart';
import '../features/category/presentation/screens/categories_screen.dart';
import '../features/category/presentation/screens/category_detail_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/simple_flow/presentation/screens/simple_inventory_flow_screen.dart';
import '../features/product/presentation/screens/add_edit_product_screen.dart';
import '../features/product/presentation/screens/product_detail_screen.dart';
import '../features/product/presentation/screens/products_screen.dart';
import '../features/inventory/presentation/screens/batch_detail_screen.dart';
import '../features/inventory/presentation/screens/inventory_detail_screen.dart';
import '../features/inventory/presentation/screens/inventory_screen.dart';
import '../features/inventory/presentation/screens/product_batches_screen.dart';
import '../features/inventory/presentation/screens/stock_adjustment_screen.dart';
import '../features/customer/presentation/screens/add_edit_customer_screen.dart';
import '../features/customer/presentation/screens/customer_detail_screen.dart';
import '../features/customer/presentation/screens/customers_screen.dart';
import '../features/customer/presentation/screens/receive_payment_screen.dart';
import '../features/vendor/presentation/screens/add_edit_vendor_screen.dart';
import '../features/vendor/presentation/screens/vendor_detail_screen.dart';
import '../features/purchase/presentation/screens/purchase_detail_screen.dart';
import '../features/purchase/presentation/screens/purchase_list_screen.dart';
import '../features/purchase/presentation/screens/purchase_return_screen.dart';
import '../features/sale/presentation/screens/bill_invoice_screen.dart';
import '../features/sale/presentation/screens/sale_returns_history_screen.dart';
import '../features/sale/presentation/screens/create_sale_return_screen.dart';
import '../features/sale/presentation/screens/sale_detail_screen.dart';
import '../features/sale/presentation/screens/sale_return_detail_screen.dart';
import '../features/sale/presentation/screens/sales_history_screen.dart';
import '../features/super_admin/presentation/screens/add_edit_company_screen.dart';
import '../features/super_admin/presentation/screens/add_edit_plan_screen.dart';
import '../features/super_admin/presentation/screens/assign_plan_screen.dart';
import '../features/super_admin/presentation/screens/companies_list_screen.dart';
import '../features/super_admin/presentation/screens/company_detail_screen.dart';
import '../features/super_admin/presentation/screens/plans_list_screen.dart';
import '../features/super_admin/presentation/screens/super_admin_dashboard_screen.dart';
import '../features/vendor/presentation/screens/vendors_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import 'providers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      // Redirect /category to /categories
      if (state.matchedLocation == '/category') {
        return AppRoutes.categories;
      }

      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;
      final isAuthRoute =
          state.matchedLocation == AppRoutes.chooseRole ||
          state.matchedLocation == AppRoutes.companyLogin ||
          state.matchedLocation == AppRoutes.companyRegister ||
          state.matchedLocation == AppRoutes.superAdminLogin ||
          state.matchedLocation == AppRoutes.forgotPassword;
      final isSubscriptionExpiredRoute =
          state.matchedLocation == AppRoutes.subscriptionExpired;
      final isSubscriptionManagementRoute =
          state.matchedLocation == AppRoutes.subscriptionManagement;

      final isAuthenticated = authState.valueOrNull?.isAuthenticated ?? false;
      final isSuperAdmin = authState.valueOrNull?.user?.isSuperAdmin ?? false;

      // Read onboarding status directly from prefs to avoid stale provider state
      final prefs = ref.read(sharedPreferencesProvider);
      final hasSeenOnboarding = prefs.getBool('onboarding_complete') ?? false;

      // Still loading auth state - stay on splash
      if (authState.isLoading) return isSplash ? null : AppRoutes.splash;

      // Keep the visible auth flow focused on company login only.
      if (!isAuthenticated &&
          (state.matchedLocation == AppRoutes.chooseRole ||
              state.matchedLocation == AppRoutes.superAdminLogin)) {
        return AppRoutes.companyLogin;
      }

      // Check subscription expiry for owner
      final user = authState.valueOrNull?.user;
      final isOwner = user?.isOwner ?? false;
      final subscriptionStatus = user?.subscriptionStatus;
      final subscriptionEndDate = user?.subscriptionEndDate;

      bool isSubscriptionExpired = false;
      if (isOwner && subscriptionStatus != null) {
        if (subscriptionStatus == 'EXPIRED' ||
            subscriptionStatus == 'SUSPENDED') {
          isSubscriptionExpired = true;
        } else if (subscriptionEndDate != null &&
            subscriptionEndDate.isBefore(DateTime.now())) {
          isSubscriptionExpired = true;
        }
      }

      // Block expired subscriptions from non-allowed routes
      if (isAuthenticated &&
          isSubscriptionExpired &&
          !isSubscriptionExpiredRoute &&
          !isSubscriptionManagementRoute &&
          !isAuthRoute &&
          !isSplash &&
          !isOnboarding) {
        return AppRoutes.subscriptionExpired;
      }

      // Authenticated user trying to access auth/onboarding/splash pages
      // If subscription is expired, allow them to stay on auth routes (logout/register)
      if (isAuthenticated && (isAuthRoute || isSplash || isOnboarding)) {
        if (!isSubscriptionExpired) {
          return isSuperAdmin
              ? AppRoutes.superAdminDashboard
              : AppRoutes.dashboard;
        }
        return null;
      }

      // Not onboarded yet
      if (!hasSeenOnboarding && !isSplash && !isOnboarding && !isAuthRoute) {
        return AppRoutes.onboarding;
      }

      // Unauthenticated user trying to access protected pages
      if (!isAuthenticated && !isAuthRoute && !isSplash && !isOnboarding) {
        return AppRoutes.companyLogin;
      }

      // Role-based access control
      final isSuperAdminRoute = state.matchedLocation.startsWith(
        '/super-admin',
      );
      if (isAuthenticated && isSuperAdmin && !isSuperAdminRoute) {
        return AppRoutes.superAdminDashboard;
      }
      if (isAuthenticated && !isSuperAdmin && isSuperAdminRoute) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.chooseRole,
        builder: (context, state) => const CompanyLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.companyLogin,
        builder: (context, state) => const CompanyLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.companyRegister,
        builder: (context, state) => const CompanyRegistrationScreen(),
      ),
      GoRoute(
        path: AppRoutes.superAdminLogin,
        builder: (context, state) => const CompanyLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscriptionExpired,
        builder: (context, state) => const SubscriptionExpiredScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscriptionManagement,
        builder: (context, state) => const SubscriptionManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.detailedDashboard,
        builder: (context, state) => const DashboardScreen(detailed: true),
      ),
      GoRoute(
        path: AppRoutes.simpleFlow,
        builder: (context, state) => SimpleInventoryFlowScreen(
          initialMode: state.uri.queryParameters['mode'],
        ),
      ),
      GoRoute(
        path: AppRoutes.superAdminDashboard,
        builder: (context, state) => const SuperAdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.companies,
        builder: (context, state) => const CompaniesListScreen(),
      ),
      GoRoute(
        path: AppRoutes.addCompany,
        builder: (context, state) => const AddEditCompanyScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.editCompany}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddEditCompanyScreen(companyId: id);
        },
      ),
      GoRoute(
        path: '${AppRoutes.companyDetail}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CompanyDetailScreen(companyId: id);
        },
      ),
      GoRoute(
        path: '${AppRoutes.assignPlan}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AssignPlanScreen(companyId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.plans,
        builder: (context, state) => const PlansListScreen(),
      ),
      GoRoute(
        path: AppRoutes.addPlan,
        builder: (context, state) => const AddEditPlanScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.editPlan}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddEditPlanScreen(planId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.categories,
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.categoryDetail}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CategoryDetailScreen(categoryId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.addCategory,
        builder: (context, state) => const AddEditCategoryScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.editCategory}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddEditCategoryScreen(categoryId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.products,
        builder: (context, state) => const ProductsScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.productDetail}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.addProduct,
        builder: (context, state) => const AddEditProductScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.editProduct}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddEditProductScreen(productId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.vendors,
        builder: (context, state) => const VendorsScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.vendorDetail}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return VendorDetailScreen(vendorId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.addVendor,
        builder: (context, state) => const AddEditVendorScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.editVendor}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddEditVendorScreen(vendorId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.customers,
        builder: (context, state) => const CustomersScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.customerDetail}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomerDetailScreen(customerId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.addCustomer,
        builder: (context, state) => const AddEditCustomerScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.editCustomer}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddEditCustomerScreen(customerId: id);
        },
      ),
      GoRoute(
        path: '${AppRoutes.receivePayment}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ReceivePaymentScreen(
            customerId: id,
            sourceSaleId: state.uri.queryParameters['saleId'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.inventory,
        builder: (context, state) => const InventoryScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.inventoryDetail}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return InventoryDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: '${AppRoutes.stockAdjustment}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return StockAdjustmentScreen(productId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.stockAdjustment,
        builder: (context, state) => const StockAdjustmentScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.batchDetail}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BatchDetailScreen(batchId: id);
        },
      ),
      GoRoute(
        path: '${AppRoutes.productBatches}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductBatchesScreen(productId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.sales,
        builder: (context, state) =>
            const SimpleInventoryFlowScreen(initialMode: 'sell'),
      ),
      GoRoute(
        path: AppRoutes.salesHistory,
        builder: (context, state) => const SalesHistoryScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.saleDetail}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SaleDetailScreen(saleId: id);
        },
      ),
      GoRoute(
        path: '${AppRoutes.billInvoice}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BillInvoiceScreen(saleId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.saleReturnsHistory,
        builder: (context, state) => const SaleReturnsHistoryScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.saleReturn}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CreateSaleReturnScreen(saleId: id);
        },
      ),
      GoRoute(
        path: '${AppRoutes.saleReturnDetail}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return SaleReturnDetailScreen(returnId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.purchases,
        builder: (context, state) => const PurchaseListScreen(),
      ),
      GoRoute(
        path: AppRoutes.addPurchase,
        builder: (context, state) => const SimpleInventoryFlowScreen(initialMode: 'purchase'),
      ),
      GoRoute(
        path: '${AppRoutes.purchaseDetail}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PurchaseDetailScreen(purchaseId: id);
        },
      ),
      GoRoute(
        path: '${AppRoutes.editPurchase}/:id',
        builder: (context, state) => const SimpleInventoryFlowScreen(initialMode: 'purchase'),
      ),
      GoRoute(
        path: '${AppRoutes.duplicatePurchase}/:id',
        builder: (context, state) => const SimpleInventoryFlowScreen(initialMode: 'purchase'),
      ),
      GoRoute(
        path: '${AppRoutes.purchaseReturn}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PurchaseReturnScreen(purchaseId: id);
        },
      ),
    ],
  );
});
