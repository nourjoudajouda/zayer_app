import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Single login event. API: GET /api/me/login-history.
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
}

final _loginActivityProvider = FutureProvider<List<LoginActivityItem>>((ref) async {
  await Future<void>.delayed(const Duration(milliseconds: 80));
  return const [
    LoginActivityItem(
      id: '1',
      location: 'London, UK',
      device: 'iPhone 15',
      timestamp: 'Today, 10:24 AM',
    ),
    LoginActivityItem(
      id: '2',
      location: 'Dubai, UAE',
      device: 'Safari on macOS',
      timestamp: 'Yesterday, 2:30 PM',
    ),
    LoginActivityItem(
      id: '3',
      location: 'Riyadh, Saudi Arabia',
      device: 'Zayer App v2.4',
      timestamp: 'Dec 12, 9:15 AM',
    ),
    LoginActivityItem(
      id: '4',
      location: 'London, UK',
      device: 'Chrome on Windows',
      timestamp: 'Dec 10, 4:00 PM',
    ),
  ];
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
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) => _RecentActivityContent(items: items),
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
