import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'account_activity_provider.dart';

IconData _iconForAction(String t) {
  switch (t) {
    case 'login':
    case 'login_new_device':
      return Icons.login_rounded;
    case 'request_created':
    case 'request_deleted':
      return Icons.shopping_bag_outlined;
    case 'payment_started':
    case 'payment_completed':
      return Icons.payments_outlined;
    case 'order_created':
    case 'order_paid':
      return Icons.receipt_long_outlined;
    case 'shipment_created':
    case 'shipment_shipped':
    case 'shipment_delivered':
      return Icons.local_shipping_outlined;
    case 'delivery_confirmed_by_user':
    case 'rating_submitted':
      return Icons.rate_review_outlined;
    case 'wallet_topup':
    case 'wallet_payment':
      return Icons.account_balance_wallet_outlined;
    case 'refund_received':
      return Icons.undo_rounded;
    default:
      return Icons.notifications_active_outlined;
  }
}

String _formatTime(String raw) {
  final d = DateTime.tryParse(raw);
  if (d == null) return raw;
  return DateFormat.yMMMd().add_jm().format(d.toLocal());
}

/// Full list: GET /api/me/activities
class RecentActivityScreen extends ConsumerWidget {
  const RecentActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(accountActivitiesFullProvider);

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
                  onPressed: () => ref.invalidate(accountActivitiesFullProvider),
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
                    'No activity yet. Sign-ins, orders, and wallet actions will appear here.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium(AppConfig.subtitleColor),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final item = items[i];
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
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppConfig.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _iconForAction(item.actionType),
                            color: AppConfig.primaryColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppConfig.textColor,
                                    ),
                              ),
                              if (item.description != null &&
                                  item.description!.trim().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.description!,
                                  style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(item.createdAtIso),
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
                  );
                },
              ),
      ),
    );
  }
}
