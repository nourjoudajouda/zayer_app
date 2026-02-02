import 'package:flutter/material.dart';

/// Centralized app configuration. Change these values to update theme globally.
class AppConfig {
  AppConfig._();

  // Colors
  static const Color primaryColor = Color(0xFF1E66F5);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF0B1220);
  static const Color subtitleColor = Color(0xFF6B7280);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color lightBlueBg = Color(0xFFEFF6FF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFDC2626);

  // Radius (used for rounded corners)
  static const double radiusSmall = 12;
  static const double radiusMedium = 16;
  static const double radiusLarge = 20;
  static const double radiusXLarge = 28;
}
