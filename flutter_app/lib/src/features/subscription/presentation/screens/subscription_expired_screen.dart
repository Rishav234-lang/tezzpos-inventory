import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/providers.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../../generated/l10n/app_localizations.dart';
import '../providers/subscription_providers.dart';

// Conditionally import razorpay_flutter for non-web platforms
import 'package:razorpay_flutter/razorpay_flutter.dart'
    if (dart.library.html) 'stub_razorpay.dart';

class SubscriptionExpiredScreen extends ConsumerStatefulWidget {
  const SubscriptionExpiredScreen({super.key});

  @override
  ConsumerState<SubscriptionExpiredScreen> createState() => _SubscriptionExpiredScreenState();
}

class _SubscriptionExpiredScreenState extends ConsumerState<SubscriptionExpiredScreen> {
  Razorpay? _razorpay;
  bool _isRenewing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
    // Handle web checkout callback on init
    _checkWebCallback();
  }

  Future<void> _checkWebCallback() async {
    if (!kIsWeb) return;
    final uri = Uri.base;
    final paymentId = uri.queryParameters['razorpay_payment_id'];
    final orderId = uri.queryParameters['razorpay_order_id'];
    final signature = uri.queryParameters['razorpay_signature'];
    final status = uri.queryParameters['status'];

    if (status == 'cancelled') {
      if (mounted) setState(() => _errorMessage = AppLocalizations.of(context).paymentCancelled);
      return;
    }

    if (paymentId != null && orderId != null && signature != null) {
      final subscriptionNotifier = ref.read(subscriptionNotifierProvider.notifier);
      final mySub = await ref.read(mySubscriptionProvider.future);
      final plan = mySub?['plan'] as Map<String, dynamic>?;
      final billingCycle = mySub?['billingCycle'] as String? ?? 'MONTHLY';

      setState(() => _isRenewing = true);
      final verified = await subscriptionNotifier.verifyPayment(
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
        planId: plan?['id'] ?? '',
        billingCycle: billingCycle,
      );
      if (mounted) {
        setState(() => _isRenewing = false);
        if (verified) {
          ref.invalidate(mySubscriptionProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).paymentSuccessful), backgroundColor: AppColors.success),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) context.go(AppRoutes.dashboard);
          });
        } else {
          setState(() => _errorMessage = AppLocalizations.of(context).paymentVerificationFailed);
        }
      }
    }
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // One-time payment (orderId present) vs Subscription authorization (no orderId)
    if (response.orderId != null && response.orderId!.isNotEmpty) {
      // One-time payment - verify with backend
      final subscriptionNotifier = ref.read(subscriptionNotifierProvider.notifier);
      final mySub = await ref.read(mySubscriptionProvider.future);
      final plan = mySub?['plan'] as Map<String, dynamic>?;
      final billingCycle = mySub?['billingCycle'] as String? ?? 'MONTHLY';

      final verified = await subscriptionNotifier.verifyPayment(
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
        planId: plan?['id'] ?? '',
        billingCycle: billingCycle,
      );

      if (verified && mounted) {
        ref.invalidate(mySubscriptionProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).paymentSuccessful), backgroundColor: AppColors.success),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) context.go(AppRoutes.dashboard);
          });
        }
      } else if (mounted) {
        setState(() => _errorMessage = AppLocalizations.of(context).paymentVerificationFailed);
      }
    } else {
      // Subscription authorization - webhook handles backend update
      if (mounted) {
        ref.invalidate(mySubscriptionProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).autoPayAuthorizedSuccessfully), backgroundColor: AppColors.success),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.go(AppRoutes.dashboard);
        });
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _errorMessage = AppLocalizations.of(context).paymentFailed(response.message ?? ''));
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External wallet: ${response.walletName}');
  }

  Future<void> _renewSubscription() async {
    setState(() {
      _isRenewing = true;
      _errorMessage = null;
    });

    try {
      final subscriptionNotifier = ref.read(subscriptionNotifierProvider.notifier);
      final mySub = await ref.read(mySubscriptionProvider.future);
      final plan = mySub?['plan'] as Map<String, dynamic>?;
      final billingCycle = mySub?['billingCycle'] as String? ?? 'MONTHLY';
      final planId = plan?['id'] as String?;

      if (planId == null) {
        setState(() => _errorMessage = AppLocalizations.of(context).noSubscriptionPlanFound);
        return;
      }

      final orderData = await subscriptionNotifier.createOrder(
        planId: planId,
        billingCycle: billingCycle,
      );

      if (orderData == null) {
        setState(() => _errorMessage = AppLocalizations.of(context).failedToCreatePaymentOrder);
        return;
      }

      final user = ref.read(authNotifierProvider).valueOrNull?.user;

      if (kIsWeb) {
        // Web: redirect to backend checkout page
        final baseUrl = ApiConstants.baseUrl;
        final callbackUrl = '$baseUrl${AppRoutes.subscriptionExpired}';
        final checkoutUrl = Uri.parse('$baseUrl${ApiConstants.webCheckout}').replace(queryParameters: {
          'orderId': orderData['orderId']?.toString() ?? '',
          'keyId': orderData['keyId']?.toString() ?? '',
          'amount': orderData['amount']?.toString() ?? '0',
          'name': 'TezzPOS',
          'description': 'Subscription Renewal - ${orderData['planName'] ?? ''}',
          'email': user?.email ?? '',
          'callbackUrl': callbackUrl,
          'billingCycle': billingCycle,
        });
        if (await canLaunchUrl(checkoutUrl)) {
          await launchUrl(checkoutUrl, webOnlyWindowName: '_self');
        } else {
          setState(() => _errorMessage = AppLocalizations.of(context).couldNotOpenPaymentPage);
        }
        return;
      }

      // Mobile: use Razorpay Flutter SDK
      final options = {
        'key': orderData['keyId'] ?? '',
        'amount': orderData['amount'] ?? 0,
        'currency': orderData['currency'] ?? 'INR',
        'name': 'TezzPOS',
        'description': 'Subscription Renewal - ${orderData['planName'] ?? ''}',
        'order_id': orderData['orderId'] ?? '',
        'prefill': {
          'contact': '',
          'email': user?.email ?? '',
        },
        'theme': {
          'color': '#0D47A1',
        },
      };

      _razorpay?.open(options);
    } finally {
      if (mounted) setState(() => _isRenewing = false);
    }
  }

  Future<void> _enableAutoPay() async {
    setState(() {
      _isRenewing = true;
      _errorMessage = null;
    });

    try {
      if (kIsWeb) {
        setState(() => _errorMessage = AppLocalizations.of(context).autoPaySetupOnlyMobile);
        return;
      }

      final subscriptionNotifier = ref.read(subscriptionNotifierProvider.notifier);
      final mySub = await ref.read(mySubscriptionProvider.future);
      final plan = mySub?['plan'] as Map<String, dynamic>?;
      final billingCycle = mySub?['billingCycle'] as String? ?? 'MONTHLY';
      final planId = plan?['id'] as String?;

      if (planId == null) {
        setState(() => _errorMessage = AppLocalizations.of(context).noSubscriptionPlanFound);
        return;
      }

      final subData = await subscriptionNotifier.createRazorpaySubscription(
        planId: planId,
        billingCycle: billingCycle,
      );

      if (subData == null) {
        setState(() => _errorMessage = AppLocalizations.of(context).failedToCreateAutoPaySubscription);
        return;
      }

      final user = ref.read(authNotifierProvider).valueOrNull?.user;
      final options = {
        'key': subData['keyId'] ?? '',
        'subscription_id': subData['subscriptionId'] ?? '',
        'name': 'TezzPOS',
        'description': 'Enable Auto-Pay - ${subData['planName'] ?? ''}',
        'prefill': {
          'contact': '',
          'email': user?.email ?? '',
        },
        'theme': {
          'color': '#0D47A1',
        },
      };

      _razorpay?.open(options);
    } finally {
      if (mounted) setState(() => _isRenewing = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(authNotifierProvider.notifier).logout();
    if (mounted) context.go(AppRoutes.chooseRole);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.valueOrNull?.user;
    final subscriptionAsync = ref.watch(mySubscriptionProvider);

    final endDate = user?.subscriptionEndDate;
    final daysOverdue = endDate != null
        ? DateTime.now().difference(endDate).inDays
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: AppColors.error,
                ),
              )
                  .animate()
                  .scale(duration: const Duration(milliseconds: 500), curve: Curves.easeOutBack)
                  .fadeIn(),

              const SizedBox(height: 32),

              Text(
                l10n.subscriptionExpired,
                style: context.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 200))
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 12),

              Text(
                endDate != null
                    ? l10n.subscriptionEndedOn('${endDate.day} ${_monthName(endDate.month)} ${endDate.year}')
                    : l10n.subscriptionExpiredMessage,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 350))
                  .slideY(begin: 0.2, end: 0),

              if (daysOverdue != null && daysOverdue > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    daysOverdue == 1
                        ? l10n.oneDayOverdue(daysOverdue.toString())
                        : l10n.daysOverdue(daysOverdue.toString()),
                    style: context.textTheme.labelLarge?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 450)),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: context.textTheme.bodySmall?.copyWith(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Subscription details card
              subscriptionAsync.when(
                data: (subscription) {
                  if (subscription == null) return const SizedBox.shrink();
                  final plan = subscription['plan'] as Map<String, dynamic>?;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.currentPlan,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan?['name'] ?? l10n.unknownPlan,
                          style: context.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.billingLabel(subscription['billingCycle'] ?? 'MONTHLY'),
                          style: context.textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        if ((subscription['autoRenew'] as bool? ?? false)) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.repeat, size: 14, color: AppColors.success),
                              const SizedBox(width: 4),
                              Text(
                                l10n.autoRenewEnabled,
                                style: context.textTheme.labelSmall?.copyWith(color: AppColors.success),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 500));
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 32),

              AppButton(
                text: l10n.renewSubscription,
                isLoading: _isRenewing,
                onPressed: _renewSubscription,
              )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 600))
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 12),

              subscriptionAsync.when(
                data: (subscription) {
                  final autoRenew = subscription?['autoRenew'] as bool? ?? false;
                  if (autoRenew) return const SizedBox.shrink();
                  return OutlinedButton(
                    onPressed: _enableAutoPay,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text(l10n.enableAutoPay),
                  )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 700));
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: _logout,
                child: Text(
                  l10n.signOut,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 800)),

              const Spacer(),

              Text(
                '${l10n.needHelp} ${l10n.contactSupport}',
                style: context.textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }
}
