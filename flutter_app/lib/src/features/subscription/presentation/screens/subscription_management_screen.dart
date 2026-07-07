import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/subscription_providers.dart';

class SubscriptionManagementScreen extends ConsumerStatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  ConsumerState<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends ConsumerState<SubscriptionManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final subscriptionAsync = ref.watch(mySubscriptionProvider);
    final paymentsAsync = ref.watch(subscriptionPaymentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Subscription',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              subscriptionAsync.when(
                data: (subscription) {
                  if (subscription == null) {
                    return const _InfoCard(
                      icon: Icons.info_outline,
                      message: 'No active subscription found.',
                    );
                  }
                  return _buildSubscriptionCard(subscription);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _InfoCard(
                  icon: Icons.error_outline,
                  message: 'Error loading subscription: $e',
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Payment History',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              paymentsAsync.when(
                data: (payments) {
                  if (payments.isEmpty) {
                    return const _InfoCard(
                      icon: Icons.receipt_long_outlined,
                      message: 'No payment history yet.',
                    );
                  }
                  return Column(
                    children: payments
                        .map((p) => _buildPaymentTile(p))
                        .toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _InfoCard(
                  icon: Icons.error_outline,
                  message: 'Error loading payments: $e',
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> subscription) {
    final plan = subscription['plan'] as Map<String, dynamic>?;
    final rawStatus = subscription['status'] as String? ?? 'UNKNOWN';
    final billingCycle = subscription['billingCycle'] as String? ?? 'MONTHLY';
    final autoRenew = subscription['autoRenew'] as bool? ?? false;
    final endDate = subscription['endDate'] != null
        ? DateTime.tryParse(subscription['endDate'].toString())
        : null;

    final isExpired = endDate != null && endDate.isBefore(DateTime.now());
    final isActive =
        !isExpired &&
        rawStatus.toUpperCase() != 'EXPIRED' &&
        rawStatus.toUpperCase() != 'SUSPENDED';
    final status = isActive ? 'ACTIVE' : rawStatus;
    final daysLeft = endDate != null && !isExpired
        ? endDate.difference(DateTime.now()).inDays
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (autoRenew)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.repeat,
                        size: 14,
                        color: AppColors.successLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Auto-Pay',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: AppColors.successLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            plan?['name'] ?? 'Unknown Plan',
            style: context.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Billing: ${billingCycle.toLowerCase()}',
            style: context.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          if (endDate != null) ...[
            Row(
              children: [
                Icon(
                  isExpired ? Icons.warning_amber : Icons.calendar_today,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 8),
                Text(
                  isExpired
                      ? 'Expired on ${DateFormat('dd MMM yyyy').format(endDate)}'
                      : daysLeft != null && daysLeft <= 7
                      ? 'Expires in $daysLeft day${daysLeft == 1 ? '' : 's'}'
                      : 'Valid until ${DateFormat('dd MMM yyyy').format(endDate)}',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: isExpired || (daysLeft != null && daysLeft <= 7)
                        ? AppColors.warningLight
                        : Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isActive
                        ? 'Your account status is Active.'
                        : 'Your subscription is not active. Please contact support.',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isLoading,
    required VoidCallback onPressed,
    bool outlined = false,
  }) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _toggleAutoRenew(bool value) async {
    final notifier = ref.read(subscriptionNotifierProvider.notifier);
    if (!value) {
      // Cancelling auto-pay
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cancel Auto-Pay?'),
          content: const Text(
            'Your subscription will not renew automatically. You will need to renew manually when it expires.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep Auto-Pay'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      final success = await notifier.cancelAutoPay();
      if (success && mounted) {
        ref.invalidate(mySubscriptionProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auto-pay cancelled'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      // Enabling auto-pay - redirect to expired screen flow or show info
      final success = await notifier.toggleAutoRenew(true);
      if (success && mounted) {
        ref.invalidate(mySubscriptionProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auto-pay enabled'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Widget _buildPaymentTile(Map<String, dynamic> payment) {
    final amount = payment['amount'];
    final paymentDate = payment['paymentDate'] != null
        ? DateTime.tryParse(payment['paymentDate'].toString())
        : null;
    final status = payment['status'] as String? ?? 'PENDING';
    final razorpayId = payment['razorpayPaymentId'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: status == 'SUCCESS'
                  ? AppColors.successLight
                  : AppColors.warningLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              status == 'SUCCESS' ? Icons.check : Icons.hourglass_empty,
              color: status == 'SUCCESS'
                  ? AppColors.success
                  : AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\u20b9${amount ?? '0.00'}',
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  paymentDate != null
                      ? DateFormat('dd MMM yyyy, hh:mm a').format(paymentDate)
                      : '-',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (razorpayId != null)
                  Text(
                    'ID: $razorpayId',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'SUCCESS'
                  ? AppColors.successLight
                  : AppColors.warningLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: context.textTheme.labelSmall?.copyWith(
                color: status == 'SUCCESS'
                    ? AppColors.success
                    : AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _InfoCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: context.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
