import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Single login event. API: GET /api/me/login-history when supported.
class LoginActivityItem {
  const LoginActivityItem({
    required this.id,
    required this.location,
    required this.device,
    required this.timestamp,
    this.ipAddress,
  });

  final String id;
  final String location;
  final String device;
  final String timestamp;
  final String? ipAddress;

  static LoginActivityItem? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    final id = (j['id'] ?? '').toString();
    if (id.isEmpty) return null;
    return LoginActivityItem(
      id: id,
      location: (j['location'] ?? j['city'] ?? '—').toString(),
      device: (j['device'] ?? j['device_name'] ?? '—').toString(),
      timestamp: (j['timestamp'] ?? j['last_active'] ?? '').toString(),
      ipAddress: j['ip_address'] as String?,
    );
  }
}

/// GET /api/me/login-history (Sanctum sessions as activity).
final loginActivityProvider = FutureProvider<List<LoginActivityItem>>((ref) async {
  final res = await ApiClient.instance.get<List<dynamic>>('/api/me/login-history');
  final list = res.data;
  if (list == null || list.isEmpty) return [];
  return list
      .whereType<Map<String, dynamic>>()
      .map((e) => LoginActivityItem.fromJson(e))
      .whereType<LoginActivityItem>()
      .toList();
});

/// Recent Activity: list of locations/devices where login was performed.
class RecentActivityScreen extends ConsumerWidget {
  const RecentActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(loginActivityProvider);

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Recent Activity'),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
      ),
      body: activityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Could not load activity.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium(AppConfig.subtitleColor),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () => ref.invalidate(loginActivityProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) => items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'No login activity yet. It will list devices that used your account.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium(AppConfig.subtitleColor),
                  ),
                ),
              )
            : _RecentActivityContent(items: items),
      ),
    );
  }
}

String _formatActivityTime(String raw) {
  final d = DateTime.tryParse(raw);
  if (d == null) return raw;
  return DateFormat.yMMMd().add_jm().format(d.toLocal());
}

class _RecentActivityContent extends StatelessWidget {
  const _RecentActivityContent({required this.items});

  final List<LoginActivityItem> items;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Locations where you signed in',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppConfig.textColor,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Review recent login activity. If you see something unfamiliar, change your password and sign out of other sessions.',
            style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
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
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppConfig.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.location_on_outlined,
                          color: AppConfig.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.location,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppConfig.textColor,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.device,
                              style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatActivityTime(item.timestamp),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppConfig.subtitleColor,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
