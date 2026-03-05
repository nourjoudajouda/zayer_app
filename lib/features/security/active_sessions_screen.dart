import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Session model. From API GET /api/me/sessions.
class SessionInfo {
  const SessionInfo({
    required this.id,
    required this.deviceName,
    required this.location,
    required this.lastActive,
    required this.clientInfo,
    required this.isCurrent,
  });

  final String id;
  final String deviceName;
  final String location;
  final String lastActive;
  final String clientInfo;
  final bool isCurrent;

  static SessionInfo fromJson(Map<String, dynamic> json) => SessionInfo(
        id: json['id']?.toString() ?? '',
        deviceName: json['device_name'] as String? ?? '',
        location: json['location'] as String? ?? '',
        lastActive: json['last_active'] as String? ?? '',
        clientInfo: json['client_info'] as String? ?? '',
        isCurrent: json['is_current'] == true,
      );
}

/// Sessions from API: GET /api/me/sessions
final sessionsProvider = FutureProvider<List<SessionInfo>>((ref) async {
  try {
    final res = await ApiClient.instance.get<List<dynamic>>('/api/me/sessions');
    final list = res.data;
    if (list == null) return [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(SessionInfo.fromJson)
        .where((s) => s.id.isNotEmpty)
        .toList();
  } catch (_) {}
  return [];
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
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sessions) => _ActiveSessionsContent(sessions: sessions),
      ),
    );
  }
}

class _ActiveSessionsContent extends StatelessWidget {
  const _ActiveSessionsContent({required this.sessions});

  final List<SessionInfo> sessions;

  @override
  Widget build(BuildContext context) {
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
              onSecure: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Device secured')),
                );
              },
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
                  onSignOut: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Signed out from ${s.deviceName}')),
                    );
                  },
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Signed out of all other sessions')),
                    );
                  },
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 20, color: AppConfig.subtitleColor),
              const SizedBox(width: 8),
              Text(
                'Your security is our priority. Zayer uses end-to-end encryption for session management.',
                style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                textAlign: TextAlign.center,
              ),
            ],
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

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.isCurrent,
    this.onSecure,
    this.onSignOut,
  });

  final SessionInfo session;
  final bool isCurrent;
  final VoidCallback? onSecure;
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
                  session.location,
                  style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                ),
                if (session.clientInfo.isNotEmpty)
                  Text(
                    session.clientInfo,
                    style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                  ),
                if (isCurrent && onSecure != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onSecure,
                    icon: const Icon(Icons.shield_outlined, size: 18),
                    label: const Text('Secure Device'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppConfig.primaryColor,
                    ),
                  ),
                ],
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
