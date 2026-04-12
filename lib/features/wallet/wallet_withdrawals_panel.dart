import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import 'providers/wallet_withdrawal_providers.dart';

/// Withdraw wallet balance to bank (IBAN).
class WalletWithdrawalsPanel extends ConsumerWidget {
  const WalletWithdrawalsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(walletWithdrawalsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(walletWithdrawalsProvider);
        await ref.read(walletWithdrawalsProvider.future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Withdraw to bank',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppConfig.warningOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                border: Border.all(color: AppConfig.borderColor),
              ),
              child: Text(
                'Withdrawals are reviewed manually. After your transfer is completed, receiving funds at your bank '
                'may take up to 30 days. A service fee may apply (see summary before you submit).',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConfig.textColor,
                      height: 1.4,
                    ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.walletWithdrawToBank),
              icon: const Icon(Icons.account_balance_outlined),
              label: const Text('Withdraw to bank'),
              style: FilledButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Your withdrawals',
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
                    'No withdrawals yet.',
                    style: TextStyle(color: AppConfig.subtitleColor),
                  );
                }
                return Column(
                  children: [
                    for (final w in list)
                      Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ListTile(
                          title: Text(
                            '\$${w.amount.toStringAsFixed(2)} → net \$${w.netAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${w.statusLabel} · ${w.bankName}, ${w.country}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            showDialog<void>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('Withdrawal #${w.id}'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Status: ${w.statusLabel}'),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Gross: \$${w.amount.toStringAsFixed(2)} · Fee: \$${w.feeAmount.toStringAsFixed(2)} · Net: \$${w.netAmount.toStringAsFixed(2)}',
                                      ),
                                      const SizedBox(height: 8),
                                      Text('IBAN: ${w.iban}'),
                                      const SizedBox(height: 8),
                                      Text('Bank: ${w.bankName}'),
                                      const SizedBox(height: 8),
                                      Text('Country: ${w.country}'),
                                      if (w.note != null && w.note!.trim().isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text('Note: ${w.note}'),
                                      ],
                                      if (w.transferProofUrl != null &&
                                          w.transferProofUrl!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text('Proof: ${w.transferProofUrl}'),
                                      ],
                                      if (w.adminNotes != null &&
                                          w.adminNotes!.trim().isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text('Admin: ${w.adminNotes}'),
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
