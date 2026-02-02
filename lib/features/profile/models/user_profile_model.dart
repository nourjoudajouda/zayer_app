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
