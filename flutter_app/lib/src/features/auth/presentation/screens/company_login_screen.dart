import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../../generated/l10n/app_localizations.dart';

class CompanyLoginScreen extends ConsumerStatefulWidget {
  const CompanyLoginScreen({super.key});

  @override
  ConsumerState<CompanyLoginScreen> createState() => _CompanyLoginScreenState();
}

class _CompanyLoginScreenState extends ConsumerState<CompanyLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    await ref.read(authNotifierProvider.notifier).loginCompanyOwner(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    final state = ref.read(authNotifierProvider);
    if (state.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.surfaceGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Header
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    l10n.companyLogin,
                    style: context.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 100))
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 8),

                  Text(
                    l10n.companyLoginSubtitle,
                    style: context.textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 200)),

                  const SizedBox(height: 40),

                  // Email field
                  AppTextField(
                    label: l10n.email,
                    hint: l10n.emailHint,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.onSurfaceVariant),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.emailRequired;
                      }
                      if (!value.contains('@')) {
                        return l10n.emailInvalid;
                      }
                      return null;
                    },
                  )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 300))
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 20),

                  // Password field
                  AppTextField(
                    label: l10n.password,
                    hint: l10n.passwordHint,
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.onSurfaceVariant),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    onFieldSubmitted: (_) => _login(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.passwordRequired;
                      }
                      if (value.length < 6) {
                        return l10n.passwordMinLength('6');
                      }
                      return null;
                    },
                  )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 400))
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 12),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(AppRoutes.forgotPassword),
                      child: Text(
                        l10n.forgotPassword,
                        style: context.textTheme.titleSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 500)),

                  const SizedBox(height: 24),

                  // Login button
                  AppButton(
                    text: l10n.login,
                    isLoading: authState.isLoading,
                    onPressed: _login,
                  )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 600))
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 32),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          l10n.or,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 700)),

                  const SizedBox(height: 24),

                  // Create account
                  Center(
                    child: TextButton.icon(
                      onPressed: () => context.push(AppRoutes.companyRegister),
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                      label: Text(l10n.createNewAccount),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 800)),

                  const SizedBox(height: 8),

                  // Switch to super admin
                  Center(
                    child: TextButton.icon(
                      onPressed: () => context.pushReplacement(AppRoutes.superAdminLogin),
                      icon: const Icon(Icons.admin_panel_settings_rounded, size: 20),
                      label: Text(l10n.loginAsSuperAdmin),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 900)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
