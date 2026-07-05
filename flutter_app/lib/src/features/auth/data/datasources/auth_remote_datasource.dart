import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failures.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> loginCompanyOwner({
    required String email,
    required String password,
  });

  Future<UserModel> loginSuperAdmin({
    required String email,
    required String password,
  });

  Future<UserModel> registerCompany({
    required String companyName,
    required String companyEmail,
    String? companyPhone,
    String? companyAddress,
    String? companyGstNumber,
    required String ownerName,
    required String ownerEmail,
    required String ownerPassword,
    String? planId,
    String? billingCycle,
  });

  Future<UserModel> getCurrentUser();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<UserModel> loginCompanyOwner({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.ownerLogin,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return UserModel.fromJson(response.data);
      }
      throw const ServerFailure(message: 'Login failed');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<UserModel> loginSuperAdmin({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.superAdminLogin,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return UserModel.fromJson(response.data);
      }
      throw const ServerFailure(message: 'Login failed');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<UserModel> registerCompany({
    required String companyName,
    required String companyEmail,
    String? companyPhone,
    String? companyAddress,
    String? companyGstNumber,
    required String ownerName,
    required String ownerEmail,
    required String ownerPassword,
    String? planId,
    String? billingCycle,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.companyRegister,
        data: {
          'companyName': companyName,
          'companyEmail': companyEmail,
          'companyPhone': companyPhone,
          'companyAddress': companyAddress,
          'companyGstNumber': companyGstNumber,
          'ownerName': ownerName,
          'ownerEmail': ownerEmail,
          'ownerPassword': ownerPassword,
          'planId': planId,
          'billingCycle': billingCycle,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return UserModel.fromJson(response.data);
      }
      throw const ServerFailure(message: 'Registration failed');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiConstants.me);
      if (response.statusCode == 200) {
        return UserModel.fromJson({'user': response.data});
      }
      throw const ServerFailure(message: 'Failed to get user');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.put(
        ApiConstants.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      if (response.statusCode != 200) {
        throw const ServerFailure(message: 'Failed to change password');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Failure _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }

    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      final message = data is Map ? data['error']?.toString() : 'Server error';

      if (statusCode == 401) {
        return UnauthorizedFailure(message: message ?? 'Invalid credentials');
      }
      if (statusCode == 403) {
        return UnauthorizedFailure(
          message: message ?? 'Access denied. Subscription may be expired.',
        );
      }
      return ServerFailure(
        message: message ?? 'Server error occurred',
        statusCode: statusCode,
      );
    }

    return UnknownFailure(message: e.message ?? 'Unknown error');
  }
}
