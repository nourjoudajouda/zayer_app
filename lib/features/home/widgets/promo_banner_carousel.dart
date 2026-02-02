import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/home_providers.dart';

/// Promo banner carousel with PageView and dots inside each banner.
/// Supports multiple banners. Replace with API/remote config later.
class PromoBannerCarousel extends StatefulWidget {
  const PromoBannerCarousel({super.key, required this.banners});

  final List<PromoBanner> banners;

  @override
  State<PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends State<PromoBannerCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemCount: widget.banners.length,
        itemBuilder: (context, i) => _BannerCard(
          banner: widget.banners[i],
          dotsCount: widget.banners.length,
          activeIndex: _currentPage,
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.banner,
    required this.dotsCount,
    required this.activeIndex,
  });

  final PromoBanner banner;
  final int dotsCount;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.primaryColor,
        borderRadius: BorderRadius.circular(AppConfig.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppConfig.primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              banner.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: Text(
                banner.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppConfig.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConfig.radiusXLarge),
                ),
              ),
              child: Text(banner.ctaText),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                dotsCount,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _Dot(active: i == activeIndex),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white38,
        shape: BoxShape.circle,
      ),
    );
  }
}
