import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';

class ChooseRoleScreen extends StatefulWidget {
  const ChooseRoleScreen({super.key});

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.surfaceGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Logo
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                )
                    .animate()
                    .scale(duration: const Duration(milliseconds: 600), curve: Curves.easeOutBack)
                    .fadeIn(duration: const Duration(milliseconds: 400)),

                const SizedBox(height: 40),

                // Title
                Text(
                  AppStrings.chooseRoleTitle,
                  style: context.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 200))
                    .slideY(begin: 0.2, end: 0, delay: const Duration(milliseconds: 200)),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  AppStrings.chooseRoleSubtitle,
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 350)),

                const SizedBox(height: 48),

                // Role cards
                _RoleCard(
                  title: AppStrings.companyOwner,
                  description: 'Manage inventory, sales, purchases & billing for your store.',
                  icon: Icons.storefront_rounded,
                  gradient: AppColors.primaryGradient,
                  onTap: () => context.push(AppRoutes.companyLogin),
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 500))
                    .slideX(begin: -0.2, end: 0, delay: const Duration(milliseconds: 500)),

                const SizedBox(height: 16),

                _RoleCard(
                  title: AppStrings.superAdmin,
                  description: 'Manage companies, plans, subscriptions & platform analytics.',
                  icon: Icons.admin_panel_settings_rounded,
                  gradient: AppColors.secondaryGradient,
                  onTap: () => context.push(AppRoutes.superAdminLogin),
                )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 650))
                    .slideX(begin: 0.2, end: 0, delay: const Duration(milliseconds: 650)),

                const Spacer(),

                // Version
                Text(
                  'v1.0.0',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.outline, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
