import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/providers.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>((ref) {
  return DashboardRemoteDataSourceImpl(ref.watch(dioProvider).dio);
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dashboardRemoteDataSourceProvider));
});

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  final result = await repository.getDashboardStats();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (stats) => stats,
  );
});

final recentSalesProvider = FutureProvider<List<RecentTransaction>>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  final result = await repository.getRecentSales();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (transactions) => transactions,
  );
});

final recentPurchasesProvider = FutureProvider<List<RecentTransaction>>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  final result = await repository.getRecentPurchases();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (transactions) => transactions,
  );
});

final topSellingProductsProvider = FutureProvider<List<TopSellingProduct>>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  final result = await repository.getTopSellingProducts();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (products) => products,
  );
});

final dailySalesChartProvider = FutureProvider<List<ChartDataPoint>>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  final result = await repository.getDailySalesChart();
  return result.fold(
    (failure) => [],
    (data) => data,
  );
});
