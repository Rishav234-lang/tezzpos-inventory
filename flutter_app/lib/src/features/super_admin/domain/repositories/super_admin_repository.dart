import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/company.dart';
import '../entities/plan.dart';
import '../entities/super_admin_dashboard_stats.dart';

abstract class SuperAdminRepository {
  Future<Either<Failure, SuperAdminDashboardStats>> getDashboardStats();

  Future<Either<Failure, List<Company>>> getCompanies({String? status, String? search, int page, int limit});
  Future<Either<Failure, Company>> getCompanyById(String id);
  Future<Either<Failure, Company>> createCompany({
    required String name,
    required String email,
    required String phone,
    String? address,
    String? gstNumber,
    required String ownerName,
    required String ownerEmail,
    required String ownerPassword,
  });
  Future<Either<Failure, Company>> updateCompany(String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> approveCompany(String id);
  Future<Either<Failure, void>> suspendCompany(String id);
  Future<Either<Failure, void>> activateCompany(String id);
  Future<Either<Failure, void>> expireCompanyNow(String id);
  Future<Either<Failure, void>> resetOwnerPassword(String id, String newPassword);
  Future<Either<Failure, void>> assignPlan(String companyId, {
    required String planId,
    required String billingCycle,
    DateTime? startDate,
    required DateTime endDate,
    double? customPrice,
  });

  Future<Either<Failure, List<Plan>>> getPlans();
  Future<Either<Failure, Plan>> createPlan({
    required String name,
    required double monthlyPrice,
    required double yearlyPrice,
    String? description,
  });
  Future<Either<Failure, Plan>> updatePlan(String id, Map<String, dynamic> data);
}
