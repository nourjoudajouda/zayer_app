/// Country from GET /api/countries
class CountryItem {
  const CountryItem({
    required this.id,
    required this.name,
    this.flagEmoji = '',
    this.dialCode = '',
  });
  final String id;
  final String name;
  final String flagEmoji;
  final String dialCode;

  factory CountryItem.fromJson(Map<String, dynamic> json) {
    return CountryItem(
      id: (json['id'] ?? json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      flagEmoji: (json['flag_emoji'] ?? '').toString(),
      dialCode: (json['dial_code'] ?? '').toString(),
    );
  }
}

/// City from GET /api/cities?country_id=...
class CityItem {
  const CityItem({required this.id, required this.name});
  final String id;
  final String name;

  factory CityItem.fromJson(Map<String, dynamic> json) {
    return CityItem(
      id: (json['id'] ?? json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
}
