import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../features/auth/presentation/screens/choose_role_screen.dart';
import '../features/auth/presentation/screens/company_login_screen.dart';
import '../features/auth/presentation/screens/super_admin_login_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/category/presentation/screens/add_edit_category_screen.dart';
import '../features/category/presentation/screens/categories_screen.dart';
import '../features/category/presentation/screens/category_detail_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
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
      final isAuthRoute = state.matchedLocation == AppRoutes.chooseRole ||
          state.matchedLocation == AppRoutes.companyLogin ||
          state.matchedLocation == AppRoutes.superAdminLogin ||
          state.matchedLocation == AppRoutes.forgotPassword;

      final isAuthenticated = authState.valueOrNull?.isAuthenticated ?? false;

      // Read onboarding status directly from prefs to avoid stale provider state
      final prefs = ref.read(sharedPreferencesProvider);
      final hasSeenOnboarding = prefs.getBool('onboarding_complete') ?? false;

      // Still loading auth state - stay on splash
      if (authState.isLoading) return isSplash ? null : AppRoutes.splash;

      // Authenticated user trying to access auth/onboarding/splash pages
      if (isAuthenticated && (isAuthRoute || isSplash || isOnboarding)) {
        return AppRoutes.dashboard;
      }

      // Not onboarded yet
      if (!hasSeenOnboarding && !isSplash && !isOnboarding) {
        return AppRoutes.onboarding;
      }

      // Unauthenticated user trying to access protected pages
      if (!isAuthenticated && !isAuthRoute && !isSplash && !isOnboarding) {
        return AppRoutes.chooseRole;
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
        builder: (context, state) => const ChooseRoleScreen(),
      ),
      GoRoute(
        path: AppRoutes.companyLogin,
        builder: (context, state) => const CompanyLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.superAdminLogin,
        builder: (context, state) => const SuperAdminLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
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
    ],
  );
});
