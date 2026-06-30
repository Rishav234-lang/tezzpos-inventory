import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failures.dart';
import '../models/sale_model.dart';
import '../models/sale_return_model.dart';

abstract class SaleRemoteDataSource {
  Future<List<SaleModel>> getSales({
    String? customerId,
    String? status,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    int page,
    int limit,
  });
  Future<SaleModel> getSaleById(String id);
  Future<SaleModel> createSale(Map<String, dynamic> data);
  Future<SaleModel> updateSalePayment(String id, Map<String, dynamic> data);
  Future<List<SaleModel>> searchSalesByInvoice(String invoiceNumber);

  Future<List<SaleReturnModel>> getSaleReturns({int page, int limit});
  Future<SaleReturnModel> getSaleReturnById(String id);
  Future<SaleReturnModel> createSaleReturn(Map<String, dynamic> data);
}

class SaleRemoteDataSourceImpl implements SaleRemoteDataSource {
  final Dio _dio;

  SaleRemoteDataSourceImpl(this._dio);

  @override
  Future<List<SaleModel>> getSales({
    String? customerId,
    String? status,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (customerId != null && customerId.isNotEmpty) query['customerId'] = customerId;
      if (status != null && status.isNotEmpty) query['status'] = status;
      if (startDate != null) query['startDate'] = startDate.toIso8601String();
      if (endDate != null) query['endDate'] = endDate.toIso8601String();

      final response = await _dio.get(ApiConstants.sales, queryParameters: query);
      final data = response.data as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>;
      return list.map((e) => SaleModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<SaleModel> getSaleById(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.sales}/$id');
      return SaleModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<SaleModel> createSale(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.sales, data: data);
      return SaleModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<SaleModel> updateSalePayment(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('${ApiConstants.sales}/$id', data: data);
      return SaleModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<SaleModel>> searchSalesByInvoice(String invoiceNumber) async {
    try {
      final response = await _dio.get('${ApiConstants.sales}/search/$invoiceNumber');
      final list = response.data as List<dynamic>;
      return list.map((e) => SaleModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<SaleReturnModel>> getSaleReturns({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        ApiConstants.saleReturns,
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>;
      return list.map((e) => SaleReturnModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<SaleReturnModel> getSaleReturnById(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.saleReturns}/$id');
      return SaleReturnModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<SaleReturnModel> createSaleReturn(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.saleReturns, data: data);
      return SaleReturnModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Failure _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;
    final message = responseData is Map<String, dynamic>
        ? (responseData['error'] ?? responseData['message'] ?? e.message ?? 'Something went wrong')
        : (e.message ?? 'Something went wrong');
    switch (statusCode) {
      case 400:
        return ValidationFailure(message: message);
      case 401:
        return UnauthorizedFailure(message: message);
      case 404:
        return NotFoundFailure(message: message);
      case 409:
        return ConflictFailure(message: message);
      default:
        return ServerFailure(message: message);
    }
  }
}
