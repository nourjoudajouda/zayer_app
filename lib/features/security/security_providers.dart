import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';

const _kBiometricsPrefKey = 'security_biometrics_enabled';

/// Server-driven summary for Security & Access (GET /api/me/security).
class SecurityOverview {
  const SecurityOverview({
    required this.twoFactorEnabled,
    required this.activeSessionsCount,
    required this.recentActivityPreview,
    required this.changePasswordHint,
  });

  factory SecurityOverview.fromJson(Map<String, dynamic> j) {
    return SecurityOverview(
      twoFactorEnabled: j['two_factor_enabled'] == true,
      activeSessionsCount: (j['active_sessions_count'] as num?)?.toInt() ?? 0,
      recentActivityPreview: (j['recent_activity_preview'] as String?) ?? '',
      changePasswordHint: (j['change_password_hint'] as String?) ?? '',
    );
  }

  final bool twoFactorEnabled;
  final int activeSessionsCount;
  final String recentActivityPreview;
  final String changePasswordHint;
}

final securityOverviewProvider =
    FutureProvider.autoDispose<SecurityOverview>((ref) async {
  final res = await ApiClient.instance.get<Map<String, dynamic>>(
    '/api/me/security',
  );
  final data = res.data;
  if (data == null) {
    throw StateError('Empty security response');
  }
  return SecurityOverview.fromJson(data);
});

Future<bool> getBiometricsEnabledPreference() async {
  final p = await SharedPreferences.getInstance();
  return p.getBool(_kBiometricsPrefKey) ?? false;
}

Future<void> setBiometricsEnabledPreference(bool value) async {
  final p = await SharedPreferences.getInstance();
  await p.setBool(_kBiometricsPrefKey, value);
}
