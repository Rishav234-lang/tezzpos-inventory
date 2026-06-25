import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/providers/auth_provider.dart';

final superAdminDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.superAdminDashboard);
  return response.data as Map<String, dynamic>;
});

final superAdminRecentCompaniesProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.superAdminCompanies, queryParams: {'page': '1', 'limit': '5'});
  final data = response.data as Map<String, dynamic>;
  return data['data'] as List<dynamic>? ?? [];
});

class SuperAdminDashboardScreen extends ConsumerWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(superAdminDashboardProvider);
    final authUser = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(superAdminDashboardProvider);
              ref.invalidate(superAdminRecentCompaniesProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(superAdminDashboardProvider);
          ref.invalidate(superAdminRecentCompaniesProvider);
        },
        child: statsAsync.when(
          loading: () => const AppLoading(message: 'Loading dashboard...'),
          error: (err, _) => AppErrorWidget(
            message: parseApiError(err),
            onRetry: () => ref.invalidate(superAdminDashboardProvider),
          ),
          data: (stats) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WelcomeBanner(name: authUser?.name ?? 'Admin'),
                const SizedBox(height: 20),
                _StatsGrid(stats: stats),
                const SizedBox(height: 20),
                _QuickActions(),
                const SizedBox(height: 20),
                _RecentCompaniesCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final String name;
  const _WelcomeBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'A',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, $name', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Super Administrator', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Super Admin', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatData('Total Companies', '${stats['totalCompanies'] ?? 0}', Icons.business_outlined, AppColors.primary),
      _StatData('Active Companies', '${stats['activeCompanies'] ?? 0}', Icons.check_circle_outline, AppColors.success),
      _StatData('Trial / Pending', '${stats['trialCompanies'] ?? 0}', Icons.hourglass_empty_outlined, AppColors.warning),
      _StatData('Suspended', '${stats['suspendedCompanies'] ?? 0}', Icons.block_outlined, AppColors.error),
      _StatData('Total Revenue', '\u20b9${_fmt(stats['totalRevenue'])}', Icons.currency_rupee_outlined, AppColors.info),
      _StatData('Expiring Soon', '${stats['expiringSubscriptions'] ?? 0}', Icons.event_busy_outlined, AppColors.warning),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 3 : constraints.maxWidth > 500 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: crossAxisCount == 2 ? 1.8 : 2.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final c = cards[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: c.color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Icon(c.icon, size: 18, color: c.color),
                    ),
                    const SizedBox(height: 10),
                    Text(c.value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(c.title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static String _fmt(dynamic amount) {
    if (amount == null) return '0';
    final num value = amount is num ? amount : num.tryParse(amount.toString()) ?? 0;
    if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(1)}Cr';
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}

class _StatData {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatData(this.title, this.value, this.icon, this.color);
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ActionChip(
              icon: Icons.add_business_outlined,
              label: 'Add Company',
              color: AppColors.primary,
              onTap: () => context.go('/super-admin/companies'),
            ),
            _ActionChip(
              icon: Icons.business_outlined,
              label: 'Manage Companies',
              color: AppColors.secondary,
              onTap: () => context.go('/super-admin/companies'),
            ),
            _ActionChip(
              icon: Icons.workspace_premium_outlined,
              label: 'Manage Plans',
              color: AppColors.info,
              onTap: () => context.go('/super-admin/plans'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}

class _RecentCompaniesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(superAdminRecentCompaniesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.business_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                const Expanded(child: Text('Recent Companies', style: TextStyle(fontWeight: FontWeight.w600))),
                TextButton(
                  onPressed: () => context.go('/super-admin/companies'),
                  child: const Text('View All', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const Divider(),
            companiesAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (err, _) => Padding(padding: const EdgeInsets.all(8), child: Text(parseApiError(err), style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
              data: (companies) {
                if (companies.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('No companies yet', style: TextStyle(color: Colors.grey))),
                  );
                }
                return Column(
                  children: companies.map<Widget>((c) {
                    final status = c['status'] as String? ?? 'UNKNOWN';
                    final statusColor = _statusColor(status);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => context.push('/super-admin/companies/${c['id']}'),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Text(
                                (c['name'] as String? ?? '?')[0].toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c['name'] as String? ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                  Text(c['email'] as String? ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE': return AppColors.success;
      case 'SUSPENDED': return AppColors.error;
      case 'PENDING': return AppColors.warning;
      default: return Colors.grey;
    }
  }
}
