import 'package:flutter/material.dart';

/// Premium Luxury Color Palette — Deep Royal Violet & Warm Gold
class AppColors {
  AppColors._();

  // Primary - Deep Royal Violet
  static const Color primary = Color(0xFF5B21B6);
  static const Color primaryDark = Color(0xFF4C1D95);
  static const Color primaryLight = Color(0xFF8B5CF6);
  static const Color primaryLightest = Color(0xFFEDE9FE);

  // Accent - Warm Gold
  static const Color accent = Color(0xFFD4AF37);
  static const Color accentLight = Color(0xFFF5E6B8);

  // Secondary - Emerald Green
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryDark = Color(0xFF059669);

  // Background & Surface
  static const Color background = Color(0xFFF8F7FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF3F0FA);

  // Text
  static const Color text = Color(0xFF1A1235);
  static const Color textSecondary = Color(0xFF64607D);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Feedback Colors
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Borders & Dividers
  static const Color border = Color(0xFFE2DFF0);
  static const Color borderFocus = Color(0xFF5B21B6);
  static const Color divider = Color(0xFFF0EDF8);

  // Input States
  static const Color placeholder = Color(0xFFA09CB5);
  static const Color disabled = Color(0xFFF3F0FA);

  // Overlay
  static const Color overlay = Color(0x991A1235); // 60%
  static const Color overlayLight = Color(0x331A1235); // 20%

  // Gradient
  static const Color gradientStart = Color(0xFF5B21B6);
  static const Color gradientEnd = Color(0xFF7C3AED);

  // Tab Bar
  static const Color tabBarBg = Color(0xFF4C1D95);
  static const Color tabBarActive = Color(0xFFFFFFFF);
  static const Color tabBarInactive = Color(0x8CFFFFFF); // 55%

  // Shadows
  static const Color shadowColor = Color(0xFF1A1235);

  // Gradient shortcut
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
