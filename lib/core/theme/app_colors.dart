import 'package:flutter/material.dart';

import '../config/app_config.dart';

/// App color palette. All values come from [AppConfig] for easy theming.
class AppColors {
  AppColors._();

  static Color get primary => AppConfig.primaryColor;
  static Color get background => AppConfig.backgroundColor;
  static Color get text => AppConfig.textColor;
  static Color get subtitle => AppConfig.subtitleColor;
  static Color get card => AppConfig.cardColor;
  static Color get border => AppConfig.borderColor;
}
