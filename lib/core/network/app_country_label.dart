import '../../features/auth/models/country_city.dart';

/// Label for session "location" on the API (stored as [location_label]).
String? formatAppCountryLabel(CountryItem? country) {
  if (country == null) return null;
  final name = country.name.trim();
  if (name.isEmpty && country.id.isEmpty) return null;
  final buf = StringBuffer();
  if (country.flagEmoji.isNotEmpty) {
    buf.write('${country.flagEmoji} ');
  }
  buf.write(name.isNotEmpty ? name : country.id);
  if (country.id.isNotEmpty && name.isNotEmpty) {
    buf.write(' (${country.id})');
  }
  return buf.toString().trim();
}
