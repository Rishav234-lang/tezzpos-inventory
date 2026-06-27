import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failures.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts({
    String? search,
    String? categoryId,
    String? status,
    String? stockFilter,
    int page,
    int limit,
  });
  Future<ProductModel> getProductById(String id);
  Future<ProductModel> createProduct(Map<String, dynamic> data);
  Future<ProductModel> updateProduct(String id, Map<String, dynamic> data);
  Future<void> deleteProduct(String id);
  Future<String> uploadProductImage(File imageFile);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final Dio _dio;

  ProductRemoteDataSourceImpl(this._dio);

  @override
  Future<List<ProductModel>> getProducts({
    String? search,
    String? categoryId,
    String? status,
    String? stockFilter,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search != null && search.isNotEmpty) query['search'] = search;
      if (categoryId != null) query['categoryId'] = categoryId;
      if (status != null) query['status'] = status;
      if (stockFilter != null) query['stockFilter'] = stockFilter;

      final response = await _dio.get(
        ApiConstants.products,
        queryParameters: query,
      );
      final data = response.data as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>;
      return list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.products}/$id');
      return ProductModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<ProductModel> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.products, data: data);
      return ProductModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<ProductModel> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('${ApiConstants.products}/$id', data: data);
      return ProductModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      await _dio.delete('${ApiConstants.products}/$id');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<String> uploadProductImage(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last.split('\\').last,
        ),
      });
      final response = await _dio.post(
        ApiConstants.productImageUpload,
        data: formData,
      );
      return (response.data['path'] as String);
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
