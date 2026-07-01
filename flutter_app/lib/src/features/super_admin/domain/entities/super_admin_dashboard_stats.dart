import 'package:equatable/equatable.dart';

class SuperAdminDashboardStats extends Equatable {
  final int totalCompanies;
  final int activeCompanies;
  final int trialCompanies;
  final int suspendedCompanies;
  final double totalRevenue;
  final int expiringSubscriptions;

  const SuperAdminDashboardStats({
    required this.totalCompanies,
    required this.activeCompanies,
    required this.trialCompanies,
    required this.suspendedCompanies,
    required this.totalRevenue,
    required this.expiringSubscriptions,
  });

  @override
  List<Object?> get props => [totalCompanies, activeCompanies, trialCompanies, suspendedCompanies, totalRevenue, expiringSubscriptions];
}
