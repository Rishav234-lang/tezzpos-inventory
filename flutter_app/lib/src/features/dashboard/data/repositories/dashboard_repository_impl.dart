import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remoteDataSource;

  DashboardRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, DashboardStats>> getDashboardStats({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final result = await _remoteDataSource.getDashboardStats(
        startDate: startDate,
        endDate: endDate,
      );
      return Right(result);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RecentTransaction>>> getRecentSales({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final result = await _remoteDataSource.getRecentSales(
        startDate: startDate,
        endDate: endDate,
      );
      return Right(result);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RecentTransaction>>> getRecentPurchases({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final result = await _remoteDataSource.getRecentPurchases(
        startDate: startDate,
        endDate: endDate,
      );
      return Right(result);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TopSellingProduct>>> getTopSellingProducts({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final result = await _remoteDataSource.getTopSellingProducts(
        startDate: startDate,
        endDate: endDate,
      );
      return Right(result);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChartDataPoint>>> getDailySalesChart() async {
    try {
      final result = await _remoteDataSource.getDailySalesChart();
      return Right(result);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChartDataPoint>>> getDailyPurchasesChart() async {
    try {
      final result = await _remoteDataSource.getDailyPurchasesChart();
      return Right(result);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
