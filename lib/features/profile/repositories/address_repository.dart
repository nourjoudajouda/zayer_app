import '../models/address_model.dart';

/// Addresses, countries, cities. Replace with API: GET/POST/PATCH /api/me/addresses, GET /api/countries, GET /api/cities.
class AddressRepository {
  AddressRepository() : _addresses = _mockAddresses;

  static final List<Address> _mockAddresses = [
    const Address(
      id: '1',
      addressLine: '123 Main Street, Apt 4B\nNew York, NY 10001',
      countryId: 'us',
      countryName: 'United States',
      cityId: 'ny',
      cityName: 'New York',
      phone: '+1 555 123 4567',
      isDefault: true,
    ),
  ];

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

  List<Address> _addresses;

  Future<List<CountryOption>> getCountries() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return List.from(_mockCountries);
  }

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

  Future<List<Address>> getAddresses() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return List.from(_addresses);
  }

  Future<void> setDefaultAddress(String addressId) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _addresses = _addresses.map((a) => a.copyWith(isDefault: a.id == addressId)).toList();
  }

  Future<void> saveAddress({
    String? id,
    required String addressLine,
    required String countryId,
    required String countryName,
    String? cityId,
    String? cityName,
    String? phone,
    required bool isDefault,
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
    );
    if (isDefault) {
      _addresses = _addresses.map((a) => a.copyWith(isDefault: false)).toList();
    }
    _addresses = [..._addresses, newAddress];
  }
}
