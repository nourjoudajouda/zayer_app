/// Single address. API: GET/POST/PATCH /api/me/addresses.
class Address {
  const Address({
    required this.id,
    required this.addressLine,
    required this.countryId,
    required this.countryName,
    this.cityId,
    this.cityName,
    this.phone,
    this.isDefault = false,
  });

  final String id;
  final String addressLine;
  final String countryId;
  final String countryName;
  final String? cityId;
  final String? cityName;
  final String? phone;
  final bool isDefault;

  Address copyWith({
    String? id,
    String? addressLine,
    String? countryId,
    String? countryName,
    String? cityId,
    String? cityName,
    String? phone,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      addressLine: addressLine ?? this.addressLine,
      countryId: countryId ?? this.countryId,
      countryName: countryName ?? this.countryName,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      phone: phone ?? this.phone,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

/// Country option for dropdown. API: GET /api/countries or from addresses config.
class CountryOption {
  const CountryOption({required this.id, required this.name});
  final String id;
  final String name;
}

/// City option for dropdown. API: GET /api/cities?countryId= or from addresses config.
class CityOption {
  const CityOption({required this.id, required this.name});
  final String id;
  final String name;
}
