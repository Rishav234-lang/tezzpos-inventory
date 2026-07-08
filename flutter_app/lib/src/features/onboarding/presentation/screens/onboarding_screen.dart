import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../../generated/l10n/app_localizations.dart';

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

List<OnboardingPage> _buildPages(AppLocalizations l10n) => [
  OnboardingPage(
    title: l10n.onboardingTitle1,
    description: l10n.onboardingDesc1,
    icon: Icons.inventory_2_rounded,
    color: AppColors.primary,
  ),
  OnboardingPage(
    title: l10n.onboardingTitle2,
    description: l10n.onboardingDesc2,
    icon: Icons.receipt_long_rounded,
    color: AppColors.secondary,
  ),
  OnboardingPage(
    title: l10n.onboardingTitle3,
    description: l10n.onboardingDesc3,
    icon: Icons.trending_up_rounded,
    color: const Color(0xFF059669),
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) {
      context.go(AppRoutes.chooseRole);
    }
  }

  void _nextPage(int pageCount) {
    if (_currentPage < pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = _buildPages(l10n);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20, top: 8),
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: Text(
                    l10n.skip,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  return _OnboardingPageView(page: pages[index]);
                },
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pages.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 28 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.outlineVariant,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  // Next / Get Started button
                  AppButton(
                    text: _currentPage == pages.length - 1
                        ? l10n.getStarted
                        : l10n.next,
                    onPressed: () => _nextPage(pages.length),
                    icon: _currentPage == pages.length - 1
                        ? Icons.arrow_forward_rounded
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  final OnboardingPage page;

  const _OnboardingPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container with gradient
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  page.color.withValues(alpha: 0.15),
                  page.color.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              page.icon,
              size: 80,
              color: page.color,
            ),
          )
              .animate()
              .scale(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: const Duration(milliseconds: 400)),

          const SizedBox(height: 48),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: context.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          )
              .animate()
              .fadeIn(delay: const Duration(milliseconds: 200))
              .slideY(
                begin: 0.3,
                end: 0,
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              ),

          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.6,
            ),
          )
              .animate()
              .fadeIn(delay: const Duration(milliseconds: 400))
              .slideY(
                begin: 0.2,
                end: 0,
                delay: const Duration(milliseconds: 400),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              ),
        ],
      ),
    );
  }
}
