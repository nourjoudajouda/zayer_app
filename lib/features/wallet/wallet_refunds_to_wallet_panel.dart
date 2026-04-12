import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import 'models/wallet_refund_to_wallet_model.dart';
import 'providers/wallet_refund_to_wallet_providers.dart';
import 'widgets/wallet_financial_detail_rows.dart';
import 'widgets/wallet_financial_status.dart';

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
                    for (final r in list) _RefundToWalletTile(refund: r),
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

class _RefundToWalletTile extends StatelessWidget {
  const _RefundToWalletTile({required this.refund});

  final WalletRefundToWalletModel refund;

  @override
  Widget build(BuildContext context) {
    final p = WalletRefundStatusPresentation.forStatus(refund.status);
    final created = formatWalletDateLine(refund.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 4,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          leading: CircleAvatar(
            backgroundColor: p.color.withValues(alpha: 0.18),
            child: Icon(p.icon, color: p.color, size: 22),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  '\$${refund.amount.toStringAsFixed(2)} ${refund.currency}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              WalletRefundStatusChip(status: refund.status),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  refund.sourceLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConfig.textColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (created != null)
                  Text(
                    created,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppConfig.subtitleColor,
                        ),
                  ),
                if (p.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    p.subtitle!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: p.color,
                        ),
                  ),
                ],
              ],
            ),
          ),
          children: [
            WalletDetailRow(
              label: 'Source',
              value:
                  '${refund.sourceType == 'shipment' ? 'Shipment' : 'Order'} #${refund.sourceId}',
            ),
            WalletDetailRow(
              label: 'Amount',
              value: '\$${refund.amount.toStringAsFixed(2)} ${refund.currency}',
            ),
            WalletDetailRow(label: 'Reason', value: refund.reason),
            WalletDetailRow(
              label: 'Submitted',
              value: formatWalletDateLine(refund.createdAt) ?? '—',
            ),
            WalletDetailRow(
              label: 'Reviewed',
              value: formatWalletDateLine(refund.reviewedAt) ?? '—',
            ),
            if (refund.adminNotes != null && refund.adminNotes!.trim().isNotEmpty)
              WalletDetailRow(
                label: 'Admin note',
                value: refund.adminNotes!.trim(),
              ),
          ],
        ),
      ),
    );
  }
}
