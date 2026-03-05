import '../models/address_model.dart';

/// Addresses, countries, cities. API: GET/POST/PATCH /api/me/addresses, GET /api/countries, GET /api/cities.
abstract class AddressRepository {
  Future<List<CountryOption>> getCountries();
  Future<List<CityOption>> getCities(String countryId);
  Future<List<Address>> getAddresses();
  Future<void> setDefaultAddress(String addressId);
  Future<void> saveAddress({
    String? id,
    required String addressLine,
    required String countryId,
    required String countryName,
    String? cityId,
    String? cityName,
    String? phone,
    required bool isDefault,
    String? nickname,
    AddressType addressType = AddressType.home,
    String? areaDistrict,
    String? streetAddress,
    String? buildingVillaSuite,
    bool isVerified = false,
    bool isResidential = true,
    double? lat,
    double? lng,
  });
}

class AddressRepositoryMock implements AddressRepository {
  static final List<Address> _mockAddresses = [
    const Address(
      id: '1',
      addressLine: '123 Burj Khalifa St, Suite 402, Downtown Dubai, UAE',
      countryId: 'ae',
      countryName: 'United Arab Emirates',
      cityId: 'dxb',
      cityName: 'Dubai',
      phone: '+971 50 123 4567',
      isDefault: true,
      nickname: 'Home - Dubai',
      addressType: AddressType.home,
      areaDistrict: 'Downtown Dubai',
      streetAddress: '123 Burj Khalifa St',
      buildingVillaSuite: 'Suite 402',
      isVerified: true,
      isResidential: true,
      linkedToActiveOrder: false,
      isLocked: false,
      lat: 25.0760,
      lng: 55.3093,
    ),
    const Address(
      id: '2',
      addressLine: 'Building 4, Dubai Media City, UAE',
      countryId: 'ae',
      countryName: 'United Arab Emirates',
      cityId: 'dxb',
      cityName: 'Dubai',
      isDefault: false,
      nickname: 'Work - Office',
      addressType: AddressType.office,
      areaDistrict: 'Dubai Media City',
      streetAddress: 'Building 4',
      isVerified: false,
      isResidential: false,
      linkedToActiveOrder: true,
      isLocked: true,
    ),
    const Address(
      id: '3',
      addressLine: 'Plot 12, Jebel Ali Free Zone, UAE',
      countryId: 'ae',
      countryName: 'United Arab Emirates',
      cityId: 'dxb',
      cityName: 'Dubai',
      isDefault: false,
      nickname: 'Warehouse 2',
      addressType: AddressType.other,
      areaDistrict: 'Jebel Ali Free Zone',
      streetAddress: 'Plot 12',
      isVerified: false,
      isResidential: false,
      linkedToActiveOrder: false,
      isLocked: false,
    ),
  ];

  List<Address> _addresses;

  AddressRepositoryMock() : _addresses = List.from(_mockAddresses);

  static const List<CountryOption> _mockCountries = [
    CountryOption(id: 'us', name: 'United States'),
    CountryOption(id: 'ae', name: 'United Arab Emirates'),
    CountryOption(id: 'sa', name: 'Saudi Arabia'),
    CountryOption(id: 'eg', name: 'Egypt'),
    CountryOption(id: 'tr', name: 'Turkey'),
    CountryOption(id: 'gb', name: 'United Kingdom'),
    CountryOption(id: 'de', name: 'Germany'),
    CountryOption(id: 'fr', name: 'France'),
  ];

  static const List<CityOption> _mockCities = [
    CityOption(id: 'ny', name: 'New York'),
    CityOption(id: 'la', name: 'Los Angeles'),
    CityOption(id: 'dxb', name: 'Dubai'),
    CityOption(id: 'auh', name: 'Abu Dhabi'),
    CityOption(id: 'ruh', name: 'Riyadh'),
    CityOption(id: 'jed', name: 'Jeddah'),
    CityOption(id: 'cai', name: 'Cairo'),
    CityOption(id: 'ist', name: 'Istanbul'),
    CityOption(id: 'ank', name: 'Ankara'),
    CityOption(id: 'lon', name: 'London'),
    CityOption(id: 'ber', name: 'Berlin'),
    CityOption(id: 'par', name: 'Paris'),
  ];

  @override
  Future<List<CountryOption>> getCountries() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return List.from(_mockCountries);
  }

  @override
  Future<List<CityOption>> getCities(String countryId) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final byCountry = <String, List<CityOption>>{
      'us': const [CityOption(id: 'ny', name: 'New York'), CityOption(id: 'la', name: 'Los Angeles')],
      'ae': const [CityOption(id: 'dxb', name: 'Dubai'), CityOption(id: 'auh', name: 'Abu Dhabi')],
      'sa': const [CityOption(id: 'ruh', name: 'Riyadh'), CityOption(id: 'jed', name: 'Jeddah')],
      'eg': const [CityOption(id: 'cai', name: 'Cairo')],
      'tr': const [CityOption(id: 'ist', name: 'Istanbul'), CityOption(id: 'ank', name: 'Ankara')],
      'gb': const [CityOption(id: 'lon', name: 'London')],
      'de': const [CityOption(id: 'ber', name: 'Berlin')],
      'fr': const [CityOption(id: 'par', name: 'Paris')],
    };
    return List.from(byCountry[countryId] ?? []);
  }

  @override
  Future<List<Address>> getAddresses() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    // Primary (default) first, then others
    final list = List<Address>.from(_addresses);
    list.sort((a, b) {
      if (a.isDefault) return -1;
      if (b.isDefault) return 1;
      return 0;
    });
    return list;
  }

  @override
  Future<void> setDefaultAddress(String addressId) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _addresses = _addresses.map((a) => a.copyWith(isDefault: a.id == addressId)).toList();
  }

  @override
  Future<void> saveAddress({
    String? id,
    required String addressLine,
    required String countryId,
    required String countryName,
    String? cityId,
    String? cityName,
    String? phone,
    required bool isDefault,
    String? nickname,
    AddressType addressType = AddressType.home,
    String? areaDistrict,
    String? streetAddress,
    String? buildingVillaSuite,
    bool isVerified = false,
    bool isResidential = true,
    double? lat,
    double? lng,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (id != null) {
      final i = _addresses.indexWhere((a) => a.id == id);
      if (i >= 0) {
        _addresses[i] = Address(
          id: id,
          addressLine: addressLine,
          countryId: countryId,
          countryName: countryName,
          cityId: cityId,
          cityName: cityName,
          phone: phone,
          isDefault: isDefault,
          nickname: nickname,
          addressType: addressType,
          areaDistrict: areaDistrict,
          streetAddress: streetAddress,
          buildingVillaSuite: buildingVillaSuite,
          isVerified: isVerified,
          isResidential: isResidential,
          linkedToActiveOrder: _addresses[i].linkedToActiveOrder,
          isLocked: _addresses[i].isLocked,
          lat: lat,
          lng: lng,
        );
        if (isDefault) {
          for (var j = 0; j < _addresses.length; j++) {
            if (j != i) _addresses[j] = _addresses[j].copyWith(isDefault: false);
          }
        }
        return;
      }
    }
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newAddress = Address(
      id: newId,
      addressLine: addressLine,
      countryId: countryId,
      countryName: countryName,
      cityId: cityId,
      cityName: cityName,
      phone: phone,
      isDefault: isDefault,
      nickname: nickname,
      addressType: addressType,
      areaDistrict: areaDistrict,
      streetAddress: streetAddress,
      buildingVillaSuite: buildingVillaSuite,
      isVerified: isVerified,
      isResidential: isResidential,
      linkedToActiveOrder: false,
      isLocked: false,
      lat: lat,
      lng: lng,
    );
    if (isDefault) {
      _addresses = _addresses.map((a) => a.copyWith(isDefault: false)).toList();
    }
    _addresses = [..._addresses, newAddress];
  }
}
