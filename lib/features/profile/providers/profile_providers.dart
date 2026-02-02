import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile_model.dart';
import '../repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((_) => ProfileRepository());

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  return ref.read(profileRepositoryProvider).getProfile();
});

final complianceStatusProvider = FutureProvider<ComplianceStatus>((ref) async {
  return ref.read(profileRepositoryProvider).getCompliance();
});

/// Picked avatar image file. TODO: Upload to POST /api/me/avatar and persist URL.
final avatarImageProvider = StateProvider<File?>((_) => null);
