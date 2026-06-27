import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failures.dart';
import '../models/vendor_model.dart';

abstract class VendorRemoteDataSource {
  Future<List<VendorModel>> getVendors({
    String? search,
    int page,
    int limit,
  });
  Future<VendorModel> getVendorById(String id);
  Future<VendorModel> createVendor(Map<String, dynamic> data);
  Future<VendorModel> updateVendor(String id, Map<String, dynamic> data);
  Future<void> deleteVendor(String id);
  Future<Map<String, dynamic>> getVendorLedger(String id);
}

class VendorRemoteDataSourceImpl implements VendorRemoteDataSource {
  final Dio _dio;

  VendorRemoteDataSourceImpl(this._dio);

  @override
  Future<List<VendorModel>> getVendors({
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search != null && search.isNotEmpty) query['search'] = search;

      final response = await _dio.get(
        ApiConstants.vendors,
        queryParameters: query,
      );
      final data = response.data as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>;
      return list.map((e) => VendorModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<VendorModel> getVendorById(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.vendors}/$id');
      return VendorModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<VendorModel> createVendor(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.vendors, data: data);
      return VendorModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<VendorModel> updateVendor(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('${ApiConstants.vendors}/$id', data: data);
      return VendorModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deleteVendor(String id) async {
    try {
      await _dio.delete('${ApiConstants.vendors}/$id');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getVendorLedger(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.vendors}/$id/ledger');
      return response.data as Map<String, dynamic>;
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
