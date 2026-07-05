import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/super_admin_dashboard_stats.dart';
import '../../domain/repositories/super_admin_repository.dart';
import '../datasources/super_admin_remote_datasource.dart';

class SuperAdminRepositoryImpl implements SuperAdminRepository {
  final SuperAdminRemoteDataSource remoteDataSource;

  SuperAdminRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, SuperAdminDashboardStats>> getDashboardStats() async {
    try {
      final stats = await remoteDataSource.getDashboardStats();
      return Right(stats.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Company>>> getCompanies({String? status, String? search, int page = 1, int limit = 20}) async {
    try {
      final companies = await remoteDataSource.getCompanies(status: status, search: search, page: page, limit: limit);
      return Right(companies.map((c) => c.toEntity()).toList());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Company>> getCompanyById(String id) async {
    try {
      final company = await remoteDataSource.getCompanyById(id);
      return Right(company.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Company>> createCompany({
    required String name,
    required String email,
    required String phone,
    String? address,
    String? gstNumber,
    required String ownerName,
    required String ownerEmail,
    required String ownerPassword,
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
        'email': email,
        'phone': phone,
        'ownerName': ownerName,
        'ownerEmail': ownerEmail,
        'ownerPassword': ownerPassword,
      };
      if (address != null) data['address'] = address;
      if (gstNumber != null) data['gstNumber'] = gstNumber;
      final company = await remoteDataSource.createCompany(data);
      return Right(company.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Company>> updateCompany(String id, Map<String, dynamic> data) async {
    try {
      final company = await remoteDataSource.updateCompany(id, data);
      return Right(company.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> approveCompany(String id) async {
    try {
      await remoteDataSource.approveCompany(id);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> suspendCompany(String id) async {
    try {
      await remoteDataSource.suspendCompany(id);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> activateCompany(String id) async {
    try {
      await remoteDataSource.activateCompany(id);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> expireCompanyNow(String id) async {
    try {
      await remoteDataSource.expireCompanyNow(id);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetOwnerPassword(String id, String newPassword) async {
    try {
      await remoteDataSource.resetOwnerPassword(id, newPassword);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> assignPlan(String companyId, {
    required String planId,
    required String billingCycle,
    DateTime? startDate,
    required DateTime endDate,
    double? customPrice,
  }) async {
    try {
      final data = <String, dynamic>{
        'planId': planId,
        'billingCycle': billingCycle,
        'startDate': (startDate ?? DateTime.now()).toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };
      if (customPrice != null) data['customPrice'] = customPrice;
      await remoteDataSource.assignPlan(companyId, data);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Plan>>> getPlans() async {
    try {
      final plans = await remoteDataSource.getPlans();
      return Right(plans.map((p) => p.toEntity()).toList());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Plan>> createPlan({
    required String name,
    required double monthlyPrice,
    required double yearlyPrice,
    String? description,
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
        'monthlyPrice': monthlyPrice,
        'yearlyPrice': yearlyPrice,
      };
      if (description != null) data['description'] = description;
      final plan = await remoteDataSource.createPlan(data);
      return Right(plan.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Plan>> updatePlan(String id, Map<String, dynamic> data) async {
    try {
      final plan = await remoteDataSource.updatePlan(id, data);
      return Right(plan.toEntity());
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}

