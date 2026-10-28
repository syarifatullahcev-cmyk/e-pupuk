import 'package:flutter/material.dart';

class AppTheme {
  // Core Brand Colors as requested
  static const Color primaryGreen = Color(0xFF078A61);
  static const Color darkGreen = Color(0xFF075C45);
  static const Color lightGreen = Color(0xFFE8F6EF);
  static const Color background = Color(0xFFF5F8F6);

  // Surface & Borders
  static const Color cardBg = Colors.white;
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderSubtle = Color(0xFFF1F5F9);

  // Typography Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Status & Badges
  static const Color warningOrange = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color infoBlue = Color(0xFF2563EB);
  static const Color infoBg = Color(0xFFEFF6FF);
  static const Color infoBorder = Color(0xFFBFDBFE);

  static const Color dangerRed = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFEE2E2);

  static const Color successGreen = Color(0xFF078A61);
  static const Color successBg = Color(0xFFE8F6EF);

  // Common Card Shadow
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
}
