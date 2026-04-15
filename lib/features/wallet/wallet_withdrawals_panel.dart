import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import 'providers/wallet_withdrawal_providers.dart';
import 'widgets/transfer_proof_download.dart';
import 'widgets/transfer_proof_viewer.dart';
import 'widgets/wallet_financial_detail_rows.dart';
import 'widgets/wallet_financial_status.dart';
import 'models/wallet_withdrawal_model.dart';
import 'wallet_feedback.dart';

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
                    for (final w in list) _WithdrawalTile(withdrawal: w),
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

class _WithdrawalTile extends StatefulWidget {
  const _WithdrawalTile({required this.withdrawal});

  final WalletWithdrawalModel withdrawal;

  @override
  State<_WithdrawalTile> createState() => _WithdrawalTileState();
}

class _WithdrawalTileState extends State<_WithdrawalTile> {
  bool _downloadingProof = false;

  @override
  Widget build(BuildContext context) {
    final withdrawal = widget.withdrawal;
    final p = WalletWithdrawalStatusPresentation.forStatus(withdrawal.status);
    final created = formatWalletDateLine(withdrawal.createdAt);
    final proofUrl = withdrawal.transferProofUrl?.trim();
    final hasProof = proofUrl != null && proofUrl.isNotEmpty;

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
                  '\$${withdrawal.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              WalletWithdrawalStatusChip(status: withdrawal.status),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${withdrawal.bankName} · ${withdrawal.country}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConfig.textColor,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'IBAN ${maskIbanForDisplay(withdrawal.iban)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppConfig.subtitleColor,
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
                          height: 1.25,
                        ),
                  ),
                ],
              ],
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Net to bank \$${withdrawal.netAmount.toStringAsFixed(2)} '
                '(fee ${withdrawal.feePercent.toStringAsFixed(2)}% · '
                '\$${withdrawal.feeAmount.toStringAsFixed(2)})',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppConfig.primaryColor,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            WalletDetailRow(
              label: 'Requested',
              value: '\$${withdrawal.amount.toStringAsFixed(2)}',
            ),
            WalletDetailRow(
              label: 'Fee %',
              value: '${withdrawal.feePercent.toStringAsFixed(2)}%',
            ),
            WalletDetailRow(
              label: 'Fee amount',
              value: '\$${withdrawal.feeAmount.toStringAsFixed(2)}',
            ),
            WalletDetailRow(
              label: 'Net amount',
              value: '\$${withdrawal.netAmount.toStringAsFixed(2)}',
            ),
            WalletDetailRow(label: 'Bank', value: withdrawal.bankName),
            WalletDetailRow(label: 'Country', value: withdrawal.country),
            WalletDetailRow(
              label: 'IBAN',
              value: withdrawal.iban,
            ),
            if (withdrawal.note != null && withdrawal.note!.trim().isNotEmpty)
              WalletDetailRow(label: 'Your note', value: withdrawal.note!.trim()),
            WalletDetailRow(
              label: 'Submitted',
              value: formatWalletDateLine(withdrawal.createdAt) ?? '—',
            ),
            WalletDetailRow(
              label: 'Reviewed',
              value: formatWalletDateLine(withdrawal.reviewedAt) ?? '—',
            ),
            WalletDetailRow(
              label: 'Transferred',
              value: formatWalletDateLine(withdrawal.transferredAt) ?? '—',
            ),
            if (withdrawal.adminNotes != null &&
                withdrawal.adminNotes!.trim().isNotEmpty)
              WalletDetailRow(
                label: 'Admin note',
                value: withdrawal.adminNotes!.trim(),
              ),
            if (hasProof) ...[
              const SizedBox(height: 8),
              Text(
                'Transfer proof',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppConfig.subtitleColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _downloadingProof
                        ? null
                        : () => viewTransferProof(context, proofUrl!),
                    icon: const Icon(Icons.visibility_outlined, size: 20),
                    label: const Text('View proof'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _downloadingProof
                        ? null
                        : () async {
                            setState(() => _downloadingProof = true);
                            try {
                              await downloadAndOpenTransferProof(
                                context,
                                proofUrl!,
                                withdrawalId: withdrawal.id,
                              );
                            } catch (e) {
                              if (context.mounted) {
                                await walletShowError(
                                  context,
                                  title: 'Download',
                                  message: 'Download failed: ${e.toString()}',
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _downloadingProof = false);
                              }
                            }
                          },
                    icon: _downloadingProof
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download, size: 20),
                    label: Text(_downloadingProof ? 'Downloading…' : 'Download proof'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _downloadingProof
                        ? null
                        : () => openTransferProofExternally(proofUrl!),
                    icon: const Icon(Icons.open_in_new, size: 20),
                    label: const Text('Open externally'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _downloadingProof
                        ? null
                        : () => copyTransferProofLink(context, proofUrl!),
                    icon: const Icon(Icons.link, size: 20),
                    label: const Text('Copy link'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
