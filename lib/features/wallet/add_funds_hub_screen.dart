import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import 'stripe_wallet_helpers.dart';
import 'top_up_wallet_screen.dart';

/// Entry for Add Funds: card (saved + browser), wire transfer, Zelle.
class AddFundsHubScreen extends ConsumerStatefulWidget {
  const AddFundsHubScreen({super.key, this.initialAmount});

  final double? initialAmount;

  @override
  ConsumerState<AddFundsHubScreen> createState() => _AddFundsHubScreenState();
}

class _AddFundsHubScreenState extends ConsumerState<AddFundsHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cfg = ref.read(bootstrapConfigProvider).valueOrNull;
      applyStripePublishableKey(cfg);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(bootstrapConfigProvider).valueOrNull;
    final stripeOn = stripeEnabledInBootstrap(bootstrap);

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Add funds'),
        centerTitle: true,
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Choose how to add money to your wallet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConfig.subtitleColor,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push(AppRoutes.walletFundingHistory),
              icon: const Icon(Icons.history, size: 20),
              label: const Text('Wire & Zelle request history'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            icon: Icons.credit_card,
            title: 'Debit or credit card',
            subtitle: stripeOn
                ? 'Save a card with Stripe, verify a small charge, then top up from saved cards. Or pay in your browser.'
                : 'Stripe is not enabled for this app build.',
            onTap: stripeOn
                ? () => context.push(
                      AppRoutes.paymentMethods,
                      extra: widget.initialAmount,
                    )
                : null,
            trailing: stripeOn
                ? TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (ctx) => TopUpWalletScreen(
                            initialAmount: widget.initialAmount,
                          ),
                        ),
                      );
                    },
                    child: const Text('Browser checkout'),
                  )
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          _SectionCard(
            icon: Icons.account_balance,
            title: 'Wire transfer',
            subtitle: 'Submit details and optional proof; our team approves your deposit.',
            onTap: () => context.push(AppRoutes.walletFundingWire),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SectionCard(
            icon: Icons.phone_iphone_outlined,
            title: 'Zelle',
            subtitle:
                'See payment instructions and QR, then submit details for team review.',
            onTap: () => context.push(AppRoutes.walletFundingZelle),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppConfig.cardColor,
      borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppConfig.primaryColor, size: 28),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                  if (onTap != null)
                    Icon(Icons.chevron_right, color: AppConfig.subtitleColor),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConfig.subtitleColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
