import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/providers.dart';
import '../../data/datasources/super_admin_remote_datasource.dart';
import '../../data/repositories/super_admin_repository_impl.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/super_admin_dashboard_stats.dart';
import '../../domain/repositories/super_admin_repository.dart';

// Data sources
final superAdminRemoteDataSourceProvider = Provider<SuperAdminRemoteDataSource>((ref) {
  return SuperAdminRemoteDataSourceImpl(ref.watch(dioProvider).dio);
});

final superAdminRepositoryProvider = Provider<SuperAdminRepository>((ref) {
  return SuperAdminRepositoryImpl(remoteDataSource: ref.watch(superAdminRemoteDataSourceProvider));
});

// Dashboard
final superAdminDashboardStatsProvider = FutureProvider.autoDispose<SuperAdminDashboardStats>((ref) async {
  final repository = ref.watch(superAdminRepositoryProvider);
  final result = await repository.getDashboardStats();
  return result.fold(
    (failure) => throw failure,
    (stats) => stats,
  );
});

// Companies
class CompanyFilter {
  final String? status;
  final String? search;
  final int page;
  final int limit;

  const CompanyFilter({this.status, this.search, this.page = 1, this.limit = 20});

  CompanyFilter copyWith({String? status, String? search, int? page, int? limit}) {
    return CompanyFilter(
      status: status ?? this.status,
      search: search ?? this.search,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

final companiesProvider = FutureProvider.autoDispose.family<List<Company>, CompanyFilter>((ref, filter) async {
  final repository = ref.watch(superAdminRepositoryProvider);
  final result = await repository.getCompanies(
    status: filter.status,
    search: filter.search,
    page: filter.page,
    limit: filter.limit,
  );
  return result.fold(
    (failure) => throw failure,
    (companies) => companies,
  );
});

final companyDetailProvider = FutureProvider.autoDispose.family<Company, String>((ref, id) async {
  final repository = ref.watch(superAdminRepositoryProvider);
  final result = await repository.getCompanyById(id);
  return result.fold(
    (failure) => throw failure,
    (company) => company,
  );
});

// Plans
final plansProvider = FutureProvider.autoDispose<List<Plan>>((ref) async {
  final repository = ref.watch(superAdminRepositoryProvider);
  final result = await repository.getPlans();
  return result.fold(
    (failure) => throw failure,
    (plans) => plans,
  );
});

// Notifier for CRUD operations
class SuperAdminNotifier extends StateNotifier<AsyncValue<void>> {
  final SuperAdminRepository _repository;

  SuperAdminNotifier({required SuperAdminRepository repository})
      : _repository = repository,
        super(const AsyncValue.data(null));

  String? _lastError;
  String? get lastError => _lastError;

  Future<Company?> createCompany({
    required String name,
    required String email,
    required String phone,
    String? address,
    String? gstNumber,
    required String ownerName,
    required String ownerEmail,
    required String ownerPassword,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.createCompany(
      name: name,
      email: email,
      phone: phone,
      address: address,
      gstNumber: gstNumber,
      ownerName: ownerName,
      ownerEmail: ownerEmail,
      ownerPassword: ownerPassword,
    );
    return result.fold(
      (failure) {
        _lastError = failure.message;
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (company) {
        state = const AsyncValue.data(null);
        return company;
      },
    );
  }

  Future<Company?> updateCompany(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateCompany(id, data);
    return result.fold(
      (failure) {
        _lastError = failure.message;
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (company) {
        state = const AsyncValue.data(null);
        return company;
      },
    );
  }

  Future<bool> approveCompany(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.approveCompany(id);
    return result.fold(
      (failure) {
        _lastError = failure.message;
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }

  Future<bool> suspendCompany(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.suspendCompany(id);
    return result.fold(
      (failure) {
        _lastError = failure.message;
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }

  Future<bool> activateCompany(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.activateCompany(id);
    return result.fold(
      (failure) {
        _lastError = failure.message;
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }

  Future<bool> expireCompanyNow(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.expireCompanyNow(id);
    return result.fold(
      (failure) {
        _lastError = failure.message;
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }

  Future<bool> resetOwnerPassword(String id, String newPassword) async {
    state = const AsyncValue.loading();
    final result = await _repository.resetOwnerPassword(id, newPassword);
    return result.fold(
      (failure) {
        _lastError = failure.message;
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }

  Future<bool> assignPlan(String companyId, {
    required String planId,
    required String billingCycle,
    DateTime? startDate,
    required DateTime endDate,
    double? customPrice,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.assignPlan(
      companyId,
      planId: planId,
      billingCycle: billingCycle,
      startDate: startDate,
      endDate: endDate,
      customPrice: customPrice,
    );
    return result.fold(
      (failure) {
        _lastError = failure.message;
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }

  Future<Plan?> createPlan({
    required String name,
    required double monthlyPrice,
    required double yearlyPrice,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.createPlan(
      name: name,
      monthlyPrice: monthlyPrice,
      yearlyPrice: yearlyPrice,
      description: description,
    );
    return result.fold(
      (failure) {
        _lastError = failure.message;
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (plan) {
        state = const AsyncValue.data(null);
        return plan;
      },
    );
  }

  Future<Plan?> updatePlan(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final result = await _repository.updatePlan(id, data);
    return result.fold(
      (failure) {
        _lastError = failure.message;
        state = AsyncValue.error(failure.message, StackTrace.current);
        return null;
      },
      (plan) {
        state = const AsyncValue.data(null);
        return plan;
      },
    );
  }
}

final superAdminNotifierProvider = StateNotifierProvider<SuperAdminNotifier, AsyncValue<void>>((ref) {
  return SuperAdminNotifier(repository: ref.watch(superAdminRepositoryProvider));
});
