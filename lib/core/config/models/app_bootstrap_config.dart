import 'package:flutter/material.dart';

/// Parses hex color string (with or without #). Returns fallback on error.
Color parseHexColor(String? hex, Color fallback) {
  if (hex == null || hex.isEmpty) return fallback;
  final h = hex.startsWith('#') ? hex.substring(1) : hex;
  if (h.length != 6 && h.length != 8) return fallback;
  final value = int.tryParse(h, radix: 16);
  if (value == null) return fallback;
  if (h.length == 6) return Color(0xFF000000 | value);
  return Color(value);
}

/// Theme from remote config. Laravel snake_case.
class ThemeConfig {
  const ThemeConfig({
    this.primaryColor,
    this.backgroundColor,
    this.textColor,
    this.mutedTextColor,
  });

  final String? primaryColor;
  final String? backgroundColor;
  final String? textColor;
  final String? mutedTextColor;

  static const Color _defaultPrimary = Color(0xFF1E66F5);
  static const Color _defaultBackground = Color(0xFFFFFFFF);
  static const Color _defaultText = Color(0xFF0B1220);
  static const Color _defaultMuted = Color(0xFF6B7280);

  factory ThemeConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ThemeConfig.fallback;
    return ThemeConfig(
      primaryColor: json['primary_color'] as String?,
      backgroundColor: json['background_color'] as String?,
      textColor: json['text_color'] as String?,
      mutedTextColor: json['muted_text_color'] as String?,
    );
  }

  Color get primary => parseHexColor(primaryColor, _defaultPrimary);
  Color get background => parseHexColor(backgroundColor, _defaultBackground);
  Color get text => parseHexColor(textColor, _defaultText);
  Color get muted => parseHexColor(mutedTextColor, _defaultMuted);

  static const ThemeConfig fallback = ThemeConfig();
}

/// Remote config for Splash. Bilingual + Laravel snake_case.
class SplashConfig {
  const SplashConfig({
    required this.logoUrl,
    required this.titleEn,
    required this.titleAr,
    required this.subtitleEn,
    required this.subtitleAr,
    this.progressTextEn,
    this.progressTextAr,
  });

  final String logoUrl;
  final String titleEn;
  final String titleAr;
  final String subtitleEn;
  final String subtitleAr;
  final String? progressTextEn;
  final String? progressTextAr;

  /// If Arabic requested but field empty, fallback to English.
  String title(String lang) =>
      lang == 'ar' ? (titleAr.trim().isNotEmpty ? titleAr : titleEn) : titleEn;
  String subtitle(String lang) =>
      lang == 'ar'
          ? (subtitleAr.trim().isNotEmpty ? subtitleAr : subtitleEn)
          : subtitleEn;
  String? progressText(String lang) {
    if (lang == 'ar') {
      return progressTextAr != null && progressTextAr!.trim().isNotEmpty
          ? progressTextAr
          : progressTextEn;
    }
    return progressTextEn;
  }

  factory SplashConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return SplashConfig.fallback;
    return SplashConfig(
      logoUrl: json['logo_url'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? 'Zayer',
      titleAr: json['title_ar'] as String? ?? 'زير',
      subtitleEn:
          json['subtitle_en'] as String? ?? 'Shop globally, delivered locally',
      subtitleAr: json['subtitle_ar'] as String? ?? 'تسوق عالميًا، توصيل محلي',
      progressTextEn: json['progress_text_en'] as String?,
      progressTextAr: json['progress_text_ar'] as String?,
    );
  }

  static const SplashConfig fallback = SplashConfig(
    logoUrl: '',
    titleEn: 'Zayer',
    titleAr: 'زير',
    subtitleEn: 'Shop globally, delivered locally',
    subtitleAr: 'تسوق عالميًا، توصيل محلي',
    progressTextEn: null,
    progressTextAr: null,
  );
}

/// Single onboarding page. Bilingual + Laravel snake_case.
class OnboardingPageConfig {
  const OnboardingPageConfig({
    required this.imageUrl,
    required this.titleEn,
    required this.titleAr,
    required this.descriptionEn,
    required this.descriptionAr,
  });

  final String imageUrl;
  final String titleEn;
  final String titleAr;
  final String descriptionEn;
  final String descriptionAr;

  /// If Arabic requested but field empty, fallback to English.
  String title(String lang) =>
      lang == 'ar' ? (titleAr.trim().isNotEmpty ? titleAr : titleEn) : titleEn;
  String description(String lang) =>
      lang == 'ar'
          ? (descriptionAr.trim().isNotEmpty ? descriptionAr : descriptionEn)
          : descriptionEn;

  factory OnboardingPageConfig.fromJson(Map<String, dynamic> json) {
    final titleEn = json['title_en'] as String? ?? '';
    final titleAr = json['title_ar'] as String? ?? titleEn;
    final descEn = json['description_en'] as String? ?? '';
    final descAr = json['description_ar'] as String? ?? descEn;
    return OnboardingPageConfig(
      imageUrl: json['image_url'] as String? ?? '',
      titleEn: titleEn,
      titleAr: titleAr,
      descriptionEn: descEn,
      descriptionAr: descAr,
    );
  }
}

/// Canonical key for matching [MarketCountryConfig.code] with [StoreConfig.countryCode].
/// Trims, uppercases, and treats UK and GB as the same market (common API mismatch).
String canonicalMarketCountryCode(String code) {
  final u = code.trim().toUpperCase();
  if (u == 'UK' || u == 'GB') return 'GB';
  return u;
}

/// True when two bootstrap country codes refer to the same market.
bool marketCountryCodesEqual(String a, String b) {
  return canonicalMarketCountryCode(a) == canonicalMarketCountryCode(b);
}

/// Market country for filter chips. Laravel snake_case.
class MarketCountryConfig {
  const MarketCountryConfig({
    required this.code,
    required this.name,
    this.flagEmoji = '',
    this.isFeatured,
    this.storeCount,
  });

  final String code;
  final String name;
  final String flagEmoji;
  final bool? isFeatured;
  /// When set by API (`store_count` / `stores_count`), shown on home instead of counting [MarketsConfig.featuredStores] only.
  final int? storeCount;

  factory MarketCountryConfig.fromJson(Map<String, dynamic> json) {
    final rawCount = json['store_count'] ?? json['stores_count'];
    int? parsedCount;
    if (rawCount is int) {
      parsedCount = rawCount;
    } else if (rawCount is String) {
      parsedCount = int.tryParse(rawCount.trim());
    }

    return MarketCountryConfig(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      flagEmoji: json['flag_emoji'] as String? ?? '',
      isFeatured: json['is_featured'] as bool?,
      storeCount: parsedCount,
    );
  }
}

/// Store config for markets directory. Laravel snake_case.
class StoreConfig {
  const StoreConfig({
    required this.id,
    required this.name,
    required this.description,
    this.logoUrl = '',
    required this.countryCode,
    required this.storeUrl,
    this.isFeatured = false,
    this.categories = const <String>[],
  });

  final String id;
  final String name;
  final String description;
  final String logoUrl;
  final String countryCode;
  final String storeUrl;
  final bool isFeatured;
  final List<String> categories;

  factory StoreConfig.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'];
    List<String> categories = const <String>[];
    if (rawCategories is List) {
      categories = rawCategories
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return StoreConfig(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      logoUrl: json['logo_url'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
      storeUrl: json['store_url'] as String? ?? '',
      isFeatured: json['is_featured'] as bool? ?? false,
      categories: categories,
    );
  }
}

/// Markets screen config. Laravel snake_case.
class MarketsConfig {
  const MarketsConfig({
    required this.title,
    required this.subtitle,
    required this.countries,
    required this.featuredStores,
  });

  final String title;
  final String subtitle;
  final List<MarketCountryConfig> countries;
  final List<StoreConfig> featuredStores;

  factory MarketsConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return MarketsConfig.fallback;
    final countriesList = json['countries'] as List<dynamic>?;
    final storesList = json['featured_stores'] as List<dynamic>?;
    return MarketsConfig(
      title: json['title'] as String? ?? MarketsConfig.fallbackTitle,
      subtitle: json['subtitle'] as String? ?? 'Shop directly from official stores worldwide',
      countries: countriesList
              ?.map((e) => MarketCountryConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          MarketsConfig.fallbackCountries,
      featuredStores: storesList
              ?.map((e) => StoreConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          MarketsConfig.fallbackStores,
    );
  }

  static const fallbackTitle = 'Explore Markets';

  static const fallbackCountries = [
    MarketCountryConfig(code: 'ALL', name: 'All Markets', flagEmoji: ''),
    MarketCountryConfig(code: 'US', name: 'USA', flagEmoji: '🇺🇸'),
    MarketCountryConfig(code: 'TR', name: 'Turkey', flagEmoji: '🇹🇷'),
    MarketCountryConfig(code: 'UK', name: 'UK', flagEmoji: '🇬🇧'),
  ];

  static const fallbackStores = [
    StoreConfig(
      id: 'amazon_us',
      name: 'Amazon US',
      description: 'Global marketplace for tech & electronics',
      countryCode: 'US',
      storeUrl: 'https://www.amazon.com',
      isFeatured: true,
    ),
    StoreConfig(
      id: 'trendyol',
      name: 'Trendyol',
      description: "Turkey's largest fashion & beauty hub",
      countryCode: 'TR',
      storeUrl: 'https://www.trendyol.com',
      isFeatured: true,
    ),
    StoreConfig(
      id: 'asos_uk',
      name: 'ASOS UK',
      description: 'British fashion destination with 850+ brands',
      countryCode: 'UK',
      storeUrl: 'https://www.asos.com',
      isFeatured: true,
    ),
  ];

  static const MarketsConfig fallback = MarketsConfig(
    title: 'Explore Markets',
    subtitle: 'Shop directly from official stores worldwide',
    countries: fallbackCountries,
    featuredStores: fallbackStores,
  );
}

/// Promo banner from bootstrap. Laravel snake_case.
class PromoBannerConfig {
  const PromoBannerConfig({
    required this.id,
    required this.label,
    required this.title,
    required this.ctaText,
    this.imageUrl = '',
    this.deepLink = '',
  });

  final Object id;
  final String label;
  final String title;
  final String ctaText;
  final String imageUrl;
  final String deepLink;

  factory PromoBannerConfig.fromJson(Map<String, dynamic> json) {
    return PromoBannerConfig(
      id: json['id'] ?? '',
      label: json['label'] as String? ?? '',
      title: json['title'] as String? ?? '',
      ctaText: json['cta_text'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      deepLink: json['deep_link'] as String? ?? '',
    );
  }
}

class PaymentGatewayProviderConfig {
  const PaymentGatewayProviderConfig({
    required this.enabled,
    required this.environment,
    this.publishableKey,
    this.supportsWebCheckout = true,
  });

  final bool enabled;
  final String environment;
  final String? publishableKey;
  final bool supportsWebCheckout;

  factory PaymentGatewayProviderConfig.fromJson(Map<String, dynamic> json) {
    return PaymentGatewayProviderConfig(
      enabled: json['enabled'] as bool? ?? false,
      environment: (json['environment'] as String?)?.trim().isNotEmpty == true
          ? (json['environment'] as String).trim()
          : 'test',
      publishableKey: json['publishable_key'] as String?,
      supportsWebCheckout: json['supports_web_checkout'] as bool? ?? true,
    );
  }
}

class PaymentGatewaysConfig {
  const PaymentGatewaysConfig({
    required this.defaultGatewayCode,
    required this.enabled,
    required this.providers,
  });

  final String defaultGatewayCode;
  final List<String> enabled;
  final Map<String, PaymentGatewayProviderConfig> providers;

  factory PaymentGatewaysConfig.fromJson(Map<String, dynamic> json) {
    final enabledList = (json['enabled'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();

    final providerMapJson = json['providers'] as Map<String, dynamic>? ?? const {};
    final providerMap = <String, PaymentGatewayProviderConfig>{};
    for (final entry in providerMapJson.entries) {
      final v = entry.value;
      if (v is Map<String, dynamic>) {
        providerMap[entry.key] = PaymentGatewayProviderConfig.fromJson(v);
      }
    }

    return PaymentGatewaysConfig(
      defaultGatewayCode: (json['default'] as String?)?.trim().isNotEmpty == true
          ? (json['default'] as String).trim()
          : 'square',
      enabled: enabledList,
      providers: providerMap,
    );
  }
}

/// Root bootstrap config: theme + splash + onboarding + markets + promo_banners + api_base_url + development_mode + app_name + app_icon_url.
class AppBootstrapConfig {
  const AppBootstrapConfig({
    required this.theme,
    required this.splash,
    required this.onboarding,
    this.markets,
    this.promoBanners = const [],
    this.apiBaseUrl,
    this.developmentMode = false,
    this.appName,
    this.appIconUrl,
    this.paymentGateways,
    this.checkoutPaymentMode,
  });

  final ThemeConfig theme;
  final SplashConfig splash;
  final List<OnboardingPageConfig> onboarding;
  final MarketsConfig? markets;
  final List<PromoBannerConfig> promoBanners;
  /// Base URL for API from admin panel. When set, app uses it for all requests.
  final String? apiBaseUrl;
  /// When true (set in admin), app shows development UI (banner / dev screen).
  final bool developmentMode;
  /// App display name from admin. Used for MaterialApp title.
  final String? appName;
  /// App icon/logo URL from admin. Used inside the app (e.g. AppBar).
  final String? appIconUrl;
  final PaymentGatewaysConfig? paymentGateways;
  /// Same source as checkout: `wallet_only` | `gateway_only` | `wallet_and_gateway`.
  final String? checkoutPaymentMode;

  factory AppBootstrapConfig.fromJson(Map<String, dynamic> json) {
    final themeJson = json['theme'] as Map<String, dynamic>?;
    final splashJson = json['splash'] as Map<String, dynamic>?;
    final onboardingList = json['onboarding'] as List<dynamic>?;
    final marketsJson = json['markets'] as Map<String, dynamic>?;
    final promoList = json['promo_banners'] as List<dynamic>?;
    final apiBase = json['api_base_url'] as String?;
    final devMode = json['development_mode'] as bool? ?? false;
    final appName = json['app_name'] as String?;
    final appIconUrl = json['app_icon_url'] as String?;
    final paymentGatewaysJson = json['payment_gateways'] as Map<String, dynamic>?;
    final paymentGateways = paymentGatewaysJson != null
        ? PaymentGatewaysConfig.fromJson(paymentGatewaysJson)
        : null;
    final checkoutMode = (json['checkout_payment_mode'] as String?)?.trim();
    return AppBootstrapConfig(
      theme: ThemeConfig.fromJson(themeJson),
      splash: SplashConfig.fromJson(splashJson),
      onboarding: onboardingList
              ?.map((e) => OnboardingPageConfig.fromJson(
                    e as Map<String, dynamic>,
                  ))
              .toList() ??
          AppBootstrapConfig.fallbackOnboarding,
      markets: MarketsConfig.fromJson(marketsJson),
      promoBanners: promoList
              ?.map((e) => PromoBannerConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      apiBaseUrl: apiBase != null && apiBase.trim().isNotEmpty ? apiBase.trim() : null,
      developmentMode: devMode,
      appName: appName != null && appName.trim().isNotEmpty ? appName.trim() : null,
      appIconUrl: appIconUrl != null && appIconUrl.trim().isNotEmpty ? appIconUrl.trim() : null,
      paymentGateways: paymentGateways,
      checkoutPaymentMode: checkoutMode != null && checkoutMode.isNotEmpty
          ? checkoutMode
          : null,
    );
  }

  static const List<OnboardingPageConfig> fallbackOnboarding = [
    OnboardingPageConfig(
      imageUrl: '',
      titleEn: 'Shop from Global Stores',
      titleAr: 'تسوق من متاجر العالم',
      descriptionEn:
          "Access millions of products from the world's best markets directly through Zayer.",
      descriptionAr:
          'الوصول إلى ملايين المنتجات من أفضل أسواق العالم مباشرة عبر زير.',
    ),
    OnboardingPageConfig(
      imageUrl: '',
      titleEn: 'Combine & Save',
      titleAr: 'اجمع ووفر',
      descriptionEn:
          'We group your purchases by origin country to minimize shipping costs and maximize your savings.',
      descriptionAr:
          'نجمع مشترياتك حسب دولة المنشأ لتقليل تكاليف الشحن وزيادة توفيرك.',
    ),
    OnboardingPageConfig(
      imageUrl: '',
      titleEn: 'Transparent Tracking',
      titleAr: 'تتبع شفاف',
      descriptionEn:
          'No hidden fees. Track your consolidated shipments from the warehouse to your doorstep in real-time.',
      descriptionAr:
          'بدون رسوم خفية. تتبع شحناتك المجمعة من المستودع إلى عتبة بابك في الوقت الفعلي.',
    ),
  ];

  static AppBootstrapConfig get fallback => AppBootstrapConfig(
        theme: ThemeConfig.fallback,
        splash: SplashConfig.fallback,
        onboarding: fallbackOnboarding,
        markets: MarketsConfig.fallback,
        promoBanners: const [],
        checkoutPaymentMode: null,
      );
}

