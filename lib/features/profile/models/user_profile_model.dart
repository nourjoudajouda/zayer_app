/// User profile model. Replace with API response (GET /api/me) later.
class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.verified,
    this.lastVerifiedAt,
    required this.fullLegalName,
    this.dateOfBirth,
    required this.primaryAddress,
    this.primaryAddressCountry,
    this.isDefault = true,
    this.isAddressLocked = false,
    this.avatarUrl,
  });
  final String displayName;
  final bool verified;
  final String? lastVerifiedAt;
  final String fullLegalName;
  final String? dateOfBirth;
  final String primaryAddress;
  final String? primaryAddressCountry;
  final bool isDefault;
  final bool isAddressLocked;
  final String? avatarUrl;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      displayName: (json['display_name'] ?? json['name'] ?? '').toString(),
      verified: json['verified'] == true,
      lastVerifiedAt: json['last_verified_at'] as String?,
      fullLegalName: (json['full_legal_name'] ?? json['full_name'] ?? '').toString(),
      dateOfBirth: json['date_of_birth'] as String?,
      primaryAddress: (json['primary_address'] ?? '').toString(),
      primaryAddressCountry: json['primary_address_country'] as String?,
      isDefault: json['is_default'] != false,
      isAddressLocked: json['is_address_locked'] == true,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

/// KYC/Identity compliance status. Replace with API (GET /api/me/compliance) later.
class ComplianceStatus {
  const ComplianceStatus({
    required this.actionRequired,
    this.expiryDate,
    this.description,
  });
  final bool actionRequired;
  final String? expiryDate;
  final String? description;
}
