import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../config/providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/super_admin_dashboard_stats.dart';
import '../providers/super_admin_providers.dart';

class SuperAdminDashboardScreen extends ConsumerWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(superAdminDashboardStatsProvider);
    final currency = NumberFormat('#,##,##0.00');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Super Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(superAdminDashboardStatsProvider),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(context, ref),
                const SizedBox(height: 20),
                statsAsync.when(
                  data: (stats) => _buildStatsGrid(context, stats, currency),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
                const SizedBox(height: 24),
                _buildQuickActions(context),
                const SizedBox(height: 24),
                _buildRecentSection(context, ref),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.valueOrNull?.user;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.secondaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${user?.name ?? 'Admin'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, SuperAdminDashboardStats stats, NumberFormat currency) {
    return Column(
      children: [
        Row(
          children: [
            _StatCard(
              label: 'Total Companies',
              value: '${stats.totalCompanies}',
              icon: Icons.business,
              color: const Color(0xFF1565C0),
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Active',
              value: '${stats.activeCompanies}',
              icon: Icons.check_circle,
              color: const Color(0xFF2E7D32),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatCard(
              label: 'Trial',
              value: '${stats.trialCompanies}',
              icon: Icons.timelapse,
              color: const Color(0xFFEF6C00),
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Suspended',
              value: '${stats.suspendedCompanies}',
              icon: Icons.block,
              color: AppColors.error,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatCard(
              label: 'Total Revenue',
              value: 'Rs. ${currency.format(stats.totalRevenue)}',
              icon: Icons.currency_rupee,
              color: const Color(0xFF6A1B9A),
            ),
            const SizedBox(width: 12),
            _StatCard(
              label: 'Expiring Soon',
              value: '${stats.expiringSubscriptions}',
              icon: Icons.event_busy,
              color: const Color(0xFFC62828),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            _ActionButton(
              icon: Icons.business,
              label: 'Companies',
              color: const Color(0xFF1565C0),
              onTap: () => context.push(AppRoutes.companies),
            ),
            const SizedBox(width: 12),
            _ActionButton(
              icon: Icons.card_membership,
              label: 'Plans',
              color: const Color(0xFF6A1B9A),
              onTap: () => context.push(AppRoutes.plans),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _ActionButton(
              icon: Icons.person_add,
              label: 'Add Company',
              color: const Color(0xFF2E7D32),
              onTap: () => context.push(AppRoutes.addCompany),
            ),
            const SizedBox(width: 12),
            _ActionButton(
              icon: Icons.add_card,
              label: 'Add Plan',
              color: const Color(0xFFEF6C00),
              onTap: () => context.push(AppRoutes.addPlan),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Companies', style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => context.push(AppRoutes.companies),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, child) {
            final companiesAsync = ref.watch(companiesProvider(const CompanyFilter(limit: 5)));
            return companiesAsync.when(
              data: (companies) {
                if (companies.isEmpty) {
                  return _buildEmptyState('No companies yet');
                }
                return Column(
                  children: companies.map((company) => _CompanyListTile(company: company)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, style: TextStyle(color: AppColors.onSurfaceVariant)),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanyListTile extends StatelessWidget {
  final Company company;

  const _CompanyListTile({required this.company});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    if (company.isActive) {
      statusColor = const Color(0xFF2E7D32);
    } else if (company.isSuspended) {
      statusColor = AppColors.error;
    } else {
      statusColor = const Color(0xFFEF6C00);
    }

    return InkWell(
      onTap: () => context.push('${AppRoutes.companyDetail}/${company.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE3F2FD),
              child: Text(company.initials, style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(company.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(company.email, style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(company.status, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
