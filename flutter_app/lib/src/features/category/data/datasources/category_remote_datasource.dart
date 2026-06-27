import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failures.dart';
import '../models/category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getCategories({String? search, String? status});
  Future<CategoryModel> getCategoryById(String id);
  Future<CategoryModel> createCategory(Map<String, dynamic> data);
  Future<CategoryModel> updateCategory(String id, Map<String, dynamic> data);
  Future<void> deleteCategory(String id);
  Future<String> uploadCategoryImage(File imageFile);
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final Dio _dio;

  CategoryRemoteDataSourceImpl(this._dio);

  @override
  Future<List<CategoryModel>> getCategories({String? search, String? status}) async {
    try {
      final query = <String, dynamic>{};
      if (search != null && search.isNotEmpty) query['search'] = search;
      if (status != null) query['status'] = status;

      final response = await _dio.get(
        ApiConstants.categories,
        queryParameters: query.isNotEmpty ? query : null,
      );
      final list = response.data as List<dynamic>;
      return list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<CategoryModel> getCategoryById(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.categories}/$id');
      return CategoryModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<CategoryModel> createCategory(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.categories, data: data);
      return CategoryModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<CategoryModel> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('${ApiConstants.categories}/$id', data: data);
      return CategoryModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await _dio.delete('${ApiConstants.categories}/$id');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<String> uploadCategoryImage(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last.split('\\').last,
        ),
      });
      final response = await _dio.post(
        ApiConstants.categoryImageUpload,
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
