import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Fetches from API when available; returns empty list otherwise so we don't show fake data.
final _loginActivityProvider = FutureProvider<List<LoginActivityItem>>((ref) async {
  try {
    final res = await ApiClient.instance.get<List<dynamic>>('/api/me/login-history');
    final list = res.data;
    if (list != null && list.isNotEmpty) {
      return list
          .whereType<Map<String, dynamic>>()
          .map((e) => LoginActivityItem.fromJson(e))
          .whereType<LoginActivityItem>()
          .toList();
    }
  } catch (_) {}
  return [];
});

/// Recent Activity: list of locations/devices where login was performed.
class RecentActivityScreen extends ConsumerWidget {
  const RecentActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(_loginActivityProvider);

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
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Recent activity will appear here when available.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(AppConfig.subtitleColor),
            ),
          ),
        ),
        data: (items) => items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Recent activity will appear here when available.',
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
                              item.timestamp,
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
