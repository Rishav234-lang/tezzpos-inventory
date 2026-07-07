import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/providers.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>((
  ref,
) {
  return DashboardRemoteDataSourceImpl(ref.watch(dioProvider).dio);
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dashboardRemoteDataSourceProvider));
});

class DashboardDateFilter {
  final DateTime? startDate;
  final DateTime? endDate;

  const DashboardDateFilter({this.startDate, this.endDate});

  String? get startDateIso => startDate?.toIso8601String();
  String? get endDateIso => endDate?.toIso8601String();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardDateFilter &&
          other.startDate == startDate &&
          other.endDate == endDate;

  @override
  int get hashCode => Object.hash(startDate, endDate);
}

final dashboardStatsProvider =
    FutureProvider.family<DashboardStats, DashboardDateFilter>((
      ref,
      filter,
    ) async {
      final repository = ref.watch(dashboardRepositoryProvider);
      final result = await repository.getDashboardStats(
        startDate: filter.startDateIso,
        endDate: filter.endDateIso,
      );
      return result.fold(
        (failure) => throw Exception(failure.message),
        (stats) => stats,
      );
    });

final recentSalesProvider =
    FutureProvider.family<List<RecentTransaction>, DashboardDateFilter>((
      ref,
      filter,
    ) async {
      final repository = ref.watch(dashboardRepositoryProvider);
      final result = await repository.getRecentSales(
        startDate: filter.startDateIso,
        endDate: filter.endDateIso,
      );
      return result.fold(
        (failure) => throw Exception(failure.message),
        (transactions) => transactions,
      );
    });

final recentPurchasesProvider =
    FutureProvider.family<List<RecentTransaction>, DashboardDateFilter>((
      ref,
      filter,
    ) async {
      final repository = ref.watch(dashboardRepositoryProvider);
      final result = await repository.getRecentPurchases(
        startDate: filter.startDateIso,
        endDate: filter.endDateIso,
      );
      return result.fold(
        (failure) => throw Exception(failure.message),
        (transactions) => transactions,
      );
    });

final topSellingProductsProvider =
    FutureProvider.family<List<TopSellingProduct>, DashboardDateFilter>((
      ref,
      filter,
    ) async {
      final repository = ref.watch(dashboardRepositoryProvider);
      final result = await repository.getTopSellingProducts(
        startDate: filter.startDateIso,
        endDate: filter.endDateIso,
      );
      return result.fold(
        (failure) => throw Exception(failure.message),
        (products) => products,
      );
    });

final dailySalesChartProvider = FutureProvider<List<ChartDataPoint>>((
  ref,
) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  final result = await repository.getDailySalesChart();
  return result.fold((failure) => [], (data) => data);
});
