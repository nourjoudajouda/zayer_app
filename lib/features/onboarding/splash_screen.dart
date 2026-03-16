import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_providers.dart';
import '../../core/config/app_config.dart';
import '../../core/fcm/pending_notification_provider.dart';
import '../../core/network/api_config.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/config/models/app_bootstrap_config.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  double _progress = 0;
  bool _hasScheduledNavigation = false;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _runFakeProgress();
  }

  void _runFakeProgress() {
    const steps = 15;
    const stepDuration = Duration(milliseconds: 100);
    for (var i = 1; i <= steps; i++) {
      Future<void>.delayed(stepDuration * i, () {
        if (mounted) setState(() => _progress = i / steps);
      });
    }
  }

  void _navigateAfterDelay(WidgetRef ref, bool onboardingEmpty, bool developmentMode) async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    final pending = ref.read(pendingNotificationTargetProvider);
    if (pending != null) {
      ref.read(pendingNotificationTargetProvider.notifier).clear();
      final hasToken = await ref.read(tokenStoreProvider).hasToken();
      if (!mounted) return;
      if (hasToken) {
        context.go(pending.route);
      } else {
        context.go(onboardingEmpty ? AppRoutes.register : AppRoutes.onboarding);
      }
      return;
    }
    final hasToken = await ref.read(tokenStoreProvider).hasToken();
    if (!mounted) return;
    if (hasToken) {
      context.go(AppRoutes.home);
      return;
    }
    if (developmentMode) {
      context.go(AppRoutes.underDevelopment);
    } else {
      context.go(onboardingEmpty ? AppRoutes.register : AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(bootstrapConfigProvider);
    final lang = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      body: Directionality(
        textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: configAsync.when(
            loading: () => _buildLoadingSkeleton(),
            error: (err, _) => _buildError(context, err),
            data: (config) {
              if (!_hasScheduledNavigation) {
                _hasScheduledNavigation = true;
                _navigateAfterDelay(
                  ref,
                  config.onboarding.isEmpty,
                  config.developmentMode,
                );
              }
              return _buildContent(config.splash, lang);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppConfig.borderColor,
              borderRadius: BorderRadius.circular(AppConfig.radiusLarge),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            height: 28,
            width: 120,
            decoration: BoxDecoration(
              color: AppConfig.borderColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 20,
            width: 200,
            decoration: BoxDecoration(
              color: AppConfig.borderColor.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Spacer(),
          LinearProgressIndicator(
            value: null,
            backgroundColor: AppConfig.borderColor,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppConfig.primaryColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Future<void> _retryBootstrap() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      bootstrapConfigRefresh(ref);
      await ref.read(bootstrapConfigProvider.future);
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  Widget _buildError(BuildContext context, Object error) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 64,
            color: AppConfig.subtitleColor,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Something went wrong',
            style: AppTextStyles.headlineSmall(AppConfig.textColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Please check your connection and try again.',
            style: AppTextStyles.bodyMedium(AppConfig.subtitleColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: _isRetrying ? null : _retryBootstrap,
            icon: _isRetrying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh),
            label: Text(_isRetrying ? 'Retrying...' : 'Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(SplashConfig splash, String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          const Spacer(),
          _buildLogo(splash.logoUrl),
          const SizedBox(height: AppSpacing.lg),
          Text(
            splash.title(lang),
            style: AppTextStyles.headlineLarge(AppConfig.textColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            splash.subtitle(lang),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge(AppConfig.subtitleColor),
          ),
          const Spacer(),
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: AppConfig.borderColor,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppConfig.primaryColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            splash.progressText(lang) ?? '${(_progress * 100).round()}%',
            style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildLogo(String logoUrl) {
    final resolved = resolveAssetUrl(logoUrl);
    if (resolved == null || resolved.isEmpty) {
      return _buildLogoPlaceholder();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConfig.radiusLarge),
      child: CachedNetworkImage(
        imageUrl: resolved,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildLogoPlaceholder(),
        errorWidget: (context, url, error) => _buildLogoPlaceholder(),
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppConfig.primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppConfig.radiusLarge),
      ),
      child: const Icon(
        Icons.shopping_bag_outlined,
        size: 40,
        color: AppConfig.primaryColor,
      ),
    );
  }
}
