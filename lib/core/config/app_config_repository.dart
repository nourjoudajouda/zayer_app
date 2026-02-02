import 'models/app_bootstrap_config.dart';

/// Fetches app bootstrap config (theme + splash + onboarding) from remote or mock.
abstract class AppConfigRepository {
  Future<AppBootstrapConfig> fetchBootstrapConfig();
}

/// Mock implementation: Laravel-style JSON with theme + bilingual splash/onboarding.
class AppConfigRepositoryMock implements AppConfigRepository {
  @override
  Future<AppBootstrapConfig> fetchBootstrapConfig() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    const mockJson = {
      'theme': {
        'primary_color': '1E66F5',
        'background_color': 'FFFFFF',
        'text_color': '0B1220',
        'muted_text_color': '6B7280',
      },
      'splash': {
        'logo_url':
            'https://via.placeholder.com/160x160/1E66F5/FFFFFF?text=Z',
        'title_en': 'Zayer',
        'title_ar': 'زير',
        'subtitle_en': 'Shop globally, delivered locally',
        'subtitle_ar': 'تسوق عالميًا، توصيل محلي',
        'progress_text_en': null,
        'progress_text_ar': null,
      },
      'onboarding': [
        {
          'image_url':
              'https://via.placeholder.com/400x300/1E66F5/FFFFFF?text=Shop',
          'title_en': 'Shop from Global Stores',
          'title_ar': 'تسوق من متاجر العالم',
          'description_en':
              "Access millions of products from the world's best markets directly through Zayer.",
          'description_ar':
              'الوصول إلى ملايين المنتجات من أفضل أسواق العالم مباشرة عبر زير.',
        },
        {
          'image_url':
              'https://via.placeholder.com/400x300/1E66F5/FFFFFF?text=Save',
          'title_en': 'Combine & Save',
          'title_ar': 'اجمع ووفر',
          'description_en':
              'We group your purchases by origin country to minimize shipping costs and maximize your savings.',
          'description_ar':
              'نجمع مشترياتك حسب دولة المنشأ لتقليل تكاليف الشحن وزيادة توفيرك.',
        },
        {
          'image_url':
              'https://via.placeholder.com/400x300/1E66F5/FFFFFF?text=Track',
          'title_en': 'Transparent Tracking',
          'title_ar': 'تتبع شفاف',
          'description_en':
              'No hidden fees. Track your consolidated shipments from the warehouse to your doorstep in real-time.',
          'description_ar':
              'بدون رسوم خفية. تتبع شحناتك المجمعة من المستودع إلى عتبة بابك في الوقت الفعلي.',
        },
      ],
      'markets': {
        'title': 'Explore Markets',
        'subtitle': 'Shop directly from official stores worldwide',
        'countries': [
          {'code': 'ALL', 'name': 'All Markets', 'flag_emoji': ''},
          {'code': 'US', 'name': 'USA', 'flag_emoji': '🇺🇸'},
          {'code': 'TR', 'name': 'Turkey', 'flag_emoji': '🇹🇷'},
          {'code': 'UK', 'name': 'UK', 'flag_emoji': '🇬🇧'},
          {'code': 'FR', 'name': 'France', 'flag_emoji': '🇫🇷'},
          {'code': 'AE', 'name': 'UAE', 'flag_emoji': '🇦🇪'},
        ],
        'featured_stores': [
          {
            'id': 'amazon_us',
            'name': 'Amazon US',
            'description': 'Global marketplace for tech & electronics',
            'logo_url': '',
            'country_code': 'US',
            'store_url': 'https://www.amazon.com',
            'is_featured': true,
          },
          {
            'id': 'trendyol',
            'name': 'Trendyol',
            'description': "Turkey's largest fashion & beauty hub",
            'logo_url': '',
            'country_code': 'TR',
            'store_url': 'https://www.trendyol.com',
            'is_featured': true,
          },
          {
            'id': 'asos_uk',
            'name': 'ASOS UK',
            'description': 'British fashion destination with 850+ brands',
            'logo_url': '',
            'country_code': 'UK',
            'store_url': 'https://www.asos.com',
            'is_featured': true,
          },
          {
            'id': 'sephora_fr',
            'name': 'Sephora France',
            'description': 'Premium makeup, skin & hair care',
            'logo_url': '',
            'country_code': 'FR',
            'store_url': 'https://www.sephora.fr',
            'is_featured': true,
          },
          {
            'id': 'apple_uae',
            'name': 'Apple UAE',
            'description': 'Official products and accessories',
            'logo_url': '',
            'country_code': 'AE',
            'store_url': 'https://www.apple.com/ae',
            'is_featured': true,
          },
        ],
      },
    };

    return AppBootstrapConfig.fromJson(mockJson);
  }
}
