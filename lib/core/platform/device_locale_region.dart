import 'dart:ui' as ui;

/// ISO 3166-1 alpha-2 region from the device locale (system language/region).
/// Does not use GPS — no location permission. Used for session `app_country` when
/// the user has not chosen a country from the API list yet.
String? deviceLocaleCountryCode() {
  final locale = ui.PlatformDispatcher.instance.locale;
  final cc = locale.countryCode;
  if (cc != null && cc.isNotEmpty) return cc.toUpperCase();
  // e.g. en-US, ar-JO from toLanguageTag()
  final tag = locale.toLanguageTag();
  final parts = tag.split(RegExp(r'[-_]'));
  if (parts.length >= 2) {
    final last = parts.last.trim();
    if (last.length == 2) return last.toUpperCase();
  }
  return null;
}

/// Human-readable label for [app_country] when the picker label is missing.
String? deviceRegionLabelForSession() {
  final code = deviceLocaleCountryCode();
  if (code == null || code.isEmpty) return null;
  return '📍 $code';
}
