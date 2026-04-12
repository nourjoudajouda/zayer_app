import 'package:intl/intl.dart';

final _dateTimeFmt = DateFormat.yMMMd().add_jm();

/// Formats API ISO-8601 strings for display in local time.
String formatWalletDateTime(String? iso) {
  if (iso == null || iso.trim().isEmpty) {
    return '—';
  }
  try {
    final d = DateTime.parse(iso.trim());
    return _dateTimeFmt.format(d.toLocal());
  } catch (_) {
    return iso;
  }
}

/// Masks IBAN for display (keeps country prefix hint + last 4).
String maskIbanForDisplay(String iban) {
  final c = iban.replaceAll(' ', '').trim();
  if (c.length <= 4) {
    return '••••';
  }
  final prefix = c.length >= 4 ? c.substring(0, 2) : c;
  final last = c.substring(c.length - 4);
  return '$prefix••••••$last';
}

/// Heuristic: treat URL as image if path suggests common image extensions.
bool transferProofUrlLooksLikeImage(String url) {
  final path = url.split('?').first.toLowerCase();
  return path.endsWith('.jpg') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.png') ||
      path.endsWith('.webp') ||
      path.endsWith('.gif');
}

bool transferProofUrlLooksLikePdf(String url) {
  return url.split('?').first.toLowerCase().endsWith('.pdf');
}
