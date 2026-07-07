import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failures.dart';
import '../models/dashboard_stats_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardStatsModel> getDashboardStats({
    String? startDate,
    String? endDate,
  });
  Future<List<RecentTransactionModel>> getRecentSales({
    String? startDate,
    String? endDate,
  });
  Future<List<RecentTransactionModel>> getRecentPurchases({
    String? startDate,
    String? endDate,
  });
  Future<List<TopSellingProductModel>> getTopSellingProducts({
    String? startDate,
    String? endDate,
  });
  Future<List<ChartDataPointModel>> getDailySalesChart();
  Future<List<ChartDataPointModel>> getDailyPurchasesChart();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final Dio _dio;

  DashboardRemoteDataSourceImpl(this._dio);

  @override
  Future<DashboardStatsModel> getDashboardStats({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (startDate != null) query['startDate'] = startDate;
      if (endDate != null) query['endDate'] = endDate;
      final response = await _dio.get(
        ApiConstants.dashboard,
        queryParameters: query,
      );
      return DashboardStatsModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<RecentTransactionModel>> getRecentSales({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (startDate != null) query['startDate'] = startDate;
      if (endDate != null) query['endDate'] = endDate;
      final response = await _dio.get(
        ApiConstants.recentSales,
        queryParameters: query,
      );
      final List data = response.data is List ? response.data : [];
      return data.map((e) => RecentTransactionModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<RecentTransactionModel>> getRecentPurchases({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (startDate != null) query['startDate'] = startDate;
      if (endDate != null) query['endDate'] = endDate;
      final response = await _dio.get(
        ApiConstants.recentPurchases,
        queryParameters: query,
      );
      final List data = response.data is List ? response.data : [];
      return data.map((e) => RecentTransactionModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<TopSellingProductModel>> getTopSellingProducts({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (startDate != null) query['startDate'] = startDate;
      if (endDate != null) query['endDate'] = endDate;
      final response = await _dio.get(
        '${ApiConstants.dashboard}/charts/top-products',
        queryParameters: query,
      );
      final List data = response.data is List ? response.data : [];
      return data.map((e) => TopSellingProductModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<ChartDataPointModel>> getDailySalesChart() async {
    try {
      final response = await _dio.get(
        '${ApiConstants.dashboard}/charts/daily-sales',
      );
      final List data = response.data is List ? response.data : [];
      return data.map((e) => ChartDataPointModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<ChartDataPointModel>> getDailyPurchasesChart() async {
    try {
      final response = await _dio.get(
        '${ApiConstants.dashboard}/charts/daily-purchases',
      );
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
