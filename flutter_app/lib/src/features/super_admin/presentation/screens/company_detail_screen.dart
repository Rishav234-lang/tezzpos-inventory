import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/super_admin_providers.dart';

class CompanyDetailScreen extends ConsumerWidget {
  final String companyId;

  const CompanyDetailScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(companyDetailProvider(companyId));
    final currency = NumberFormat('#,##,##0.00');
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Company Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('${AppRoutes.editCompany}/$companyId'),
          ),
        ],
      ),
      body: companyAsync.when(
        data: (company) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(companyDetailProvider(companyId)),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, company),
                  const SizedBox(height: 16),
                  _buildInfoSection(context, company, dateFormat),
                  const SizedBox(height: 16),
                  if (company.subscription != null)
                    _buildSubscriptionCard(context, company, dateFormat, currency),
                  const SizedBox(height: 24),
                  _buildActions(context, ref, company),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic company) {
    Color statusColor;
    if (company.isActive) {
      statusColor = const Color(0xFF2E7D32);
    } else if (company.isSuspended) {
      statusColor = AppColors.error;
    } else {
      statusColor = const Color(0xFFEF6C00);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFFE3F2FD),
            child: Text(company.initials, style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 20)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(company.name, style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(company.email, style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(company.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, dynamic company, DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Company Info', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.phone, label: 'Phone', value: company.phone ?? 'N/A'),
          _InfoRow(icon: Icons.location_on, label: 'Address', value: company.address ?? 'N/A'),
          _InfoRow(icon: Icons.receipt, label: 'GST', value: company.gstNumber ?? 'N/A'),
          _InfoRow(icon: Icons.calendar_today, label: 'Created', value: dateFormat.format(company.createdAt)),
          const Divider(height: 24),
          if (company.owner != null) ...[
            Text('Owner', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.person, label: 'Name', value: company.owner!.name),
            _InfoRow(icon: Icons.email, label: 'Email', value: company.owner!.email),
            _InfoRow(icon: Icons.phone, label: 'Phone', value: company.owner!.phone ?? 'N/A'),
          ],
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, dynamic company, DateFormat dateFormat, NumberFormat currency) {
    final sub = company.subscription!;
    final isExpired = sub.isExpired;
    final isExpiringSoon = sub.isExpiringSoon;

    Color subColor = const Color(0xFF2E7D32);
    if (isExpired) {
      subColor = AppColors.error;
    } else if (isExpiringSoon) {
      subColor = const Color(0xFFEF6C00);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subscription', style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: subColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(sub.status, style: TextStyle(fontSize: 11, color: subColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.card_membership, label: 'Plan', value: sub.planName ?? 'Unknown'),
          _InfoRow(icon: Icons.repeat, label: 'Cycle', value: sub.billingCycle),
          _InfoRow(icon: Icons.date_range, label: 'Start', value: dateFormat.format(sub.startDate)),
          _InfoRow(icon: Icons.event, label: 'End', value: dateFormat.format(sub.endDate)),
          if (sub.customPrice != null)
            _InfoRow(icon: Icons.currency_rupee, label: 'Custom Price', value: 'Rs. ${currency.format(sub.customPrice)}'),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, dynamic company) {
    final isLoading = ref.watch(superAdminNotifierProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (company.isPending)
          FilledButton.icon(
            onPressed: isLoading ? null : () async {
              final ok = await ref.read(superAdminNotifierProvider.notifier).approveCompany(companyId);
              if (ok) {
                ref.invalidate(companyDetailProvider(companyId));
                ref.invalidate(companiesProvider(const CompanyFilter()));
              }
            },
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Approve Company'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
          ),
        if (company.isPending) const SizedBox(height: 8),
        if (!company.isSuspended)
          OutlinedButton.icon(
            onPressed: isLoading ? null : () async {
              final ok = await ref.read(superAdminNotifierProvider.notifier).suspendCompany(companyId);
              if (ok) {
                ref.invalidate(companyDetailProvider(companyId));
                ref.invalidate(companiesProvider(const CompanyFilter()));
              }
            },
            icon: const Icon(Icons.block, size: 18),
            label: const Text('Suspend'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
          ),
        if (company.isSuspended) const SizedBox(height: 8),
        if (company.isSuspended)
          FilledButton.icon(
            onPressed: isLoading ? null : () async {
              final ok = await ref.read(superAdminNotifierProvider.notifier).activateCompany(companyId);
              if (ok) {
                ref.invalidate(companyDetailProvider(companyId));
                ref.invalidate(companiesProvider(const CompanyFilter()));
              }
            },
            icon: const Icon(Icons.play_circle, size: 18),
            label: const Text('Activate'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: isLoading ? null : () => _showResetPasswordDialog(context, ref),
          icon: const Icon(Icons.lock_reset, size: 18),
          label: const Text('Reset Owner Password'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => context.push('${AppRoutes.assignPlan}/$companyId'),
          icon: const Icon(Icons.card_membership, size: 18),
          label: const Text('Assign / Change Plan'),
        ),
      ],
    );
  }

  void _showResetPasswordDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Owner Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New Password', hintText: 'Min 6 characters'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final password = controller.text.trim();
              if (password.length < 6) return;
              Navigator.pop(ctx);
              final ok = await ref.read(superAdminNotifierProvider.notifier).resetOwnerPassword(companyId, password);
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successfully')));
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 8),
          SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
