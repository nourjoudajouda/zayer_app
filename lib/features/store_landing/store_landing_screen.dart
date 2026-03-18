import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../generated/l10n/app_localizations.dart';

/// Store model hydrated from backend config/navigation.
class _StoreModel {
  const _StoreModel({
    required this.storeName,
    required this.storeUrl,
    this.logoUrl,
    this.isVerified = true,
    this.isOfficial = true,
    this.isSecure = true,
    this.categories = const ['Electronics', 'Fashion', 'Home', 'Beauty'],
  });
  final String storeName;
  final String storeUrl;
  final String? logoUrl;
  final bool isVerified;
  final bool isOfficial;
  final bool isSecure;
  final List<String> categories;
}

/// Flag to show/hide Paste Product Link button. Set to false later if needed.
const bool showPasteLinkButton = true;

class StoreLandingScreen extends ConsumerWidget {
  const StoreLandingScreen({
    super.key,
    this.storeId,
    required this.storeName,
    required this.storeUrl,
    this.logoUrl,
    this.categories = const <String>[],
  });

  final String? storeId;
  final String storeName;
  final String storeUrl;
  final String? logoUrl;
  final List<String> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final appName = ref.watch(appDisplayNameProvider);

    // Model built from route/config.
    final store = _StoreModel(
      storeName: storeName,
      storeUrl: storeUrl,
      logoUrl: logoUrl,
      isVerified: true,
      isOfficial: true,
      isSecure: true,
      categories: categories.isNotEmpty
          ? categories
          : const ['Electronics', 'Fashion', 'Home', 'Beauty'],
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(store.storeName),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {},
                customBorder: const CircleBorder(),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: AppConfig.borderColor,
                  child: Icon(Icons.flag, size: 20, color: AppConfig.subtitleColor),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopSection(store: store),
              const SizedBox(height: AppSpacing.lg),
              _InfoCard(appName: appName),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: () {
                    context.push('${AppRoutes.store}?url=${Uri.encodeComponent(store.storeUrl)}');
                  },
                  icon: const Icon(Icons.open_in_new, size: 20),
                  label: Text(l10n.shopOnAmazon.replaceAll('Amazon', store.storeName)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                    ),
                  ),
                ),
              ),
              if (showPasteLinkButton) ...[
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.pasteLink),
                    icon: const Icon(Icons.link, size: 20),
                    label: Text(l10n.pasteProductLink),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppConfig.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              _WhatYouCanShop(categories: store.categories),
              const SizedBox(height: AppSpacing.xl),
              _HowItWorks(l10n: l10n),
              const SizedBox(height: AppSpacing.lg),
              _ConsolidationBenefitsCard(l10n: l10n),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopSection extends StatelessWidget {
  const _TopSection({required this.store});

  final _StoreModel store;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: AppConfig.borderColor,
              borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
            ),
            child: () {
              final resolved = resolveAssetUrl(store.logoUrl, ApiClient.safeBaseUrl);
              if (resolved != null && resolved.isNotEmpty) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                  child: CachedNetworkImage(
                    imageUrl: resolved,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Icon(
                      Icons.store,
                      size: 52,
                      color: AppConfig.subtitleColor,
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.store,
                      size: 52,
                      color: AppConfig.subtitleColor,
                    ),
                  ),
                );
              }
              return const Icon(Icons.store, size: 52, color: AppConfig.subtitleColor);
            }(),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                store.storeName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppConfig.textColor,
                    ),
              ),
              if (store.isVerified) ...[
                const SizedBox(width: 8),
                Icon(Icons.verified, size: 22, color: AppConfig.primaryColor),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (store.isOfficial)
                _PillChip(
                  icon: Icons.check_circle,
                  label: l10n.officialStore,
                  color: AppConfig.successGreen,
                ),
              if (store.isSecure)
                _PillChip(
                  icon: Icons.lock,
                  label: l10n.secure,
                  color: AppConfig.subtitleColor,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.appName});

  final String appName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.lightBlueBg,
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
      ),
      child: Text(
        "You'll shop directly on the official store website. $appName handles shipping and consolidation.",
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppConfig.textColor,
            ),
      ),
    );
  }
}

class _WhatYouCanShop extends StatelessWidget {
  const _WhatYouCanShop({required this.categories});

  final List<String> categories;

  static const _categoryIcons = {
    'Electronics': Icons.devices,
    'Fashion': Icons.checkroom,
    'Home': Icons.home,
    'Beauty': Icons.face,
  };

  IconData _iconFor(String name) =>
      _categoryIcons[name] ?? Icons.category;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHAT YOU CAN SHOP',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppConfig.subtitleColor,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories
              .map(
                (c) => _CategoryChip(
                  icon: _iconFor(c),
                  label: c,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppConfig.borderColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppConfig.subtitleColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConfig.textColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How it Works',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppConfig.textColor,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
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
          child: Column(
            children: [
              _HowItWorksRow(
                step: 1,
                title: l10n.findProducts,
                subtitle: l10n.findProductsDesc,
              ),
              Divider(height: 1, color: AppConfig.borderColor),
              _HowItWorksRow(
                step: 2,
                title: l10n.addToZayerCart,
                subtitle: l10n.addToZayerCartDesc,
              ),
              Divider(height: 1, color: AppConfig.borderColor),
              _HowItWorksRow(
                step: 3,
                title: l10n.globalDelivery,
                subtitle: l10n.globalDeliveryDesc,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HowItWorksRow extends StatelessWidget {
  const _HowItWorksRow({
    required this.step,
    required this.title,
    required this.subtitle,
  });

  final int step;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppConfig.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '$step',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppConfig.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppConfig.textColor,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppConfig.subtitleColor,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsolidationBenefitsCard extends StatelessWidget {
  const _ConsolidationBenefitsCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConfig.primaryColor,
            AppConfig.primaryColor.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConfig.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppConfig.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 20,
            bottom: 20,
            child: Opacity(
              opacity: 0.15,
              child: Icon(Icons.public, size: 80, color: Colors.white),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.inventory_2, size: 28, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.consolidationBenefits,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.saveUpTo70,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Combine multiple orders from different US stores into one package to drastically reduce your international shipping fees.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
