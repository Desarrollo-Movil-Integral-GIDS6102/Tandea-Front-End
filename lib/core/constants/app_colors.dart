import 'package:flutter/material.dart';

/// Paleta de colores oficial del proyecto Tandea.
class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFFCCFBF1);
  static const Color primaryVariant = Color(0xFF115E59);

  // Text colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textDisabled = Color(0xFF9CA3AF);
  static const Color hint = Color(0xFF9CA3AF);

  // Neutral / layout colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Status colors
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFD97706);
  static const Color info = Color(0xFF2563EB);
  static const Color success = Color(0xFF16A34A);

  // Aliases de compatibilidad para pantallas existentes
  static const Color backgroundLight = background;
  static const Color surfaceLight = surface;
  static const Color textPrimaryLight = textPrimary;
  static const Color textSecondaryLight = textSecondary;
  static const Color secondary = Color(0xFFF59E0B);
  static const Color accent = primary;
}
