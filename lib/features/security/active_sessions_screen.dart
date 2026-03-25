import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Session model. From API GET /api/me/sessions.
///
/// **Location display:** Prefer [ipLocation] (GeoIP from server) when set, so the
/// user sees the country derived from the session IP. Backend should set one of
/// `ip_location`, `location_from_ip`, or `geo_ip_location` after GeoIP lookup on
/// `request()->ip()` (or stored ip on the session row).
class SessionInfo {
  const SessionInfo({
    required this.id,
    required this.deviceName,
    required this.location,
    this.ipLocation,
    required this.lastActive,
    required this.clientInfo,
    required this.isCurrent,
  });

  final String id;
  final String deviceName;
  /// Legacy combined line (may mix app country + IP). Shown only if [ipLocation] empty.
  final String location;
  /// GeoIP-based label from server (e.g. "🇵🇸 … · IP: …"). Preferred for UI.
  final String? ipLocation;
  final String lastActive;
  final String clientInfo;
  final bool isCurrent;

  /// What to show under the device name: IP-based geo when API sends it, else [location].
  String get displayLocation {
    final ip = ipLocation?.trim();
    if (ip != null && ip.isNotEmpty) return ip;
    return location;
  }

  static String? _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v is String) {
        final t = v.trim();
        if (t.isNotEmpty) return t;
      }
    }
    return null;
  }

  static SessionInfo fromJson(Map<String, dynamic> json) => SessionInfo(
        id: json['id']?.toString() ?? '',
        deviceName: json['device_name'] as String? ?? '',
        location: json['location'] as String? ?? '',
        ipLocation: _firstString(json, const [
          'ip_location',
          'location_from_ip',
          'geo_ip_location',
        ]),
        lastActive: json['last_active'] as String? ?? '',
        clientInfo: json['client_info'] as String? ?? '',
        isCurrent: json['is_current'] == true,
      );
}

/// Sessions from API: GET /api/me/sessions
final sessionsProvider = FutureProvider<List<SessionInfo>>((ref) async {
  final res = await ApiClient.instance.get<List<dynamic>>('/api/me/sessions');
  final list = res.data;
  if (list == null) return [];
  return list
      .whereType<Map<String, dynamic>>()
      .map(SessionInfo.fromJson)
      .where((s) => s.id.isNotEmpty)
      .toList();
});

/// Active Sessions: this device, other sessions, danger zone. Mock sign out.
class ActiveSessionsScreen extends ConsumerWidget {
  const ActiveSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider);

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Active Sessions'),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Could not load sessions',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(AppConfig.subtitleColor),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () => ref.invalidate(sessionsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (sessions) => _ActiveSessionsContent(sessions: sessions),
      ),
    );
  }
}

class _ActiveSessionsContent extends ConsumerWidget {
  const _ActiveSessionsContent({required this.sessions});

  final List<SessionInfo> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = sessions.where((s) => s.isCurrent).toList();
    final other = sessions.where((s) => !s.isCurrent).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Devices currently signed in to your account',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppConfig.textColor,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your active logins across all platforms and ensure your account security.',
            style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (current.isNotEmpty) ...[
            _SessionCard(
              session: current.first,
              isCurrent: true,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(
            'Other Active Sessions',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppConfig.textColor,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Review other devices where your account is currently logged in.',
            style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...other.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _SessionCard(
                  session: s,
                  isCurrent: false,
                  onSignOut: () => _endSession(context, ref, s),
                ),
              )),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: AppConfig.errorRed),
              const SizedBox(width: 8),
              Text(
                'DANGER ZONE',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppConfig.errorRed,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppConfig.errorRed.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
              border: Border.all(color: AppConfig.errorRed.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'This will immediately sign you out of all devices except for this one. You\'ll need to sign back in on each device.',
                  style: AppTextStyles.bodySmall(AppConfig.textColor),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  onPressed: () => _revokeOtherSessions(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConfig.errorRed,
                    side: BorderSide(color: AppConfig.errorRed),
                  ),
                  child: const Text('Sign out of all other sessions'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Column(
              children: [
                Icon(Icons.shield_outlined, size: 20, color: AppConfig.subtitleColor),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Your security is our priority. Session tokens are managed securely on our servers.',
                  style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {},
            child: Text(
              'Learn more about account security',
              style: AppTextStyles.bodySmall(AppConfig.primaryColor),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

Future<void> _endSession(
  BuildContext context,
  WidgetRef ref,
  SessionInfo s,
) async {
  try {
    await ApiClient.instance.delete<void>(
      '/api/me/sessions/${s.id}',
      options: Options(validateStatus: (code) => code != null && code < 500),
    );
    ref.invalidate(sessionsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signed out from ${s.deviceName}')),
      );
    }
  } on DioException catch (e) {
    final m = e.response?.data is Map
        ? (e.response!.data as Map)['message'] as String?
        : null;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m ?? e.message ?? 'Failed')),
      );
    }
  }
}

Future<void> _revokeOtherSessions(
  BuildContext context,
  WidgetRef ref,
) async {
  try {
    final res = await ApiClient.instance.post<Map<String, dynamic>>(
      '/api/me/sessions/revoke-others',
      options: Options(validateStatus: (c) => c != null && c < 500),
    );
    ref.invalidate(sessionsProvider);
    if (context.mounted) {
      final msg = res.data?['message'] as String? ?? 'Other sessions ended';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  } on DioException catch (e) {
    final m = e.response?.data is Map
        ? (e.response!.data as Map)['message'] as String?
        : null;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m ?? e.message ?? 'Failed')),
      );
    }
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.isCurrent,
    this.onSignOut,
  });

  final SessionInfo session;
  final bool isCurrent;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        border: Border.all(color: AppConfig.borderColor),
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppConfig.borderColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              session.deviceName.contains('iPhone') || session.deviceName.contains('iPad')
                  ? Icons.smartphone
                  : session.deviceName.contains('Mac')
                      ? Icons.laptop_mac
                      : Icons.computer,
              color: AppConfig.primaryColor,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: AppConfig.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'THIS DEVICE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppConfig.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                Text(
                  session.deviceName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppConfig.textColor,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  session.displayLocation,
                  style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                ),
                if (session.clientInfo.isNotEmpty)
                  Text(
                    session.clientInfo,
                    style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                  ),
                if (!isCurrent && onSignOut != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onSignOut,
                    child: const Text('Sign Out'),
                  ),
                ],
              ],
            ),
          ),
          if (isCurrent)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppConfig.successGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
