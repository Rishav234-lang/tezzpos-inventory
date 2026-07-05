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
import '../../../subscription/presentation/providers/subscription_providers.dart';

class CompanyRegistrationScreen extends ConsumerStatefulWidget {
  const CompanyRegistrationScreen({super.key});

  @override
  ConsumerState<CompanyRegistrationScreen> createState() => _CompanyRegistrationScreenState();
}

class _CompanyRegistrationScreenState extends ConsumerState<CompanyRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Company
  final _companyNameController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyGstController = TextEditingController();

  // Owner
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPasswordController = TextEditingController();
  final _ownerConfirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Plan
  String? _selectedPlanId;
  String _billingCycle = 'MONTHLY';

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyEmailController.dispose();
    _companyPhoneController.dispose();
    _companyAddressController.dispose();
    _companyGstController.dispose();
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPasswordController.dispose();
    _ownerConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ownerPasswordController.text != _ownerConfirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppColors.error),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    await ref.read(authNotifierProvider.notifier).registerCompany(
      companyName: _companyNameController.text.trim(),
      companyEmail: _companyEmailController.text.trim(),
      companyPhone: _companyPhoneController.text.trim().isEmpty ? null : _companyPhoneController.text.trim(),
      companyAddress: _companyAddressController.text.trim().isEmpty ? null : _companyAddressController.text.trim(),
      companyGstNumber: _companyGstController.text.trim().isEmpty ? null : _companyGstController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      ownerEmail: _ownerEmailController.text.trim(),
      ownerPassword: _ownerPasswordController.text,
      planId: _selectedPlanId,
      billingCycle: _billingCycle,
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
    final authState = ref.watch(authNotifierProvider);
    final plansAsync = ref.watch(subscriptionPlansProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  style: IconButton.styleFrom(backgroundColor: AppColors.surfaceVariant),
                ),

                const SizedBox(height: 24),

                Hero(
                  tag: 'app_logo',
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 36),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Create Your Account',
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
                  'Start your 14-day free trial. No credit card required.',
                  style: context.textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 200)),

                const SizedBox(height: 24),

                // Stepper
                _buildStepper(),
                const SizedBox(height: 24),

                // Step content
                if (_currentStep == 0) _buildCompanyStep(),
                if (_currentStep == 1) _buildOwnerStep(),
                if (_currentStep == 2) _buildPlanStep(plansAsync),

                const SizedBox(height: 32),

                // Navigation buttons
                Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _currentStep--),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.onSurface,
                            side: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        text: _currentStep == 2 ? 'Create Account' : 'Next',
                        isLoading: authState.isLoading && _currentStep == 2,
                        onPressed: () {
                          if (_currentStep < 2) {
                            setState(() => _currentStep++);
                          } else {
                            _register();
                          }
                        },
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 600)),

                const SizedBox(height: 24),

                Center(
                  child: TextButton(
                    onPressed: () => context.pushReplacement(AppRoutes.companyLogin),
                    child: Text(
                      'Already have an account? Sign In',
                      style: context.textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 700)),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    final steps = ['Company', 'Owner', 'Plan'];
    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : isCompleted
                                ? AppColors.success
                                : AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive ? Colors.white : AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[index],
                      style: context.textTheme.labelSmall?.copyWith(
                        color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted ? AppColors.success : AppColors.outline.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCompanyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Company Name',
          hint: 'ABC Retail Pvt Ltd',
          controller: _companyNameController,
          prefixIcon: const Icon(Icons.business_outlined, color: AppColors.onSurfaceVariant),
          validator: (v) => v == null || v.isEmpty ? 'Company name is required' : null,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Company Email',
          hint: 'company@example.com',
          controller: _companyEmailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined, color: AppColors.onSurfaceVariant),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Phone (Optional)',
          hint: '+91 98765 43210',
          controller: _companyPhoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Address (Optional)',
          hint: '123 Business Street, City',
          controller: _companyAddressController,
          maxLines: 2,
          prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'GST Number (Optional)',
          hint: '24ABCDE1234F1Z5',
          controller: _companyGstController,
          prefixIcon: const Icon(Icons.receipt_outlined, color: AppColors.onSurfaceVariant),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: const Duration(milliseconds: 300))
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildOwnerStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Owner Name',
          hint: 'John Doe',
          controller: _ownerNameController,
          prefixIcon: const Icon(Icons.person_outline, color: AppColors.onSurfaceVariant),
          validator: (v) => v == null || v.isEmpty ? 'Owner name is required' : null,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Owner Email',
          hint: 'owner@example.com',
          controller: _ownerEmailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined, color: AppColors.onSurfaceVariant),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Email is required';
            if (!v.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Password',
          hint: 'Minimum 6 characters',
          controller: _ownerPasswordController,
          obscureText: _obscurePassword,
          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.onSurfaceVariant),
          suffixIcon: IconButton(
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password is required';
            if (v.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Confirm Password',
          hint: 'Re-enter your password',
          controller: _ownerConfirmPasswordController,
          obscureText: _obscureConfirmPassword,
          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.onSurfaceVariant),
          suffixIcon: IconButton(
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please confirm password';
            return null;
          },
        ),
      ],
    )
        .animate()
        .fadeIn(delay: const Duration(milliseconds: 300))
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildPlanStep(AsyncValue<List<Map<String, dynamic>>> plansAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select a Plan',
          style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Your 14-day free trial starts immediately. You can cancel anytime.',
          style: context.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        plansAsync.when(
          data: (plans) {
            if (plans.isEmpty) {
              return const _InfoCard(message: 'No plans available. Contact admin.');
            }
            return Column(
              children: plans.map((plan) {
                final isSelected = _selectedPlanId == plan['id'];
                final monthlyPrice = plan['monthlyPrice']?.toString() ?? '0';
                final yearlyPrice = plan['yearlyPrice']?.toString() ?? '0';
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedPlanId = plan['id'];
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.outline.withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                plan['name'] ?? 'Plan',
                                style: context.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          plan['description'] ?? '',
                          style: context.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Monthly: \u20b9$monthlyPrice / Yearly: \u20b9$yearlyPrice',
                          style: context.textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _InfoCard(message: e.toString().replaceFirst('Exception: ', '')),
        ),
        const SizedBox(height: 16),
        if (_selectedPlanId != null)
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'MONTHLY', label: Text('Monthly')),
              ButtonSegment(value: 'YEARLY', label: Text('Yearly')),
            ],
            selected: {_billingCycle},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() => _billingCycle = newSelection.first);
            },
          ),
      ],
    )
        .animate()
        .fadeIn(delay: const Duration(milliseconds: 300))
        .slideY(begin: 0.1, end: 0);
  }
}

class _InfoCard extends StatelessWidget {
  final String message;
  const _InfoCard({required this.message});

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
          Icon(Icons.info_outline, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: context.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
