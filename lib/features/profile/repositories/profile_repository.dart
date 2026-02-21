import 'dart:io';

import '../models/user_profile_model.dart';

/// Mock profile repository. Replace with API calls later.
class ProfileRepository {
  UserProfile _profile = const UserProfile(
    displayName: 'Hazem',
    verified: true,
    lastVerifiedAt: 'Jan 15, 2025',
    fullLegalName: 'Hazem Al-Masri',
    dateOfBirth: 'Jan 1, 1990',
    primaryAddress: '123 Main Street, Apt 4B\nNew York, NY 10001',
    primaryAddressCountry: 'United States',
    isDefault: true,
    isAddressLocked: true,
  );

  Future<UserProfile> getProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _profile;
  }

  Future<UserProfile> updateProfile({
    String? fullLegalName,
    String? displayName,
    String? dateOfBirth,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _profile = UserProfile(
      displayName: displayName ?? _profile.displayName,
      verified: _profile.verified,
      lastVerifiedAt: _profile.lastVerifiedAt,
      fullLegalName: fullLegalName ?? _profile.fullLegalName,
      dateOfBirth: dateOfBirth ?? _profile.dateOfBirth,
      primaryAddress: _profile.primaryAddress,
      primaryAddressCountry: _profile.primaryAddressCountry,
      isDefault: _profile.isDefault,
      isAddressLocked: _profile.isAddressLocked,
    );
    return _profile;
  }

  Future<void> uploadAvatar(File file) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    // Mock: real impl would POST to /api/me/avatar and persist URL
  }

  Future<ComplianceStatus> getCompliance() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return const ComplianceStatus(
      actionRequired: true,
      expiryDate: 'Mar 1, 2026',
      description: 'Your government-issued ID is required for international shipping compliance.',
    );
  }
}
