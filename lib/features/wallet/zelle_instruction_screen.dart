import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/config/models/app_bootstrap_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import 'widgets/zelle_payment_instructions_view.dart';

/// Zelle step 1: show where to send (from admin payment settings), then Continue.
class ZelleInstructionScreen extends ConsumerWidget {
  const ZelleInstructionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(bootstrapConfigProvider).valueOrNull;
    final wf = bootstrap?.walletFunding ??
        const WalletFundingConfig(
          zelleReceiverName: '',
          zelleReceiverEmail: '',
          zelleReceiverPhone: '',
          zelleReceiverQrUrl: '',
          zelleInstructionText: '',
          wireInstructions: '',
        );

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Pay with Zelle'),
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Send your payment here first',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ZellePaymentInstructionsView(config: wf),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: FilledButton(
                onPressed: () => context.push(AppRoutes.walletFundingZelleSubmit),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
