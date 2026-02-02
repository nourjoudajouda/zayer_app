/// App language. Default is [en]; [ar] only when user taps the language toggle.
enum AppLocale {
  en,
  ar,
}

extension AppLocaleX on AppLocale {
  String get code => name;

  bool get isRtl => this == AppLocale.ar;
}

/// Picks the correct localized string. If Arabic is requested but empty, falls back to English.
String localizedString({
  required String en,
  required String ar,
  required AppLocale locale,
}) {
  if (locale == AppLocale.ar && ar.trim().isNotEmpty) return ar;
  return en.trim().isNotEmpty ? en : ar;
}

/// Same for optional strings (e.g. progress_text).
String? localizedStringOptional({
  required String? en,
  required String? ar,
  required AppLocale locale,
}) {
  if (locale == AppLocale.ar && ar != null && ar.trim().isNotEmpty) return ar;
  return en != null && en.trim().isNotEmpty ? en : ar;
}
