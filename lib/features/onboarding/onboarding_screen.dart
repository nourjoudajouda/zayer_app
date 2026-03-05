import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/routing/app_router.dart';
import '../../core/config/models/app_bootstrap_config.dart';
import '../../core/localization/app_locale.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../generated/l10n/app_localizations.dart';
import 'widgets/onboarding_page.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _hasRedirectedEmpty = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onContinue(int pageCount) {
    if (_currentPage < pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      if (ref.read(developmentModeProvider)) {
        context.go(AppRoutes.underDevelopment);
      } else {
        context.go(AppRoutes.register);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(appLocaleProvider);
    final lang = ref.watch(languageProvider);
    final configAsync = ref.watch(bootstrapConfigProvider);

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      body: Directionality(
        textDirection: locale.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: SafeArea(
          child: configAsync.when(
            loading: () => _buildLoading(),
            error: (err, _) => _buildError(context),
            data: (config) {
              final pages = config.onboarding;
              if (pages.isEmpty && !_hasRedirectedEmpty) {
                _hasRedirectedEmpty = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) context.go(AppRoutes.register);
                });
                return const SizedBox.shrink();
              }
              return _buildContent(l10n, pages, lang, locale);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildError(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 64,
            color: AppConfig.subtitleColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppConfig.subtitleColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => bootstrapConfigRefresh(ref),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    AppLocalizations l10n,
    List<OnboardingPageConfig> pages,
    String lang,
    AppLocale locale,
  ) {
    final pageCount = pages.length;
    if (pageCount == 0) return const SizedBox.shrink();

    final isLastPage = _currentPage == pageCount - 1;

    return Column(
      children: [
        // Top bar: language toggle left, Skip right
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LanguageToggle(
                currentLocale: locale,
                onTap: () {
                  ref.read(appLocaleProvider.notifier).state =
                      locale == AppLocale.en ? AppLocale.ar : AppLocale.en;
                },
              ),
              TextButton(
                onPressed: () {
                  if (ref.read(developmentModeProvider)) {
                    context.go(AppRoutes.underDevelopment);
                  } else {
                    context.go(AppRoutes.register);
                  }
                },
                child: Text(l10n.skip),
              ),
            ],
          ),
        ),
        // Content: image + title + description
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pageCount,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) => OnboardingPageWidget(
              pageConfig: pages[index],
              lang: lang,
            ),
          ),
        ),
        // Bottom section: dots, gap, CTA, padding
        _DotsIndicator(
          currentPage: _currentPage,
          pageCount: pageCount,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _onContinue(pageCount),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConfig.radiusLarge),
                ),
              ),
              child: Text(
                isLastPage ? l10n.getStarted : l10n.continueButton,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({
    required this.currentLocale,
    required this.onTap,
  });

  final AppLocale currentLocale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = currentLocale == AppLocale.en ? 'EN' : 'AR';
    return TextButton(
      onPressed: onTap,
      child: Text(label),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({
    required this.currentPage,
    required this.pageCount,
  });

  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(pageCount, (index) {
          final isActive = index == currentPage;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? AppConfig.primaryColor
                  : AppConfig.borderColor,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}
