import 'dart:io';

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

/// Picked avatar: (file, version). Bump version when setting so UI key changes and image refreshes.
final avatarImageProvider = StateProvider<(File?, int)>((_) => (null, 0));

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
