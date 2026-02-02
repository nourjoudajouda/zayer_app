import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
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
    return EmptyStateScaffold(
      appBarTitle: 'Cart',
      showBackButton: true,
      title: 'Your cart is empty',
      subtitle:
          'Start adding products from global stores by pasting their links.',
      illustration: const _CartIllustration(),
      primaryButtonLabel: 'Add Product via Link',
      primaryButtonIcon: const Icon(Icons.link, size: 20, color: Colors.white),
      onPrimaryPressed: () {
        if (context.mounted) {
          context.push(AppRoutes.pasteLink);
        }
      },
      secondaryButtonLabel: 'Browse Stores',
      secondaryButtonIcon: Icon(
        Icons.explore_outlined,
        size: 20,
        color: AppConfig.primaryColor,
      ),
      onSecondaryPressed: () {
        if (context.mounted) {
          context.go(AppRoutes.markets);
        }
      },
    );
  }
}

/// ZAYER box placeholder: container with "ZAYER" text.
class _CartIllustration extends StatelessWidget {
  const _CartIllustration();

  @override
  Widget build(BuildContext context) {
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
          'ZAYER',
          style: AppTextStyles.headlineMedium(AppConfig.primaryColor.withValues(alpha: 0.9)),
        ),
      ),
    );
  }
}
