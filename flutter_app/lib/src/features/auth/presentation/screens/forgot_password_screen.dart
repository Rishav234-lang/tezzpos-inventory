import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _sent
              ? _buildSuccessView()
              : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Forgot Password?',
          style: context.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        )
            .animate()
            .fadeIn()
            .slideY(begin: 0.2, end: 0),
        const SizedBox(height: 12),
        Text(
          'Enter your email address and we\'ll send you instructions to reset your password.',
          style: context.textTheme.bodyLarge?.copyWith(
            color: AppColors.onSurfaceVariant,
            height: 1.5,
          ),
        )
            .animate()
            .fadeIn(delay: const Duration(milliseconds: 100)),
        const SizedBox(height: 40),
        Form(
          key: _formKey,
          child: AppTextField(
            label: 'Email Address',
            hint: 'you@company.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.onSurfaceVariant),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email is required';
              if (!value.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
        )
            .animate()
            .fadeIn(delay: const Duration(milliseconds: 200))
            .slideY(begin: 0.1, end: 0),
        const SizedBox(height: 32),
        AppButton(
          text: 'Send Reset Link',
          onPressed: _submit,
        )
            .animate()
            .fadeIn(delay: const Duration(milliseconds: 300))
            .slideY(begin: 0.1, end: 0),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              size: 48,
              color: AppColors.success,
            ),
          )
              .animate()
              .scale(curve: Curves.easeOutBack, duration: const Duration(milliseconds: 600)),
          const SizedBox(height: 32),
          Text(
            'Check your email',
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          )
              .animate()
              .fadeIn(delay: const Duration(milliseconds: 200)),
          const SizedBox(height: 12),
          Text(
            'We\'ve sent password reset instructions to ${_emailController.text}',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          )
              .animate()
              .fadeIn(delay: const Duration(milliseconds: 300)),
          const SizedBox(height: 40),
          AppButton(
            text: 'Back to Login',
            isOutlined: true,
            onPressed: () => context.pop(),
          )
              .animate()
              .fadeIn(delay: const Duration(milliseconds: 400)),
        ],
      ),
    );
  }
}
