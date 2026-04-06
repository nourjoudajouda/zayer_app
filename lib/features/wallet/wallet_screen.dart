import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import 'models/wallet_model.dart';
import 'providers/wallet_providers.dart';

/// Main Wallet screen: balance, breakdown, usage, activity with filters.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(walletBalanceProvider);
    final balance =
        balanceAsync.valueOrNull ??
        const WalletBalance(available: 0, pending: 0, promo: 0);
    final balanceLoading = balanceAsync.isLoading;
    final visible = ref.watch(walletBalanceVisibleProvider);
    final transactionsAsync = ref.watch(walletFilteredTransactionsProvider);
    final transactions = transactionsAsync.valueOrNull ?? [];
    final activityFilter = ref.watch(walletActivityFilterProvider);

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Wallet'),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Material(
              color: AppConfig.textColor,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _showWalletHelp(context),
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: Text(
                      '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(walletBalanceProvider);
            ref.invalidate(walletTransactionsProvider);
            await ref.read(walletBalanceProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppConfig.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppConfig.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outlined,
                        size: 18,
                        color: AppConfig.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Use at checkout when enabled',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppConfig.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Currency converted to USD based on real-time rates',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (balanceLoading)
                          SizedBox(
                            width: 120,
                            height: 32,
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppConfig.primaryColor,
                                ),
                              ),
                            ),
                          )
                        else
                          Text(
                            visible ? balance.availableFormatted : '••••••••',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppConfig.textColor,
                                ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          'AVAILABLE BALANCE',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: AppConfig.subtitleColor),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        visible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppConfig.subtitleColor,
                      ),
                      onPressed: () =>
                          ref
                                  .read(walletBalanceVisibleProvider.notifier)
                                  .state =
                              !visible,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () => context.push(AppRoutes.topUpWallet),
                    icon: const Icon(Icons.add, size: 22),
                    label: const Text('Add Funds'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppConfig.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConfig.radiusSmall,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _BalanceBreakdownCard(balance: balance),
                const SizedBox(height: AppSpacing.md),
                _WalletUsageCard(),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Activity',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showActivityFilterSheet(context, ref),
                      child: Text(
                        'Filters',
                        style: TextStyle(
                          color: AppConfig.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ActivityChip(
                        label: 'All',
                        isSelected: activityFilter == WalletActivityType.all,
                        onTap: () =>
                            ref
                                    .read(walletActivityFilterProvider.notifier)
                                    .state =
                                WalletActivityType.all,
                      ),
                      const SizedBox(width: 8),
                      _ActivityChip(
                        label: 'Refunds',
                        isSelected:
                            activityFilter == WalletActivityType.refunds,
                        onTap: () =>
                            ref
                                    .read(walletActivityFilterProvider.notifier)
                                    .state =
                                WalletActivityType.refunds,
                      ),
                      const SizedBox(width: 8),
                      _ActivityChip(
                        label: 'Payments',
                        isSelected:
                            activityFilter == WalletActivityType.payments,
                        onTap: () =>
                            ref
                                    .read(walletActivityFilterProvider.notifier)
                                    .state =
                                WalletActivityType.payments,
                      ),
                      const SizedBox(width: 8),
                      _ActivityChip(
                        label: 'Top-ups',
                        isSelected: activityFilter == WalletActivityType.topUps,
                        onTap: () =>
                            ref
                                    .read(walletActivityFilterProvider.notifier)
                                    .state =
                                WalletActivityType.topUps,
                      ),
                      const SizedBox(width: 8),
                      _ActivityChip(
                        label: 'Admin Credits',
                        isSelected:
                            activityFilter == WalletActivityType.adminCredits,
                        onTap: () =>
                            ref
                                    .read(walletActivityFilterProvider.notifier)
                                    .state =
                                WalletActivityType.adminCredits,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (transactions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    child: Text(
                      'No activity in this category',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppConfig.subtitleColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...transactions.map((t) => _TransactionTile(transaction: t)),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showWalletHelp(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppConfig.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConfig.radiusMedium),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.help_outline,
                    color: AppConfig.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Wallet help',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Whether you can pay with your wallet at checkout depends on your store’s settings. When wallet checkout is enabled, you can choose it on Review & Pay if your balance covers the order, or top up first. Currency is converted to USD at real-time rates.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConfig.subtitleColor,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  void _showActivityFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppConfig.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConfig.radiusMedium),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Filter activity',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                title: const Text('All'),
                onTap: () {
                  ref.read(walletActivityFilterProvider.notifier).state =
                      WalletActivityType.all;
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Refunds'),
                onTap: () {
                  ref.read(walletActivityFilterProvider.notifier).state =
                      WalletActivityType.refunds;
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Payments'),
                onTap: () {
                  ref.read(walletActivityFilterProvider.notifier).state =
                      WalletActivityType.payments;
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Top-ups'),
                onTap: () {
                  ref.read(walletActivityFilterProvider.notifier).state =
                      WalletActivityType.topUps;
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Admin Credits'),
                onTap: () {
                  ref.read(walletActivityFilterProvider.notifier).state =
                      WalletActivityType.adminCredits;
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityChip extends StatelessWidget {
  const _ActivityChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppConfig.primaryColor : AppConfig.cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? null
                : Border.all(color: AppConfig.borderColor),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppConfig.subtitleColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceBreakdownCard extends StatelessWidget {
  const _BalanceBreakdownCard({required this.balance});

  final WalletBalance balance;

  static String _formatAmount(double value) {
    final s = value.toStringAsFixed(0);
    if (s.length <= 3) return s;
    final buf = StringBuffer();
    var i = s.length % 3;
    if (i == 0) i = 3;
    buf.write(s.substring(0, i));
    for (; i < s.length; i += 3) {
      buf.write(',');
      buf.write(s.substring(i, i + 3));
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
        border: Border.all(color: AppConfig.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'BALANCE BREAKDOWN',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppConfig.subtitleColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Material(
                color: AppConfig.borderColor.withValues(alpha: 0.6),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {},
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: Center(
                      child: Text(
                        'i',
                        style: TextStyle(
                          color: AppConfig.subtitleColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _BreakdownRow(
            label: 'Available',
            value: '\$${_formatAmount(balance.available)}',
            valueColor: AppConfig.textColor,
          ),
          const Divider(height: 24),
          _BreakdownRow(
            label: 'Pending',
            value: '\$${_formatAmount(balance.pending)}',
            valueColor: AppConfig.warningOrange,
            dottedUnderline: true,
          ),
          const Divider(height: 24),
          _BreakdownRow(
            label: 'Promo',
            value: '\$${_formatAmount(balance.promo)}',
            valueColor: AppConfig.primaryColor,
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.dottedUnderline = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool dottedUnderline;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppConfig.textColor),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w600,
            decoration: dottedUnderline ? TextDecoration.underline : null,
            decorationColor: dottedUnderline ? valueColor : null,
            decorationStyle: dottedUnderline
                ? TextDecorationStyle.dotted
                : null,
          ),
        ),
      ],
    );
  }
}

class _WalletUsageCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        border: Border.all(color: AppConfig.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppConfig.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppConfig.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Wallet Usage',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '• Payment Priority: Credits and refunds are always used first before other payment methods.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
          ),
          const SizedBox(height: 4),
          Text(
            '• Partial Payments: If your balance is lower than the total, you can pay the remaining with a card.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () => context.push(AppRoutes.privacyPolicy),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View Terms & Conditions',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppConfig.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final icon = transaction.type == WalletActivityType.refunds
        ? Icons.reply
        : transaction.type == WalletActivityType.adminCredits
        ? Icons.admin_panel_settings_outlined
        : transaction.type == WalletActivityType.topUps
        ? Icons.add_circle_outline
        : Icons.shopping_bag_outlined;
    final iconBg = transaction.isCredit
        ? AppConfig.successGreen.withValues(alpha: 0.15)
        : AppConfig.borderColor.withValues(alpha: 0.5);
    final amountColor = transaction.isCredit
        ? AppConfig.successGreen
        : AppConfig.textColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: transaction.isCredit
                  ? AppConfig.successGreen
                  : AppConfig.subtitleColor,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.dateTime,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction.amount,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                transaction.subtitle,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: amountColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
