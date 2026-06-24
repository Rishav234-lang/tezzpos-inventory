import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/vendors/presentation/screens/vendor_list_screen.dart';
import '../../features/vendors/presentation/screens/vendor_form_screen.dart';
import '../../features/products/presentation/screens/product_list_screen.dart';
import '../../features/products/presentation/screens/product_form_screen.dart';
import '../../features/purchases/presentation/screens/purchase_list_screen.dart';
import '../../features/purchases/presentation/screens/purchase_form_screen.dart';
import '../../features/customers/presentation/screens/customer_list_screen.dart';
import '../../features/customers/presentation/screens/customer_form_screen.dart';
import '../../features/sales/presentation/screens/sale_list_screen.dart';
import '../../features/sales/presentation/screens/sale_form_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/payments/presentation/screens/payment_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/shell/presentation/screens/app_shell.dart';
import '../providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/vendors',
            builder: (context, state) => const VendorListScreen(),
          ),
          GoRoute(
            path: '/vendors/add',
            builder: (context, state) => const VendorFormScreen(),
          ),
          GoRoute(
            path: '/vendors/:id/edit',
            builder: (context, state) => VendorFormScreen(vendorId: state.pathParameters['id']),
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductListScreen(),
          ),
          GoRoute(
            path: '/products/add',
            builder: (context, state) => const ProductFormScreen(),
          ),
          GoRoute(
            path: '/products/:id/edit',
            builder: (context, state) => ProductFormScreen(productId: state.pathParameters['id']),
          ),
          GoRoute(
            path: '/purchases',
            builder: (context, state) => const PurchaseListScreen(),
          ),
          GoRoute(
            path: '/purchases/add',
            builder: (context, state) => const PurchaseFormScreen(),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomerListScreen(),
          ),
          GoRoute(
            path: '/customers/add',
            builder: (context, state) => const CustomerFormScreen(),
          ),
          GoRoute(
            path: '/customers/:id/edit',
            builder: (context, state) => CustomerFormScreen(customerId: state.pathParameters['id']),
          ),
          GoRoute(
            path: '/sales',
            builder: (context, state) => const SaleListScreen(),
          ),
          GoRoute(
            path: '/sales/add',
            builder: (context, state) => const SaleFormScreen(),
          ),
          GoRoute(
            path: '/inventory',
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/payments',
            builder: (context, state) => const PaymentScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
