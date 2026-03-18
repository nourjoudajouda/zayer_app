import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import 'providers/markets_providers.dart';
import 'widgets/country_chips_row.dart';
import 'widgets/featured_store_card.dart';

/// Explore Markets screen. Route: /markets.
class MarketsScreen extends ConsumerStatefulWidget {
  const MarketsScreen({super.key, this.initialCountry});

  /// Pre-select country when navigating from Home (e.g. ?country=US).
  final String? initialCountry;

  @override
  ConsumerState<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends ConsumerState<MarketsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialCountry != null) {
        ref.read(selectedCountryCodeProvider.notifier).state =
            widget.initialCountry;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(marketsConfigProvider);
    final stores = ref.watch(filteredStoresProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.public),
          onPressed: () {},
        ),
        title: Column(
          children: [
            Text(
              config.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppConfig.textColor,
                  ),
            ),
            Text(
              config.subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            bootstrapConfigRefresh(ref);
            await ref.read(bootstrapConfigProvider.future);
          },
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    CountryChipsRow(countries: config.countries),
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'FEATURED STORES',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppConfig.subtitleColor,
                                  letterSpacing: 0.8,
                                ),
                          ),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: AppConfig.primaryColor,
                            ),
                            child: const Text('View all  >'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: stores.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Center(
                                child: Text(
                                  'No stores in this market',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppConfig.subtitleColor,
                                      ),
                                ),
                              ),
                            )
                          : Column(
                              children: stores
                                  .map((s) => FeaturedStoreCard(store: s))
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
              Positioned(
                right: AppSpacing.md,
                bottom: AppSpacing.lg,
                child: Material(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(AppConfig.radiusXLarge),
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.2),
                  child: InkWell(
                    onTap: () => context.push(AppRoutes.pasteLink),
                    borderRadius: BorderRadius.circular(AppConfig.radiusXLarge),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.link, color: Colors.white, size: 22),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Paste Link',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
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
