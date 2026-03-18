import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/empty_state_scaffold.dart';

/// Cart empty state. Route: /cart (tab in shell).
/// Primary: Add Product via Link -> /paste-link.
/// Secondary: Browse Stores -> /markets or /home.
class CartEmptyScreen extends StatelessWidget {
  const CartEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateScaffold(
      appBarTitle: 'Cart',
      showBackButton: true,
      title: 'Your cart is empty',
      subtitle:
          'Start adding products from global stores by pasting their links.',
      illustration: _CartIllustration(),
      primaryButtonLabel: 'Add Product via Link',
      primaryButtonIcon: Icon(Icons.link, size: 20, color: Colors.white),
      // Buttons are wired by the parent that owns navigation context.
    );
  }
}

/// Empty cart content (no Scaffold). Use inside an existing Scaffold to avoid nested scaffolds.
class CartEmptyContent extends StatelessWidget {
  const CartEmptyContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _CartIllustration(),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: AppTextStyles.headlineSmall(AppConfig.textColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding products from global stores by pasting their links.',
            style: AppTextStyles.bodyLarge(AppConfig.subtitleColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                if (context.mounted) context.push(AppRoutes.pasteLink);
              },
              icon: const Icon(Icons.link, size: 20, color: Colors.white),
              label: const Text('Add Product via Link'),
              style: FilledButton.styleFrom(backgroundColor: AppConfig.primaryColor),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                if (context.mounted) context.go(AppRoutes.markets);
              },
              icon: Icon(Icons.explore_outlined, size: 20, color: AppConfig.primaryColor),
              label: const Text('Browse Stores'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConfig.primaryColor,
                side: const BorderSide(color: AppConfig.primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// App name box placeholder (uses backend bootstrap app_name).
class _CartIllustration extends ConsumerWidget {
  const _CartIllustration();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appName = ref.watch(appDisplayNameProvider);
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: AppConfig.lightBlueBg.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppConfig.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppConfig.borderColor.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          appName,
          style: AppTextStyles.headlineMedium(AppConfig.primaryColor.withValues(alpha: 0.9)),
        ),
      ),
    );
  }
}
