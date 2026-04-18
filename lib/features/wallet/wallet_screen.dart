import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import 'models/wallet_model.dart';
import 'providers/wallet_providers.dart';
import 'wallet_refunds_to_wallet_panel.dart';
import 'wallet_withdrawals_panel.dart';

/// Main Wallet screen: Overview, Transactions, Refunds to wallet, Withdrawals to bank.
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppConfig.primaryColor,
          unselectedLabelColor: AppConfig.subtitleColor,
          indicatorColor: AppConfig.primaryColor,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Transactions'),
            Tab(text: 'Refunds'),
            Tab(text: 'Withdraw'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildActivityTab(),
            const WalletRefundsToWalletPanel(),
            const WalletWithdrawalsPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final balanceAsync = ref.watch(walletBalanceProvider);
    final balance =
        balanceAsync.valueOrNull ??
        const WalletBalance(available: 0, pending: 0, promo: 0);
    final balanceLoading = balanceAsync.isLoading;
    final visible = ref.watch(walletBalanceVisibleProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(walletBalanceProvider);
        ref.invalidate(walletTransactionsProvider);
        ref.invalidate(walletStripeTopUpsProvider);
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
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
                      ref.read(walletBalanceVisibleProvider.notifier).state =
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
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () => context.push(AppRoutes.walletFundingHistory),
                child: const Text('Wire & Zelle request history'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _BalanceBreakdownCard(balance: balance),
            const SizedBox(height: AppSpacing.md),
            const _WalletStripeTopUpsPanel(),
            const SizedBox(height: AppSpacing.md),
            _WalletUsageCard(),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    final transactionsAsync = ref.watch(walletFilteredTransactionsProvider);
    final transactions = transactionsAsync.valueOrNull ?? [];
    final activityFilter = ref.watch(walletActivityFilterProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(walletBalanceProvider);
        ref.invalidate(walletTransactionsProvider);
        ref.invalidate(walletStripeTopUpsProvider);
        await ref.read(walletTransactionsProvider.future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transactions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                TextButton(
                  onPressed: () => _showActivityFilterSheet(context),
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
                        ref.read(walletActivityFilterProvider.notifier).state =
                            WalletActivityType.all,
                  ),
                  const SizedBox(width: 8),
                  _ActivityChip(
                    label: 'Refund→wallet',
                    isSelected: activityFilter ==
                        WalletActivityType.refundToWallet,
                    onTap: () =>
                        ref.read(walletActivityFilterProvider.notifier).state =
                            WalletActivityType.refundToWallet,
                  ),
                  const SizedBox(width: 8),
                  _ActivityChip(
                    label: 'Withdraw',
                    isSelected: activityFilter ==
                        WalletActivityType.withdrawToBank,
                    onTap: () =>
                        ref.read(walletActivityFilterProvider.notifier).state =
                            WalletActivityType.withdrawToBank,
                  ),
                  const SizedBox(width: 8),
                  _ActivityChip(
                    label: 'Payments',
                    isSelected:
                        activityFilter == WalletActivityType.payments,
                    onTap: () =>
                        ref.read(walletActivityFilterProvider.notifier).state =
                            WalletActivityType.payments,
                  ),
                  const SizedBox(width: 8),
                  _ActivityChip(
                    label: 'Top-ups',
                    isSelected: activityFilter == WalletActivityType.topUps,
                    onTap: () =>
                        ref.read(walletActivityFilterProvider.notifier).state =
                            WalletActivityType.topUps,
                  ),
                  const SizedBox(width: 8),
                  _ActivityChip(
                    label: 'Admin Credits',
                    isSelected:
                        activityFilter == WalletActivityType.adminCredits,
                    onTap: () =>
                        ref.read(walletActivityFilterProvider.notifier).state =
                            WalletActivityType.adminCredits,
                  ),
                  const SizedBox(width: 8),
                  _ActivityChip(
                    label: 'Funding',
                    isSelected:
                        activityFilter == WalletActivityType.fundingCredits,
                    onTap: () =>
                        ref.read(walletActivityFilterProvider.notifier).state =
                            WalletActivityType.fundingCredits,
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

  void _showActivityFilterSheet(BuildContext context) {
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
                title: const Text('Refund to wallet'),
                onTap: () {
                  ref.read(walletActivityFilterProvider.notifier).state =
                      WalletActivityType.refundToWallet;
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Withdraw to bank'),
                onTap: () {
                  ref.read(walletActivityFilterProvider.notifier).state =
                      WalletActivityType.withdrawToBank;
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
              ListTile(
                title: const Text('Funding (cards / wire / Zelle)'),
                onTap: () {
                  ref.read(walletActivityFilterProvider.notifier).state =
                      WalletActivityType.fundingCredits;
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

  static final NumberFormat _money = NumberFormat.currency(symbol: r'$');

  static bool _meaningful(double v) => v.abs() >= 0.005;

  static void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How your balance works'),
        content: const SingleChildScrollView(
          child: Text(
            'Available — Money you can use for checkout and fees right now.\n\n'
            'Pending — Total amount of Wire and Zelle funding requests you have submitted that are still '
            'waiting for admin approval. This is not spendable until the request is approved and credited.\n\n'
            'Promo — Promotional wallet credits. They may only apply to eligible purchases.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showPromo = _meaningful(balance.promo);

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
                  onTap: () => _showHelp(context),
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
            tooltip:
                'Money you can use for orders and fees right now.',
            value: _money.format(balance.available),
            valueColor: AppConfig.textColor,
          ),
          const Divider(height: 24),
          _BreakdownRow(
            label: 'Pending',
            tooltip:
                'Sum of your Wire and Zelle funding requests that are still awaiting admin review. '
                'Not usable for purchases until approved.',
            value: _money.format(balance.pending),
            valueColor: AppConfig.warningOrange,
            dottedUnderline: true,
          ),
          if (showPromo) ...[
            const Divider(height: 24),
            _BreakdownRow(
              label: 'Promo',
              tooltip:
                  'Promotional wallet credits from Zayer. Usage may be limited to eligible purchases.',
              value: _money.format(balance.promo),
              valueColor: AppConfig.primaryColor,
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              'Pending is only manual funding (Wire/Zelle) awaiting approval — not spendable yet.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.subtitleColor,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card / Checkout Stripe top-ups (pending vs paid) from GET /api/wallet/stripe-top-ups.
class _WalletStripeTopUpsPanel extends ConsumerWidget {
  const _WalletStripeTopUpsPanel();

  static String _statusLabel(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'paid':
        return 'Completed';
      case 'processing':
      case 'pending':
        return 'Processing';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return s ?? '—';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(walletStripeTopUpsProvider);
    return async.when(
      data: (rows) {
        if (rows.isEmpty) return const SizedBox.shrink();
        final recent = rows.take(6).toList();
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppConfig.cardColor,
            borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
            border: Border.all(color: AppConfig.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'RECENT CARD TOP-UPS (STRIPE)',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppConfig.subtitleColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
              ),
              const SizedBox(height: 10),
              ...recent.map((r) {
                final amt = (r['amount'] as num?)?.toDouble() ?? 0;
                final st = r['status']?.toString();
                final method = r['method']?.toString() == 'saved_card'
                    ? 'Saved card'
                    : 'Checkout';
                final refStr = r['reference']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\$${amt.toStringAsFixed(2)} · $method',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            if (refStr.isNotEmpty)
                              Text(
                                refStr,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppConfig.subtitleColor,
                                    ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppConfig.lightBlueBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusLabel(st),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppConfig.textColor,
                              ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.tooltip,
    this.dottedUnderline = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final String? tooltip;
  final bool dottedUnderline;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppConfig.textColor,
                      ),
                ),
              ),
              if (tooltip != null && tooltip!.isNotEmpty) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: tooltip!,
                  triggerMode: TooltipTriggerMode.tap,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.info_outline,
                      size: 17,
                      color: AppConfig.subtitleColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          textAlign: TextAlign.right,
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
    final icon = _iconForTransaction(transaction);
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
                if (_flowLabel(transaction.flow) != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _flowLabel(transaction.flow)!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppConfig.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
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
                _amountSubtitle(transaction),
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

  static IconData _iconForTransaction(WalletTransaction t) {
    switch (t.flow) {
      case WalletTransactionFlow.shipmentPayment:
        return Icons.local_shipping_outlined;
      case WalletTransactionFlow.purchaseAssistantPayment:
        return Icons.handshake_outlined;
      case WalletTransactionFlow.orderPayment:
        return Icons.shopping_bag_outlined;
      case WalletTransactionFlow.walletTopup:
        return Icons.add_circle_outline;
      case WalletTransactionFlow.walletRefund:
        return Icons.savings_outlined;
      case WalletTransactionFlow.withdrawal:
        return Icons.outbound_outlined;
      case WalletTransactionFlow.adminAdjustment:
        return Icons.admin_panel_settings_outlined;
      case WalletTransactionFlow.cardVerification:
        return Icons.credit_card_outlined;
      case WalletTransactionFlow.other:
        break;
    }
    if (t.type == WalletActivityType.refundToWallet) {
      return Icons.savings_outlined;
    }
    if (t.type == WalletActivityType.withdrawToBank) {
      return Icons.outbound_outlined;
    }
    if (t.type == WalletActivityType.refunds) {
      return Icons.reply;
    }
    if (t.type == WalletActivityType.adminCredits) {
      return Icons.admin_panel_settings_outlined;
    }
    if (t.type == WalletActivityType.fundingCredits) {
      return Icons.payments_outlined;
    }
    if (t.type == WalletActivityType.topUps) {
      return Icons.add_circle_outline;
    }
    return Icons.account_balance_wallet_outlined;
  }

  static String? _flowLabel(WalletTransactionFlow flow) {
    switch (flow) {
      case WalletTransactionFlow.shipmentPayment:
        return 'Shipment payment';
      case WalletTransactionFlow.purchaseAssistantPayment:
        return 'Purchase Assistant payment';
      case WalletTransactionFlow.orderPayment:
        return 'Order payment';
      case WalletTransactionFlow.walletTopup:
        return 'Wallet top-up';
      case WalletTransactionFlow.walletRefund:
        return 'Refund';
      case WalletTransactionFlow.withdrawal:
        return 'Withdrawal';
      case WalletTransactionFlow.adminAdjustment:
        return 'Admin';
      case WalletTransactionFlow.cardVerification:
        return 'Card verification';
      case WalletTransactionFlow.other:
        return null;
    }
  }

  static String _amountSubtitle(WalletTransaction t) {
    if (t.flow == WalletTransactionFlow.shipmentPayment ||
        t.flow == WalletTransactionFlow.purchaseAssistantPayment ||
        t.flow == WalletTransactionFlow.orderPayment) {
      return t.isCredit ? 'Credit' : 'Debit';
    }
    return t.subtitle;
  }
}
