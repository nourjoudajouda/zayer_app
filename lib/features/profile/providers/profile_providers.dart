import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/address_model.dart';
import '../models/user_profile_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../repositories/address_repository.dart';
import '../repositories/address_repository_impl.dart';
import '../repositories/profile_repository.dart';
import '../repositories/profile_repository_impl.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((_) => ProfileRepositoryImpl());

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  return ref.read(profileRepositoryProvider).getProfile();
});

final complianceStatusProvider = FutureProvider<ComplianceStatus>((ref) async {
  return ref.read(profileRepositoryProvider).getCompliance();
});

/// Picked avatar preview bytes and version. Bump version when setting so UI key changes and image refreshes.
/// Uses Uint8List (not File) to support web where dart:io is unavailable.
final avatarImageProvider = StateProvider<(Uint8List?, int)>((_) => (null, 0));

/// True while avatar is being uploaded to the server.
final avatarUploadingProvider = StateProvider<bool>((_) => false);

// --- Addresses (from backend)
final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return AddressRepositoryImpl(authRepo: ref.watch(authRepositoryProvider));
});

final countriesProvider = FutureProvider<List<CountryOption>>((ref) async {
  return ref.read(addressRepositoryProvider).getCountries();
});

final citiesProvider = FutureProvider.family<List<CityOption>, String>((ref, countryId) async {
  if (countryId.isEmpty) return [];
  return ref.read(addressRepositoryProvider).getCities(countryId);
});

final addressesProvider = FutureProvider<List<Address>>((ref) async {
  return ref.read(addressRepositoryProvider).getAddresses();
});

/// Address id while "Set as default" API is in progress (for loader on Default chip).
final setDefaultAddressLoadingIdProvider = StateProvider<String?>((ref) => null);
