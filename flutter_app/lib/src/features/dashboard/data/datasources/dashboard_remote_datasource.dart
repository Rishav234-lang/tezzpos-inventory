import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failures.dart';
import '../models/dashboard_stats_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardStatsModel> getDashboardStats();
  Future<List<RecentTransactionModel>> getRecentSales();
  Future<List<RecentTransactionModel>> getRecentPurchases();
  Future<List<TopSellingProductModel>> getTopSellingProducts();
  Future<List<ChartDataPointModel>> getDailySalesChart();
  Future<List<ChartDataPointModel>> getDailyPurchasesChart();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final Dio _dio;

  DashboardRemoteDataSourceImpl(this._dio);

  @override
  Future<DashboardStatsModel> getDashboardStats() async {
    try {
      final response = await _dio.get(ApiConstants.dashboard);
      return DashboardStatsModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<RecentTransactionModel>> getRecentSales() async {
    try {
      final response = await _dio.get(ApiConstants.recentSales);
      final List data = response.data is List ? response.data : [];
      return data.map((e) => RecentTransactionModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<RecentTransactionModel>> getRecentPurchases() async {
    try {
      final response = await _dio.get(ApiConstants.recentPurchases);
      final List data = response.data is List ? response.data : [];
      return data.map((e) => RecentTransactionModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<TopSellingProductModel>> getTopSellingProducts() async {
    try {
      final response = await _dio.get('${ApiConstants.dashboard}/charts/top-products');
      final List data = response.data is List ? response.data : [];
      return data.map((e) => TopSellingProductModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<ChartDataPointModel>> getDailySalesChart() async {
    try {
      final response = await _dio.get('${ApiConstants.dashboard}/charts/daily-sales');
      final List data = response.data is List ? response.data : [];
      return data.map((e) => ChartDataPointModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<ChartDataPointModel>> getDailyPurchasesChart() async {
    try {
      final response = await _dio.get('${ApiConstants.dashboard}/charts/daily-purchases');
      final List data = response.data is List ? response.data : [];
      return data.map((e) => ChartDataPointModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Failure _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }
    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      final message = data is Map ? data['error']?.toString() : 'Server error';
      if (statusCode == 401) {
        return UnauthorizedFailure(message: message ?? 'Unauthorized');
      }
      return ServerFailure(
        message: message ?? 'Server error occurred',
        statusCode: statusCode,
      );
    }
    return UnknownFailure(message: e.message ?? 'Unknown error');
  }
}
