import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failures.dart';
import '../models/purchase_model.dart';

abstract class PurchaseRemoteDataSource {
  Future<Map<String, dynamic>> getPurchases({
    int page,
    int limit,
    String? vendorId,
    String? status,
    String? startDate,
    String? endDate,
    String? sortOrder,
  });
  Future<PurchaseModel> getPurchaseById(String id);
  Future<PurchaseModel> createPurchase(Map<String, dynamic> data);
  Future<PurchaseModel> updatePurchase(String id, Map<String, dynamic> data);
  Future<void> deletePurchase(String id);
  Future<void> recordVendorPayment(Map<String, dynamic> data);
}

class PurchaseRemoteDataSourceImpl implements PurchaseRemoteDataSource {
  final Dio _dio;

  PurchaseRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> getPurchases({
    int page = 1,
    int limit = 20,
    String? vendorId,
    String? status,
    String? startDate,
    String? endDate,
    String? sortOrder,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (vendorId != null && vendorId.isNotEmpty) query['vendorId'] = vendorId;
      if (status != null && status.isNotEmpty) query['status'] = status;
      if (startDate != null && startDate.isNotEmpty) query['startDate'] = startDate;
      if (endDate != null && endDate.isNotEmpty) query['endDate'] = endDate;
      if (sortOrder != null && sortOrder.isNotEmpty) query['sortOrder'] = sortOrder;

      final response = await _dio.get(
        ApiConstants.purchases,
        queryParameters: query,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<PurchaseModel> getPurchaseById(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.purchases}/$id');
      return PurchaseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<PurchaseModel> createPurchase(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.purchases, data: data);
      return PurchaseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<PurchaseModel> updatePurchase(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('${ApiConstants.purchases}/$id', data: data);
      return PurchaseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deletePurchase(String id) async {
    try {
      await _dio.delete('${ApiConstants.purchases}/$id');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> recordVendorPayment(Map<String, dynamic> data) async {
    try {
      await _dio.post(ApiConstants.vendorPayments, data: data);
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
