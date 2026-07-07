import 'package:flutter/material.dart';

class AppColors {
  // Primary palette
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Secondary / Accent
  static const Color secondary = Color(0xFF2563EB);
  static const Color secondaryLight = Color(0xFF60A5FA);
  static const Color secondaryDark = Color(0xFF1D4ED8);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // Containers
  static const Color primaryContainer = Color(0xFFEDE9FE);
  static const Color secondaryContainer = Color(0xFFE0E7FF);

  // Backgrounds
  static const Color background = Color(0xFFF8FAFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1EEFF);
  static const Color backgroundDark = Color(0xFF111827);
  static const Color surfaceDark = Color(0xFF1F2937);
  static const Color surfaceVariantDark = Color(0xFF273449);

  // Text
  static const Color onSurface = Color(0xFF111827);
  static const Color onSurfaceVariant = Color(0xFF64748B);
  static const Color onSurfaceDark = Color(0xFFF8FAFC);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF6366F1);
  static const Color infoLight = Color(0xFFE0E7FF);
  static const Color onError = Color(0xFFFFFFFF);

  // Utility
  static const Color outline = Color(0xFFD8DDEE);
  static const Color outlineVariant = Color(0xFFBCC7DF);
  static const Color shadow = Color(0x1F1D4ED8);
  static const Color divider = Color(0xFFE3E8F3);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF7C3AED), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFFA78BFA), Color(0xFF60A5FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFFF8FAFF), Color(0xFFF1F5FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
