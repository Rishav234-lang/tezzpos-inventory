import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/dashboard_stats.dart';

abstract class DashboardRepository {
  Future<Either<Failure, DashboardStats>> getDashboardStats({
    String? startDate,
    String? endDate,
  });
  Future<Either<Failure, List<RecentTransaction>>> getRecentSales({
    String? startDate,
    String? endDate,
  });
  Future<Either<Failure, List<RecentTransaction>>> getRecentPurchases({
    String? startDate,
    String? endDate,
  });
  Future<Either<Failure, List<TopSellingProduct>>> getTopSellingProducts({
    String? startDate,
    String? endDate,
  });
  Future<Either<Failure, List<ChartDataPoint>>> getDailySalesChart();
  Future<Either<Failure, List<ChartDataPoint>>> getDailyPurchasesChart();
}
