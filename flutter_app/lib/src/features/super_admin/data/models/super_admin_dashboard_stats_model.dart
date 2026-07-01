import '../../domain/entities/super_admin_dashboard_stats.dart';

class SuperAdminDashboardStatsModel extends SuperAdminDashboardStats {
  const SuperAdminDashboardStatsModel({
    required super.totalCompanies,
    required super.activeCompanies,
    required super.trialCompanies,
    required super.suspendedCompanies,
    required super.totalRevenue,
    required super.expiringSubscriptions,
  });

  factory SuperAdminDashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return SuperAdminDashboardStatsModel(
      totalCompanies: json['totalCompanies'] ?? 0,
      activeCompanies: json['activeCompanies'] ?? 0,
      trialCompanies: json['trialCompanies'] ?? 0,
      suspendedCompanies: json['suspendedCompanies'] ?? 0,
      totalRevenue: _toDouble(json['totalRevenue']),
      expiringSubscriptions: json['expiringSubscriptions'] ?? 0,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCompanies': totalCompanies,
      'activeCompanies': activeCompanies,
      'trialCompanies': trialCompanies,
      'suspendedCompanies': suspendedCompanies,
      'totalRevenue': totalRevenue,
      'expiringSubscriptions': expiringSubscriptions,
    };
  }

  SuperAdminDashboardStats toEntity() {
    return SuperAdminDashboardStats(
      totalCompanies: totalCompanies,
      activeCompanies: activeCompanies,
      trialCompanies: trialCompanies,
      suspendedCompanies: suspendedCompanies,
      totalRevenue: totalRevenue,
      expiringSubscriptions: expiringSubscriptions,
    );
  }
}
