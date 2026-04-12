import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import 'providers/wallet_refund_providers.dart';

/// Third tab: refund request history + CTA to submit.
class WalletRefundRequestsPanel extends ConsumerWidget {
  const WalletRefundRequestsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(walletRefundRequestsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(walletRefundRequestsProvider);
        await ref.read(walletRefundRequestsProvider.future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppConfig.warningOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                border: Border.all(color: AppConfig.borderColor),
              ),
              child: Text(
                'Bank refunds are processed manually after review. After approval and transfer, '
                'receiving the funds may take up to 30 days depending on your bank.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConfig.textColor,
                      height: 1.4,
                    ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.walletRequestRefund),
              icon: const Icon(Icons.request_quote_outlined),
              label: const Text('Request refund'),
              style: FilledButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Your requests',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Could not load: $e', style: TextStyle(color: AppConfig.subtitleColor)),
              data: (list) {
                if (list.isEmpty) {
                  return Text(
                    'No refund requests yet.',
                    style: TextStyle(color: AppConfig.subtitleColor),
                  );
                }
                return Column(
                  children: [
                    for (final r in list)
                      Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ListTile(
                          title: Text(
                            '\$${r.amount.toStringAsFixed(2)} ${r.currency}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${r.statusLabel} · ${r.bankName}, ${r.country}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            showDialog<void>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('Request #${r.id}'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Status: ${r.statusLabel}'),
                                      const SizedBox(height: 8),
                                      Text('Amount: \$${r.amount.toStringAsFixed(2)}'),
                                      const SizedBox(height: 8),
                                      Text('IBAN: ${r.iban}'),
                                      const SizedBox(height: 8),
                                      Text('Bank: ${r.bankName}'),
                                      const SizedBox(height: 8),
                                      Text('Country: ${r.country}'),
                                      const SizedBox(height: 8),
                                      Text('Reason:\n${r.reason}'),
                                      if (r.adminNotes != null && r.adminNotes!.trim().isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text('Admin: ${r.adminNotes}'),
                                      ],
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
