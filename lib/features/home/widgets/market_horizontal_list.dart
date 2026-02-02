import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/home_providers.dart';

/// Horizontal scroll list of market cards. Fixed height to prevent overflow.
class MarketHorizontalList extends StatelessWidget {
  const MarketHorizontalList({super.key, required this.markets});

  final List<MarketItem> markets;

  static const double _height = 120;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: markets.length,
        itemBuilder: (context, i) => _MarketCard(market: markets[i]),
      ),
    );
  }
}

class _MarketCard extends StatelessWidget {
  const _MarketCard({required this.market});

  final MarketItem market;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: AppConfig.cardColor,
          borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppConfig.borderColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.public, color: AppConfig.subtitleColor),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    market.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppConfig.textColor,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    market.storeCount,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppConfig.subtitleColor,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
