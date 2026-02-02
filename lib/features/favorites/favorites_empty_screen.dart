import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/widgets/empty_state_scaffold.dart';

/// Favorites empty state. Route: /favorites.
/// Browse Stores -> /markets or /home.
class FavoritesEmptyScreen extends StatelessWidget {
  const FavoritesEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyStateScaffold(
      appBarTitle: 'Favorites',
      showBackButton: true,
      title: 'No favorites yet',
      subtitle:
          'Save products from any store and we\'ll track prices and stock for you.',
      illustration: _FavoritesIllustration(),
      primaryButtonLabel: 'Browse Stores',
      onPrimaryPressed: () {
        if (context.mounted) {
          context.go(AppRoutes.markets);
        }
      },
    );
  }
}

class _FavoritesIllustration extends StatelessWidget {
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
            color: AppConfig.lightBlueBg.withValues(alpha: 0.8),
            boxShadow: [
              BoxShadow(
                color: AppConfig.borderColor.withValues(alpha: 0.5),
                blurRadius: 24,
                offset: const Offset(0, 8),
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
          child: Icon(
            Icons.favorite_border,
            size: 56,
            color: AppConfig.primaryColor.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
