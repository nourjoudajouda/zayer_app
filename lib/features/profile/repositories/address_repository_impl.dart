import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../auth/repositories/auth_repository.dart';
import '../models/address_model.dart';
import 'address_repository.dart';

/// API implementation for addresses: GET/POST/PATCH /api/me/addresses, set default.
class AddressRepositoryImpl implements AddressRepository {
  AddressRepositoryImpl({
    Dio? dio,
    required AuthRepository authRepo,
  })  : _dio = dio ?? ApiClient.instance,
        _authRepo = authRepo;

  final Dio _dio;
  final AuthRepository _authRepo;

  @override
  Future<List<CountryOption>> getCountries() async {
    final list = await _authRepo.getCountries();
    return list
        .map((c) => CountryOption(
              id: c.id,
              name: c.name,
              flagEmoji: c.flagEmoji,
              dialCode: c.dialCode,
            ))
        .toList();
  }

  @override
  Future<List<CityOption>> getCities(String countryId) async {
    if (countryId.isEmpty) return [];
    final list = await _authRepo.getCities(countryId: countryId);
    return list.map((c) => CityOption(id: c.id, name: c.name)).toList();
  }

  @override
  Future<List<Address>> getAddresses() async {
    final res = await _dio.get<List<dynamic>>('/api/me/addresses');
    final list = res.data;
    if (list == null) return [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(_addressFromJson)
        .toList();
  }

  @override
  Future<void> setDefaultAddress(String addressId) async {
    await _dio.post('/api/me/addresses/$addressId/default');
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
    final body = {
      'country_id': countryId,
      'country_name': countryName,
      'city_id': cityId,
      'city_name': cityName,
      'address_line': addressLine,
      'street_address': streetAddress,
      'area_district': areaDistrict,
      'building_villa_suite': buildingVillaSuite,
      'phone': phone,
      'is_default': isDefault,
      'nickname': nickname,
      'address_type': _addressTypeToString(addressType),
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };
    if (id != null) {
      await _dio.patch('/api/me/addresses/$id', data: body);
    } else {
      await _dio.post('/api/me/addresses', data: body);
    }
  }
}

Address _addressFromJson(Map<String, dynamic> j) {
  final at = j['address_type'] as String?;
  AddressType type = AddressType.home;
  if (at == 'office') type = AddressType.office;
  if (at == 'other') type = AddressType.other;
  return Address(
    id: (j['id'] ?? '').toString(),
    addressLine: (j['address_line'] ?? '').toString(),
    countryId: (j['country_id'] ?? '').toString(),
    countryName: (j['country_name'] ?? '').toString(),
    cityId: _asStringOrNull(j['city_id']),
    cityName: _asStringOrNull(j['city_name']),
    phone: _asStringOrNull(j['phone']),
    isDefault: j['is_default'] == true,
    nickname: _asStringOrNull(j['nickname']),
    addressType: type,
    areaDistrict: _asStringOrNull(j['area_district']),
    streetAddress: _asStringOrNull(j['street_address']),
    buildingVillaSuite: _asStringOrNull(j['building_villa_suite']),
    isVerified: j['is_verified'] == true,
    isResidential: j['is_residential'] != false,
    linkedToActiveOrder: j['linked_to_active_order'] == true,
    isLocked: j['is_locked'] == true,
    lat: (j['lat'] as num?)?.toDouble(),
    lng: (j['lng'] as num?)?.toDouble(),
  );
}

String? _asStringOrNull(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  if (s.trim().isEmpty) return null;
  return s;
}

String _addressTypeToString(AddressType t) {
  switch (t) {
    case AddressType.home:
      return 'home';
    case AddressType.office:
      return 'office';
    case AddressType.other:
      return 'other';
  }
}
