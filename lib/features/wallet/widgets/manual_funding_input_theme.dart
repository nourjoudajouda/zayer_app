import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';

/// Softer helper / hint styling for manual funding forms (Wire, Zelle submit).
ThemeData manualFundingInputTheme(BuildContext context) {
  final base = Theme.of(context);
  final soft = AppConfig.subtitleColor;
  return base.copyWith(
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      hintStyle: TextStyle(
        color: soft.withValues(alpha: 0.40),
        fontWeight: FontWeight.w400,
      ),
      helperStyle: TextStyle(
        color: soft.withValues(alpha: 0.52),
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
        final t = base.textTheme.bodyLarge ?? const TextStyle();
        if (states.contains(WidgetState.focused)) {
          return t.copyWith(
            color: AppConfig.primaryColor,
            fontWeight: FontWeight.w500,
          );
        }
        return t.copyWith(
          color: soft.withValues(alpha: 0.74),
          fontWeight: FontWeight.w400,
        );
      }),
    ),
  );
}
