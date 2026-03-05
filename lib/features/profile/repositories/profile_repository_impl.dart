import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../models/user_profile_model.dart';
import 'profile_repository.dart';

/// API implementation for profile: GET/PATCH /api/me, avatar, compliance.
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.instance;
  final Dio _dio;

  @override
  Future<UserProfile> getProfile() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/me');
    final data = res.data;
    if (data != null) {
      return UserProfile.fromJson(data);
    }
    throw StateError('Profile response empty');
  }

  @override
  Future<UserProfile> updateProfile({
    String? fullLegalName,
    String? displayName,
    String? dateOfBirth,
  }) async {
    final body = <String, dynamic>{};
    if (fullLegalName != null) body['full_legal_name'] = fullLegalName;
    if (displayName != null) body['display_name'] = displayName;
    if (dateOfBirth != null) body['date_of_birth'] = dateOfBirth;
    await _dio.patch('/api/me', data: body);
    return getProfile();
  }

  @override
  Future<void> uploadAvatar(File file) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(file.path),
    });
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/me/avatar',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(seconds: 30),
      ),
    );
    // Avatar URL updated on server; call ref.invalidate(userProfileProvider) to refetch
  }

  @override
  Future<ComplianceStatus> getCompliance() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/me/compliance');
    final data = res.data;
    if (data != null) {
      return ComplianceStatus(
        actionRequired: data['action_required'] == true,
        expiryDate: data['expiry_date'] as String?,
        description: data['description'] as String?,
      );
    }
    return const ComplianceStatus(actionRequired: false);
  }
}
