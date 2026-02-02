import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/widgets/empty_state_scaffold.dart';

/// Orders empty state. Route: /orders (tab in shell).
/// Start Shopping -> /markets or /home.
class OrdersEmptyScreen extends StatelessWidget {
  const OrdersEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateScaffold(
      appBarTitle: 'Orders',
      showBackButton: false,
      appBarActions: [
        IconButton(
          icon: Icon(
            Icons.help_outline,
            color: AppConfig.subtitleColor,
          ),
          onPressed: () {},
        ),
      ],
      title: 'You don\'t have any orders yet.',
      subtitle:
          'Explore global markets and start shopping from international stores.',
      illustration: const _OrdersIllustration(),
      primaryButtonLabel: 'Start Shopping',
      onPrimaryPressed: () {
        if (context.mounted) {
          context.go(AppRoutes.markets);
        }
      },
    );
  }
}

class _OrdersIllustration extends StatelessWidget {
  const _OrdersIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppConfig.lightBlueBg.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppConfig.borderColor.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.local_shipping_outlined,
        size: 80,
        color: AppConfig.primaryColor.withValues(alpha: 0.7),
      ),
    );
  }
}
