import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_locale.dart';

/// App language: EN (default) or AR. Only way to switch to Arabic is the in-app toggle.
final appLocaleProvider = StateProvider<AppLocale>((ref) => AppLocale.en);

/// Legacy string form for config helpers that expect "en" | "ar".
final languageProvider = Provider<String>((ref) {
  return ref.watch(appLocaleProvider).code;
});

/// Locale for MaterialApp. Drives locale + text direction (RTL for AR).
final localeProvider = Provider<Locale>((ref) {
  return Locale(ref.watch(appLocaleProvider).code);
});
