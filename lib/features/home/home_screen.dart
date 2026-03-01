import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/ui/section_header.dart';
import '../../generated/l10n/app_localizations.dart';
import 'providers/home_providers.dart';
import 'widgets/consolidation_savings_card.dart';
import 'widgets/flash_sale_carousel.dart';
import 'widgets/global_markets_row.dart';
import 'widgets/home_header.dart';
import 'widgets/popular_stores_grid.dart';

/// Home dashboard. Bottom nav is provided by MainShell.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final greeting = ref.watch(homeUserGreetingProvider);
    final banners = ref.watch(promoBannersProvider);
    final markets = ref.watch(homeMarketsProvider);
    final stores = ref.watch(homeStoresProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(promoBannersProvider);
            ref.invalidate(homeMarketsProvider);
            ref.invalidate(homeStoresProvider);
            await Future.delayed(const Duration(milliseconds: 400));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    HomeHeader(
                      greeting: greeting,
                      onProfileTap: () => context.go(AppRoutes.account),
                      onNotificationTap: () => context.push(AppRoutes.notifications),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const SizedBox(height: AppSpacing.lg),
                    if (banners.isNotEmpty) FlashSaleCarousel(banners: banners),
                    const SizedBox(height: AppSpacing.xl),
                    SectionHeader(
                      title: l10n.globalMarkets,
                      trailing: TextButton(
                        onPressed: () => context.go(AppRoutes.markets),
                        style: TextButton.styleFrom(
                          foregroundColor: AppConfig.primaryColor,
                        ),
                        child: Text(l10n.viewAll),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: GlobalMarketsRow(markets: markets),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    const ConsolidationSavingsCard(),
                    const SizedBox(height: AppSpacing.xl),
                    SectionHeader(
                      title: l10n.popularStores,
                      trailing: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: AppConfig.primaryColor,
                        ),
                        child: Text(l10n.viewAll),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PopularStoresGrid(stores: stores),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
