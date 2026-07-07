import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../config/providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull?.user;
    final subscription = ref.watch(mySubscriptionProvider).valueOrNull;
    final name = user?.name.trim().isNotEmpty == true ? user!.name : '';
    final email = user?.email.trim() ?? '';
    final companyName = user?.companyName?.trim().isNotEmpty == true
        ? user!.companyName!
        : '';
    final role = user?.role ?? '';
    final plan = subscription?['plan'] as Map<String, dynamic>?;
    final planName = plan?['name']?.toString() ?? '';
    final planCode = plan?['code']?.toString() ?? '';
    final rawSubscriptionStatus = subscription?['status']?.toString();
    final billingCycle = subscription?['billingCycle']?.toString() ?? '';
    final autoRenew = subscription?['autoRenew'] as bool?;
    final subscriptionId = subscription?['id']?.toString() ?? '';
    final subscriptionEndDate =
        _dateFrom(subscription?['endDate']) ?? user?.subscriptionEndDate;
    final isSubscriptionActive = _isValidSubscription(
      rawSubscriptionStatus,
      subscriptionEndDate,
    );
    final subscriptionStatus = subscription == null
        ? 'No subscription data'
        : (isSubscriptionActive
              ? 'Active'
              : _statusText(rawSubscriptionStatus));
    final accountStatus = user?.companyStatus?.trim().isNotEmpty == true
        ? _statusText(user?.companyStatus)
        : (isSubscriptionActive
              ? 'Active'
              : _statusText(rawSubscriptionStatus));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    _IconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => context.pop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Profile',
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    _IconButton(
                      icon: Icons.logout_rounded,
                      onTap: () async {
                        await ref.read(authNotifierProvider.notifier).logout();
                        if (context.mounted) context.go(AppRoutes.chooseRole);
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _ProfileHero(
                    initials: _initials(name.isNotEmpty ? name : companyName),
                    name: name,
                    email: email,
                    companyName: companyName,
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle('Profile Details'),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.person_outline,
                        label: 'Name',
                        value: name.isEmpty ? 'Not available' : name,
                      ),
                      _InfoRow(
                        icon: Icons.mail_outline,
                        label: 'Email',
                        value: email.isEmpty ? 'Not available' : email,
                      ),
                      _InfoRow(
                        icon: Icons.storefront_outlined,
                        label: 'Company',
                        value: companyName.isEmpty
                            ? 'Not available'
                            : companyName,
                      ),
                      _InfoRow(
                        icon: Icons.badge_outlined,
                        label: 'Role',
                        value: role.isEmpty ? 'Not available' : _roleText(role),
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle('License & Subscription'),
                  _InfoCard(
                    children: [
                      _StatusRow(
                        label: 'License',
                        value: subscriptionStatus,
                        active: isSubscriptionActive,
                      ),
                      _InfoRow(
                        icon: Icons.verified_user_outlined,
                        label: 'Account status',
                        value: accountStatus,
                      ),
                      _InfoRow(
                        icon: Icons.event_available_outlined,
                        label: 'Valid till',
                        value: subscriptionEndDate == null
                            ? 'Not available'
                            : DateFormat(
                                'dd MMM yyyy',
                              ).format(subscriptionEndDate),
                      ),
                      _InfoRow(
                        icon: Icons.payments_outlined,
                        label: 'Subscription',
                        value: planName.isEmpty
                            ? subscriptionStatus
                            : '$planName - $subscriptionStatus',
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle('Current Subscription Data'),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.confirmation_number_outlined,
                        label: 'Subscription ID',
                        value: subscriptionId.isEmpty
                            ? 'Not available'
                            : subscriptionId,
                      ),
                      _InfoRow(
                        icon: Icons.workspace_premium_outlined,
                        label: 'Plan',
                        value: planName.isEmpty
                            ? 'Not available'
                            : (planCode.isEmpty
                                  ? planName
                                  : '$planName ($planCode)'),
                      ),
                      _InfoRow(
                        icon: Icons.calendar_month_outlined,
                        label: 'Billing cycle',
                        value: billingCycle.isEmpty
                            ? 'Not available'
                            : _statusText(billingCycle),
                      ),
                      _InfoRow(
                        icon: Icons.autorenew_outlined,
                        label: 'Auto renew',
                        value: autoRenew == null
                            ? 'Not available'
                            : (autoRenew ? 'Enabled' : 'Disabled'),
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () =>
                          context.push(AppRoutes.subscriptionManagement),
                      icon: const Icon(Icons.workspace_premium_outlined),
                      label: const Text(
                        'View Subscription Details',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static bool _isActive(String? status) {
    final normalized = status?.toUpperCase();
    return normalized == 'ACTIVE' || normalized == 'TRIALING';
  }

  static bool _isValidSubscription(String? status, DateTime? endDate) {
    final normalized = status?.toUpperCase();
    if (normalized == 'EXPIRED' || normalized == 'SUSPENDED') return false;
    if (endDate != null && endDate.isBefore(DateTime.now())) return false;
    return normalized == 'ACTIVE' ||
        normalized == 'TRIALING' ||
        normalized == 'PAID' ||
        endDate != null;
  }

  static DateTime? _dateFrom(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static String _statusText(String? value) {
    if (value == null || value.trim().isEmpty) return 'Not available';
    return value
        .split('_')
        .map((part) => part.toLowerCase().capitalize)
        .join(' ');
  }

  static String _roleText(String? role) {
    if (role == null || role.trim().isEmpty) return 'User';
    return role
        .split('_')
        .map((part) => part.toLowerCase().capitalize)
        .join(' ');
  }
}

class _ProfileHero extends StatelessWidget {
  final String initials;
  final String name;
  final String email;
  final String companyName;

  const _ProfileHero({
    required this.initials,
    required this.name,
    required this.email,
    required this.companyName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email.isEmpty ? companyName : email,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  companyName.isEmpty ? 'Company not available' : companyName,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        title,
        style: context.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w900,
          color: AppColors.onSurface,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final bool active;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.success : AppColors.warning;
    final bg = active ? AppColors.successLight : AppColors.warningLight;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.workspace_premium_outlined,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outline),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}
