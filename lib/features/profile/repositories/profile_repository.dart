import 'dart:typed_data';

import '../models/user_profile_model.dart';

/// Profile repository. API: GET/PATCH /api/me, POST /api/me/avatar, GET /api/me/compliance.
abstract class ProfileRepository {
  Future<UserProfile> getProfile();
  Future<UserProfile> updateProfile({
    String? fullLegalName,
    String? displayName,
    String? dateOfBirth,
  });
  Future<void> uploadAvatar(Uint8List bytes, String filename);
  Future<ComplianceStatus> getCompliance();
}
