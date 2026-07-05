import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failures.dart';
import '../models/company_model.dart';
import '../models/plan_model.dart';
import '../models/super_admin_dashboard_stats_model.dart';

abstract class SuperAdminRemoteDataSource {
  Future<SuperAdminDashboardStatsModel> getDashboardStats();

  Future<List<CompanyModel>> getCompanies({String? status, String? search, int page, int limit});
  Future<CompanyModel> getCompanyById(String id);
  Future<CompanyModel> createCompany(Map<String, dynamic> data);
  Future<CompanyModel> updateCompany(String id, Map<String, dynamic> data);
  Future<void> approveCompany(String id);
  Future<void> suspendCompany(String id);
  Future<void> activateCompany(String id);
  Future<void> expireCompanyNow(String id);
  Future<void> resetOwnerPassword(String id, String newPassword);
  Future<void> assignPlan(String companyId, Map<String, dynamic> data);

  Future<List<PlanModel>> getPlans();
  Future<PlanModel> createPlan(Map<String, dynamic> data);
  Future<PlanModel> updatePlan(String id, Map<String, dynamic> data);
}

class SuperAdminRemoteDataSourceImpl implements SuperAdminRemoteDataSource {
  final Dio _dio;

  SuperAdminRemoteDataSourceImpl(this._dio);

  @override
  Future<SuperAdminDashboardStatsModel> getDashboardStats() async {
    try {
      final response = await _dio.get(ApiConstants.superAdminDashboard);
      if (response.statusCode == 200) {
        return SuperAdminDashboardStatsModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw const ServerFailure(message: 'Failed to load dashboard stats');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<CompanyModel>> getCompanies({String? status, String? search, int page = 1, int limit = 20}) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status != null) queryParameters['status'] = status;
      if (search != null && search.isNotEmpty) queryParameters['search'] = search;
      final response = await _dio.get(
        ApiConstants.companies,
        queryParameters: queryParameters,
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['data'] as List<dynamic>? ?? [];
        return items.map((e) => CompanyModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw const ServerFailure(message: 'Failed to load companies');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<CompanyModel> getCompanyById(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.companies}/$id');
      if (response.statusCode == 200) {
        return CompanyModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw const ServerFailure(message: 'Failed to load company');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<CompanyModel> createCompany(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.companies, data: data);
      if (response.statusCode == 201) {
        return CompanyModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw const ServerFailure(message: 'Failed to create company');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<CompanyModel> updateCompany(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('${ApiConstants.companies}/$id', data: data);
      if (response.statusCode == 200) {
        return CompanyModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw const ServerFailure(message: 'Failed to update company');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> approveCompany(String id) async {
    try {
      final response = await _dio.put('${ApiConstants.companies}/$id/approve');
      if (response.statusCode != 200) {
        throw const ServerFailure(message: 'Failed to approve company');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> suspendCompany(String id) async {
    try {
      final response = await _dio.put('${ApiConstants.companies}/$id/suspend');
      if (response.statusCode != 200) {
        throw const ServerFailure(message: 'Failed to suspend company');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> activateCompany(String id) async {
    try {
      final response = await _dio.put('${ApiConstants.companies}/$id/activate');
      if (response.statusCode != 200) {
        throw const ServerFailure(message: 'Failed to activate company');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> expireCompanyNow(String id) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.companies}/$id/expire-now',
        data: {},
      );
      if (response.statusCode != 200) {
        throw const ServerFailure(message: 'Failed to expire subscription');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> resetOwnerPassword(String id, String newPassword) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.companies}/$id/reset-password',
        data: {'newPassword': newPassword},
      );
      if (response.statusCode != 200) {
        throw const ServerFailure(message: 'Failed to reset password');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> assignPlan(String companyId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('${ApiConstants.companies}/$companyId/plan', data: data);
      if (response.statusCode != 200) {
        throw const ServerFailure(message: 'Failed to assign plan');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<PlanModel>> getPlans() async {
    try {
      final response = await _dio.get(ApiConstants.plans);
      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        return data.map((e) => PlanModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw const ServerFailure(message: 'Failed to load plans');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<PlanModel> createPlan(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.plans, data: data);
      if (response.statusCode == 201) {
        return PlanModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw const ServerFailure(message: 'Failed to create plan');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<PlanModel> updatePlan(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('${ApiConstants.plans}/$id', data: data);
      if (response.statusCode == 200) {
        return PlanModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw const ServerFailure(message: 'Failed to update plan');
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
      if (statusCode == 401) return UnauthorizedFailure(message: message ?? 'Unauthorized');
      if (statusCode == 403) return UnauthorizedFailure(message: message ?? 'Access denied');
      return ServerFailure(message: message ?? 'Server error', statusCode: statusCode);
    }
    return UnknownFailure(message: e.message ?? 'Unknown error');
  }
}
