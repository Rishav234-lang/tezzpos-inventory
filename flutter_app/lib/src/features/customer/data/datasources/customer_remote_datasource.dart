import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failures.dart';
import '../models/customer_model.dart';

abstract class CustomerRemoteDataSource {
  Future<List<CustomerModel>> getCustomers({
    String? search,
    int page,
    int limit,
  });
  Future<CustomerModel> getCustomerById(String id);
  Future<CustomerModel> createCustomer(Map<String, dynamic> data);
  Future<CustomerModel> updateCustomer(String id, Map<String, dynamic> data);
  Future<void> deleteCustomer(String id);
  Future<Map<String, dynamic>> getCustomerLedger(String id);
  Future<Map<String, dynamic>> getCustomerSales(String id, {int page, int limit});
  Future<void> receivePayment(Map<String, dynamic> data);
}

class CustomerRemoteDataSourceImpl implements CustomerRemoteDataSource {
  final Dio _dio;

  CustomerRemoteDataSourceImpl(this._dio);

  @override
  Future<List<CustomerModel>> getCustomers({
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
        ApiConstants.customers,
        queryParameters: query,
      );
      final data = response.data as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>;
      return list.map((e) => CustomerModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<CustomerModel> getCustomerById(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.customers}/$id');
      return CustomerModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<CustomerModel> createCustomer(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.customers, data: data);
      return CustomerModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<CustomerModel> updateCustomer(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('${ApiConstants.customers}/$id', data: data);
      return CustomerModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deleteCustomer(String id) async {
    try {
      await _dio.delete('${ApiConstants.customers}/$id');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getCustomerLedger(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.customers}/$id/ledger');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getCustomerSales(String id, {int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.customers}/$id/sales',
        queryParameters: {'page': page, 'limit': limit},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> receivePayment(Map<String, dynamic> data) async {
    try {
      await _dio.post(ApiConstants.customerPayments, data: data);
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
