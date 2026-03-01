/// Address type for display and form.
enum AddressType {
  home,
  office,
  other,
}

extension AddressTypeX on AddressType {
  String get displayLabel {
    switch (this) {
      case AddressType.home:
        return 'Home';
      case AddressType.office:
        return 'Office';
      case AddressType.other:
        return 'Other';
    }
  }
}

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
    this.nickname,
    this.addressType = AddressType.home,
    this.areaDistrict,
    this.streetAddress,
    this.buildingVillaSuite,
    this.isVerified = false,
    this.isResidential = true,
    this.linkedToActiveOrder = false,
    this.isLocked = false,
    this.lat,
    this.lng,
  });

  final String id;
  final String addressLine;
  final String countryId;
  final String countryName;
  final String? cityId;
  final String? cityName;
  final String? phone;
  final bool isDefault;

  /// e.g. "Home - Dubai", "Work - Office", "Warehouse 2"
  final String? nickname;
  final AddressType addressType;
  final String? areaDistrict;
  final String? streetAddress;
  final String? buildingVillaSuite;
  final bool isVerified;
  final bool isResidential;
  final bool linkedToActiveOrder;
  final bool isLocked;
  final double? lat;
  final double? lng;

  /// Display title: nickname if set, else fallback from type + city.
  String get displayTitle {
    if (nickname != null && nickname!.isNotEmpty) return nickname!;
    final city = cityName ?? '';
    if (city.isEmpty) return addressType.displayLabel;
    return '${addressType.displayLabel} - $city';
  }

  Address copyWith({
    String? id,
    String? addressLine,
    String? countryId,
    String? countryName,
    String? cityId,
    String? cityName,
    String? phone,
    bool? isDefault,
    String? nickname,
    AddressType? addressType,
    String? areaDistrict,
    String? streetAddress,
    String? buildingVillaSuite,
    bool? isVerified,
    bool? isResidential,
    bool? linkedToActiveOrder,
    bool? isLocked,
    double? lat,
    double? lng,
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
      nickname: nickname ?? this.nickname,
      addressType: addressType ?? this.addressType,
      areaDistrict: areaDistrict ?? this.areaDistrict,
      streetAddress: streetAddress ?? this.streetAddress,
      buildingVillaSuite: buildingVillaSuite ?? this.buildingVillaSuite,
      isVerified: isVerified ?? this.isVerified,
      isResidential: isResidential ?? this.isResidential,
      linkedToActiveOrder: linkedToActiveOrder ?? this.linkedToActiveOrder,
      isLocked: isLocked ?? this.isLocked,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
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
