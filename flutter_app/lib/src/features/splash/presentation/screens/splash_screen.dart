import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../presentation/providers/splash_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _taglineController;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _textController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _taglineController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _runAnimationSequence();
  }

  Future<void> _runAnimationSequence() async {
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    await _textController.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    await _taglineController.forward();

    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      _navigateNext();
    }
  }

  void _navigateNext() {
    final hasSeenOnboarding = ref.read(onboardingSeenProvider);
    final authState = ref.read(authNotifierProvider);

    if (authState.valueOrNull?.isAuthenticated == true) {
      context.go(AppRoutes.dashboard);
    } else if (!hasSeenOnboarding) {
      context.go(AppRoutes.onboarding);
    } else {
      context.go(AppRoutes.chooseRole);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _taglineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Icon
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _logoController,
                  curve: Curves.elasticOut,
                ),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // App Name
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _textController,
                  curve: Curves.easeOut,
                ),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(_textController),
                  child: Text(
                    AppStrings.appName,
                    style: context.textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Tagline
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: _taglineController,
                  curve: Curves.easeOut,
                ),
                child: Text(
                  AppStrings.tagline,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 60),
              // Loading indicator
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(
                    Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              )
                .animate(onPlay: (controller) => controller.repeat())
                .rotate(duration: const Duration(seconds: 1)),
            ],
          ),
        ),
      ),
    );
  }
}
