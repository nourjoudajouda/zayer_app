import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import 'providers/wallet_refund_to_wallet_providers.dart';

/// Refunds from orders/shipments → wallet (operational).
class WalletRefundsToWalletPanel extends ConsumerWidget {
  const WalletRefundsToWalletPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(walletRefundsToWalletProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(walletRefundsToWalletProvider);
        await ref.read(walletRefundsToWalletProvider.future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Refund to wallet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Request a refund from a paid order or shipment. If approved, funds are added to your wallet balance. '
              'This is not a bank transfer.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.subtitleColor,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.walletRefundToWallet),
              icon: const Icon(Icons.currency_exchange),
              label: const Text('Request refund to wallet'),
              style: FilledButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Your requests',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text(
                'Could not load: $e',
                style: TextStyle(color: AppConfig.subtitleColor),
              ),
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
                            '${r.statusLabel} · ${r.sourceLabel}',
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
                                      Text('Source: ${r.sourceLabel}'),
                                      const SizedBox(height: 8),
                                      Text('Amount: \$${r.amount.toStringAsFixed(2)}'),
                                      const SizedBox(height: 8),
                                      Text('Reason:\n${r.reason}'),
                                      if (r.adminNotes != null &&
                                          r.adminNotes!.trim().isNotEmpty) ...[
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
