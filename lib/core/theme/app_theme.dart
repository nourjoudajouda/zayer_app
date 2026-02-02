import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../config/models/app_bootstrap_config.dart';
import 'app_colors.dart';

/// Zayer app theme — Material 3. Default or from remote [ThemeConfig].
class AppTheme {
  AppTheme._();

  /// Default theme (Zayer blue) used while config is loading.
  static ThemeData get light => _build(
        primary: AppConfig.primaryColor,
        background: AppConfig.backgroundColor,
        text: AppConfig.textColor,
      );

  /// Theme from remote config. Fallback primary #1E66F5 if config missing.
  static ThemeData fromThemeConfig(ThemeConfig theme) => fromConfig(theme);

  /// Alias for theme from bootstrap config.
  static ThemeData fromConfig(ThemeConfig theme) => _build(
        primary: theme.primary,
        background: theme.background,
        text: theme.text,
      );

  static ThemeData _build({
    required Color primary,
    required Color background,
    required Color text,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        brightness: Brightness.light,
        surface: background,
      ),
      scaffoldBackgroundColor: background,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
          borderSide: const BorderSide(color: AppConfig.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
          borderSide: BorderSide(
            color: primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
