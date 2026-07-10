import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../config/providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../../generated/l10n/app_localizations.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';
import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authNotifierProvider).valueOrNull?.user;
    final freshUserAsync = ref.watch(profileUserProvider);
    final user = freshUserAsync.valueOrNull ?? authUser;
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
    final l10n = AppLocalizations.of(context);
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
        ? l10n.noSubscriptionData
        : (isSubscriptionActive
              ? l10n.active
              : _statusText(rawSubscriptionStatus, l10n));
    final accountStatus = user?.companyStatus?.trim().isNotEmpty == true
        ? _statusText(user?.companyStatus, l10n)
        : (isSubscriptionActive
              ? l10n.active
              : _statusText(rawSubscriptionStatus, l10n));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(profileUserProvider),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                        l10n.profile,
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
                        if (context.mounted) context.go(AppRoutes.companyLogin);
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
                    companyNotAvailable: l10n.companyNotAvailable,
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(l10n.profileDetails),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.person_outline,
                        label: l10n.name,
                        value: name.isEmpty ? l10n.notAvailable : name,
                      ),
                      _InfoRow(
                        icon: Icons.mail_outline,
                        label: l10n.email,
                        value: email.isEmpty ? l10n.notAvailable : email,
                      ),
                      _InfoRow(
                        icon: Icons.storefront_outlined,
                        label: l10n.company,
                        value: companyName.isEmpty
                            ? l10n.notAvailable
                            : companyName,
                      ),
                      _InfoRow(
                        icon: Icons.badge_outlined,
                        label: l10n.role,
                        value: role.isEmpty ? l10n.notAvailable : _roleText(role, l10n),
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle(l10n.licenseAndSubscription),
                  _InfoCard(
                    children: [
                      _StatusRow(
                        label: l10n.license,
                        value: subscriptionStatus,
                        active: isSubscriptionActive,
                      ),
                      _InfoRow(
                        icon: Icons.verified_user_outlined,
                        label: l10n.accountStatus,
                        value: accountStatus,
                      ),
                      _InfoRow(
                        icon: Icons.event_available_outlined,
                        label: l10n.validTill,
                        value: subscriptionEndDate == null
                            ? l10n.notAvailable
                            : DateFormat(
                                'dd MMM yyyy',
                              ).format(subscriptionEndDate),
                      ),
                      _InfoRow(
                        icon: Icons.payments_outlined,
                        label: l10n.subscription,
                        value: planName.isEmpty
                            ? subscriptionStatus
                            : '$planName - $subscriptionStatus',
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle(l10n.currentSubscriptionData),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.confirmation_number_outlined,
                        label: l10n.subscriptionId,
                        value: subscriptionId.isEmpty
                            ? l10n.notAvailable
                            : subscriptionId,
                      ),
                      _InfoRow(
                        icon: Icons.workspace_premium_outlined,
                        label: l10n.plan,
                        value: planName.isEmpty
                            ? l10n.notAvailable
                            : (planCode.isEmpty
                                  ? planName
                                  : '$planName ($planCode)'),
                      ),
                      _InfoRow(
                        icon: Icons.calendar_month_outlined,
                        label: l10n.billingCycle,
                        value: billingCycle.isEmpty
                            ? l10n.notAvailable
                            : _statusText(billingCycle, l10n),
                      ),
                      _InfoRow(
                        icon: Icons.autorenew_outlined,
                        label: l10n.autoRenew,
                        value: autoRenew == null
                            ? l10n.notAvailable
                            : (autoRenew ? l10n.enabled : l10n.disabled),
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _LanguageSelector(),
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
                      label: Text(
                        l10n.viewSubscriptionDetails,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
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

  static String _statusText(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return l10n.notAvailable;
    final normalized = value.trim().toUpperCase();
    switch (normalized) {
      case 'ACTIVE':
        return l10n.active;
      case 'INACTIVE':
        return l10n.inactive;
      case 'TRIAL':
      case 'TRIALING':
        return l10n.trial;
      case 'EXPIRED':
        return l10n.expired;
      case 'SUSPENDED':
        return l10n.suspended;
      case 'PENDING':
        return l10n.pending;
      case 'APPROVED':
        return l10n.approved;
      case 'REJECTED':
        return l10n.rejected;
      case 'MONTHLY':
        return l10n.monthly;
      case 'YEARLY':
        return l10n.yearly;
      default:
        return value
            .split('_')
            .map((part) => part.toLowerCase().capitalize)
            .join(' ');
    }
  }

  static String _roleText(String? role, AppLocalizations l10n) {
    if (role == null || role.trim().isEmpty) return l10n.user;
    final normalized = role.trim().toUpperCase();
    switch (normalized) {
      case 'OWNER':
        return l10n.owner;
      case 'SUPER_ADMIN':
        return l10n.superAdmin;
      case 'USER':
        return l10n.user;
      default:
        return role
            .split('_')
            .map((part) => part.toLowerCase().capitalize)
            .join(' ');
    }
  }
}

class _LanguageSelector extends ConsumerWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider);

    String languageLabel(Locale locale) {
      switch (locale.languageCode) {
        case 'hi':
          return l10n.hindi;
        case 'mr':
          return l10n.marathi;
        case 'en':
        default:
          return l10n.english;
      }
    }

    return _InfoCard(
      children: [
        InkWell(
          onTap: () => _showLanguageDialog(context, ref),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.language_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.language,
                        style: context.textTheme.labelMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        languageLabel(currentLocale),
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(l10n.selectLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LanguageOption(
                label: l10n.english,
                localeCode: 'en',
              ),
              _LanguageOption(
                label: l10n.hindi,
                localeCode: 'hi',
              ),
              _LanguageOption(
                label: l10n.marathi,
                localeCode: 'mr',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
  }
}

class _LanguageOption extends ConsumerWidget {
  final String label;
  final String localeCode;

  const _LanguageOption({
    required this.label,
    required this.localeCode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isSelected = currentLocale.languageCode == localeCode;

    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : const SizedBox(width: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: () async {
        await ref.read(localeProvider.notifier).setLanguageCode(localeCode);
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).languageChanged,
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final String initials;
  final String name;
  final String email;
  final String companyName;
  final String companyNotAvailable;

  const _ProfileHero({
    required this.initials,
    required this.name,
    required this.email,
    required this.companyName,
    required this.companyNotAvailable,
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
                  companyName.isEmpty ? companyNotAvailable : companyName,
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
