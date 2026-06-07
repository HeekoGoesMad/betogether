import 'package:flutter/material.dart';

/// BeTogether brand color palette
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF31DCF6); // Cyan
  static const Color secondary = Color(0xFFE866B3); // Pink/Magenta

  // Background
  static const Color background = Color(0xFFE8E8F8); // Lavender white
  static const Color surface = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E); // Deep navy
  static const Color textSecondary = Color(0xFF6B6B8A);
  static const Color textHint = Color(0xFFAAAAAA);

  // Utility
  static const Color error = Color(0xFFFF4D6D);
  static const Color success = Color(0xFF4CAF50);
  static const Color divider = Color(0xFFE0E0F0);
  static const Color white = Color(0xFFFFFFFF);

  // Gradient
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1BCCE8), Color(0xFFD44FA0)],
  );

  // Social button colors
  static const Color googleRed = Color(0xFFDB4437);
  static const Color facebookBlue = Color(0xFF1877F2);

  // Card/surface with slight transparency
  static const Color surfaceBlur = Color(0xCCFFFFFF);
}
