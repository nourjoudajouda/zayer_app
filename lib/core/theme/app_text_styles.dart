import 'package:flutter/material.dart';

import '../config/app_config.dart';

/// App text styles using [AppConfig] colors.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle headlineLarge([Color color = AppConfig.textColor]) =>
      TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: color,
      );

  static TextStyle headlineMedium([Color color = AppConfig.textColor]) =>
      TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: color,
      );

  static TextStyle headlineSmall([Color color = AppConfig.textColor]) =>
      TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle titleLarge([Color color = AppConfig.textColor]) => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle titleMedium([Color color = AppConfig.textColor]) =>
      TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle bodyLarge([Color color = AppConfig.textColor]) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: color,
      );

  static TextStyle bodyMedium([Color color = AppConfig.textColor]) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: color,
      );

  static TextStyle bodySmall([Color color = AppConfig.subtitleColor]) =>
      TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: color,
      );

  static TextStyle label([Color color = AppConfig.subtitleColor]) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      );
}
