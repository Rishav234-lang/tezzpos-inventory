import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/dashboard_stats.dart';

abstract class DashboardRepository {
  Future<Either<Failure, DashboardStats>> getDashboardStats();
  Future<Either<Failure, List<RecentTransaction>>> getRecentSales();
  Future<Either<Failure, List<RecentTransaction>>> getRecentPurchases();
  Future<Either<Failure, List<TopSellingProduct>>> getTopSellingProducts();
  Future<Either<Failure, List<ChartDataPoint>>> getDailySalesChart();
  Future<Either<Failure, List<ChartDataPoint>>> getDailyPurchasesChart();
}
