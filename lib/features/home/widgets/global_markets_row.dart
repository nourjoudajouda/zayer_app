import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/home_providers.dart';

/// Horizontal scroll of wide market cards: image left, name + store count right.
/// Fixed height to prevent overflow.
class GlobalMarketsRow extends StatelessWidget {
  const GlobalMarketsRow({super.key, required this.markets});

  final List<MarketItem> markets;

  static const double _height = 88;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: markets.length,
        itemBuilder: (context, i) => _MarketCard(
          market: markets[i],
          onTap: () {
            final code = markets[i].countryCode;
            context.go('${AppRoutes.markets}${code != null ? '?country=$code' : ''}');
          },
        ),
      ),
    );
  }
}

class _MarketCard extends StatelessWidget {
  const _MarketCard({required this.market, required this.onTap});

  final MarketItem market;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: AppConfig.cardColor,
          borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
          border: Border.all(color: AppConfig.borderColor),
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
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppConfig.borderColor,
                          AppConfig.borderColor.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: const Icon(Icons.public, color: AppConfig.subtitleColor, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          market.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppConfig.textColor,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
