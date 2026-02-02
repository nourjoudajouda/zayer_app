import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/widgets/empty_state_scaffold.dart';

/// Notifications empty state. Route: /notifications.
/// Track My Orders -> /orders.
class NotificationsEmptyScreen extends StatelessWidget {
  const NotificationsEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateScaffold(
      appBarTitle: 'Notifications',
      showBackButton: true,
      appBarActions: [
        TextButton(
          onPressed: null,
          child: Text(
            'Clear All',
            style: TextStyle(
              color: AppConfig.subtitleColor.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ),
      ],
      title: 'You\'re all caught up 🎉',
      subtitle:
          'We\'ll notify you about your orders, shipments, payments, and support updates.',
      illustration: const _NotificationsIllustration(),
      primaryButtonLabel: 'Track My Orders',
      onPrimaryPressed: () {
        if (context.mounted) {
          context.go(AppRoutes.orders);
        }
      },
    );
  }
}

class _NotificationsIllustration extends StatelessWidget {
  const _NotificationsIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppConfig.lightBlueBg,
                AppConfig.lightBlueBg.withValues(alpha: 0.5),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppConfig.borderColor.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
        ),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppConfig.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: AppConfig.borderColor.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Icon(
                  Icons.notifications_none,
                  size: 56,
                  color: AppConfig.primaryColor.withValues(alpha: 0.8),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppConfig.successGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
