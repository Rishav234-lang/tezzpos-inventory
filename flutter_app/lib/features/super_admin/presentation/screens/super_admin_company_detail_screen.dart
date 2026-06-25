import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/utils/error_utils.dart';

final companyDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiConstants.superAdminCompanyDetail(id));
  return response.data as Map<String, dynamic>;
});

class SuperAdminCompanyDetailScreen extends ConsumerWidget {
  final String companyId;
  const SuperAdminCompanyDetailScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(companyDetailProvider(companyId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/super-admin/companies'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(companyDetailProvider(companyId)),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const AppLoading(),
        error: (err, _) => AppErrorWidget(
          message: parseApiError(err),
          onRetry: () => ref.invalidate(companyDetailProvider(companyId)),
        ),
        data: (company) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CompanyHeader(company: company),
              const SizedBox(height: 16),
              _OwnerInfoCard(company: company),
              const SizedBox(height: 16),
              _SubscriptionInfoCard(company: company),
              const SizedBox(height: 16),
              _CompanyMetaCard(company: company),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanyHeader extends StatelessWidget {
  final Map<String, dynamic> company;
  const _CompanyHeader({required this.company});

  @override
  Widget build(BuildContext context) {
    final status = company['status'] as String? ?? 'UNKNOWN';
    final statusColor = _statusColor(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                (company['name'] as String? ?? '?')[0].toUpperCase(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(company['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(company['email'] as String? ?? '', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
                  ),
                ],
              ),
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

class _OwnerInfoCard extends StatelessWidget {
  final Map<String, dynamic> company;
  const _OwnerInfoCard({required this.company});

  @override
  Widget build(BuildContext context) {
    final owner = company['owner'] as Map<String, dynamic>?;
    if (owner == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Owner Information', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.person, label: 'Name', value: owner['name'] as String? ?? 'N/A'),
            _InfoRow(icon: Icons.email, label: 'Email', value: owner['email'] as String? ?? 'N/A'),
            _InfoRow(icon: Icons.phone, label: 'Phone', value: owner['phone'] as String? ?? 'N/A'),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionInfoCard extends StatelessWidget {
  final Map<String, dynamic> company;
  const _SubscriptionInfoCard({required this.company});

  @override
  Widget build(BuildContext context) {
    final subscription = company['subscription'] as Map<String, dynamic>?;
    final plan = subscription?['plan'] as Map<String, dynamic>?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Subscription', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            if (subscription == null || plan == null)
              const Text('No active subscription', style: TextStyle(color: Colors.grey))
            else ...[
              _InfoRow(icon: Icons.label, label: 'Plan', value: plan['name'] as String? ?? 'N/A'),
              _InfoRow(icon: Icons.currency_rupee, label: 'Price', value: '\u20b9${plan['monthlyPrice'] ?? 0}/mo'),
              _InfoRow(icon: Icons.event, label: 'Start Date', value: _formatDate(subscription['startDate']?.toString())),
              _InfoRow(icon: Icons.event_busy, label: 'End Date', value: _formatDate(subscription['endDate']?.toString())),
              _InfoRow(icon: Icons.info, label: 'Status', value: subscription['status'] as String? ?? 'N/A'),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'N/A';
    return date.length >= 10 ? date.substring(0, 10) : date;
  }
}

class _CompanyMetaCard extends StatelessWidget {
  final Map<String, dynamic> company;
  const _CompanyMetaCard({required this.company});

  @override
  Widget build(BuildContext context) {
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
                const Text('Company Information', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.phone, label: 'Phone', value: company['phone'] as String? ?? 'N/A'),
            _InfoRow(icon: Icons.location_on, label: 'Address', value: company['address'] as String? ?? 'N/A'),
            _InfoRow(icon: Icons.numbers, label: 'GST Number', value: company['gstNumber'] as String? ?? 'N/A'),
            _InfoRow(icon: Icons.calendar_today, label: 'Created', value: _formatDate(company['createdAt']?.toString())),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'N/A';
    return date.length >= 10 ? date.substring(0, 10) : date;
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
