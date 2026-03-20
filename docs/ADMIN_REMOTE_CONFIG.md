# Admin Remote Config

This document describes the **remote bootstrap config** that drives Splash, Onboarding, and app theme. All admin-controlled content and theme colors come from this config. No marketing copy is hardcoded in the app except fallbacks when the API fails.

---

## 1. Overview

- **Endpoint (future):** e.g. `GET /api/bootstrap-config` (Laravel).
- **Current:** Mock repository returns the same JSON structure locally (`AppConfigRepositoryMock`).
- **Caching:** Config is cached in memory until the user taps **Retry** on error or the provider is invalidated.
- **Versioning:** Optional `version` or `updated_at` in JSON can be used later for cache invalidation.

---

## 2. JSON Schema (Laravel-style, snake_case)

Root object:

```json
{
  "theme": { ... },
  "splash": { ... },
  "onboarding": [ ... ]
}
```

### 2.1 `theme`

| Field | Type | Required | Fallback | Description |
|-------|------|----------|----------|-------------|
| `primary_color` | string | No | `1E66F5` | Hex without `#`. Primary buttons, links, active dot. |
| `background_color` | string | No | `FFFFFF` | Scaffold/surface background. |
| `text_color` | string | No | `0B1220` | Primary text. |
| `muted_text_color` | string | No | `6B7280` | Secondary/subtitle text. |

All theme colors are applied app-wide via `AppTheme.fromConfig(config.theme)`. Material 3 is used; only these colors are overridden from config.

### 2.2 `splash`

| Field | Type | Required | Fallback | Description |
|-------|------|----------|----------|-------------|
| `logo_url` | string | No | `""` | Logo image URL. Empty → placeholder icon. |
| `title_en` | string | No | `Zayer` | App name (English). |
| `title_ar` | string | No | `زير` | App name (Arabic). If empty, EN is used. |
| `subtitle_en` | string | No | `Shop globally, delivered locally` | Tagline (English). |
| `subtitle_ar` | string | No | Arabic default | Tagline (Arabic). If empty, EN is used. |
| `progress_text_en` | string | null | null | Optional label under progress bar (EN). |
| `progress_text_ar` | string | null | null | Optional label under progress bar (AR). If null/empty, EN or `%` is used. |

**Localization:** App language is EN by default. When user selects **AR** (onboarding EN/AR toggle or Settings), splash uses `title_ar`, `subtitle_ar`, `progress_text_ar`; if any AR field is missing or empty, the app falls back to the EN value.

### 2.3 `onboarding`

Array of page objects. **If empty, the app skips onboarding and goes to `/register` after splash.**

Each page:

| Field | Type | Required | Fallback | Description |
|-------|------|----------|----------|-------------|
| `image_url` | string | No | `""` | Illustration URL. Empty → placeholder. |
| `title_en` | string | No | `""` | Page title (English). |
| `title_ar` | string | No | `title_en` | Page title (Arabic). If empty, EN is used. |
| `description_en` | string | No | `""` | Body text (English). |
| `description_ar` | string | No | `description_en` | Body text (Arabic). If empty, EN is used. |

**Localization:** Same rule: when language is AR, use `*_ar`; if `*_ar` is missing or empty, use `*_en`.

### 2.4 `stores` (for Home dashboard)

Admin-controlled store list for "Markets / Stores". Each store:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | Yes | Store key (e.g. `amazon_us`). |
| `name` | string | Yes | Display name. |
| `name_ar` | string | No | Arabic name. Fallback to `name`. |
| `logo_url` | string | No | Store logo URL. |
| `store_url` | string | Yes | Base URL for WebView (e.g. `https://www.amazon.com`). |
| `categories` | array | No | Category chips for store landing (e.g. `["Electronics","Fashion"]`). |
| `official` | bool | No | Show official/verified badge. Default true. |

### 2.5 `home` (Home Dashboard)

Admin-controlled home screen content.

| Field | Type | Required | Fallback | Description |
|-------|------|----------|----------|-------------|
| `user_greeting_name` | string | No | `""` | Name for "Hello, {name} 👋". Empty → use profile or "User". |
| `promo_carousel` | array | No | `[]` | Promo cards. Each: `{ "label", "title", "cta_label", "cta_url" }`. |
| `notification_badge_count` | int | No | 0 | Optional badge on bell icon. 0 = hide. |
| `markets` | array | No | `[]` | Global markets. Each: `{ "id", "name", "image_url", "store_count" }`. |
| `popular_stores` | array | No | `[]` | Popular stores grid. Each: `{ "id", "name", "category", "logo_url" }`. |

**Example promo item:**
```json
{ "label": "FLASH SALE", "title": "Up to 40% off on US Premium Brands", "cta_label": "Shop Now", "cta_url": "/store?url=..." }
```

### 2.6 `store_landing` (Store Profile, per store)

When `GET /api/stores/{id}` returns store details, these fields can also come from bootstrap or a store config:

| Field | Type | Required | Fallback | Description |
|-------|------|----------|----------|-------------|
| `logo_url` | string | No | `""` | Store logo. |
| `name` | string | Yes | — | Display name (e.g. "Amazon US"). |
| `verified` | bool | No | true | Show verified badge. |
| `official` | bool | No | true | OFFICIAL STORE chip. |
| `secure` | bool | No | true | SECURE chip. |
| `categories` | array | No | `[]` | "What you can shop" chips. |
| `base_url` | string | Yes | — | WebView base URL. |
| `info_banner_text` | string | No | `""` | Info banner in light-blue box. |
| `consolidation_promo_title` | string | No | "CONSOLIDATION BENEFITS" | Bottom promo card title. |
| `consolidation_promo_subtitle` | string | No | "Save up to 70% on shipping" | Bottom promo subtitle. |

### 2.7 `user_profile` (Profile & Compliance)

Structure is fixed; labels can be localized via l10n or config later.

| Field | Type | Description |
|-------|------|-------------|
| `identity_action_required_label` | string | "ACTION REQUIRED" text. |
| `verified_for_international_label` | string | Verified pill text. |
| `why_required_link` | string | "Why is this required?" link. |

### 2.8 Markets / Stores Directory

Remote config for the Explore Markets screen. Can live in bootstrap-config under `markets` or a separate endpoint.

| Field | Type | Required | Fallback | Description |
|-------|------|----------|----------|-------------|
| `title` | string | No | "Explore Markets" | Screen title (English only). |
| `subtitle` | string | No | "Shop directly from official stores worldwide" | Subtitle under title. |
| `countries` | array | No | `[]` | Country filter chips. Each: `{ "code", "name", "flag_emoji", "is_featured?", "store_count?" }`. Optional `store_count` (or `stores_count`) overrides the home-screen store total (otherwise derived from `featured_stores`). |
| `featured_stores` | array | No | `[]` | Store cards. Each: `{ "id", "name", "description", "logo_url", "country_code", "store_url", "is_featured" }`. |

**Per-country:** `code` (e.g. "US", "ALL"), `name`, `flag_emoji` (e.g. "🇺🇸"), `is_featured` (optional), `store_count` / `stores_count` (optional, integer — total stores for home badge; app matches `UK` and `GB` as one market).

**Per-store:** `id`, `name`, `description`, `logo_url`, `country_code`, `store_url`, `is_featured`.

### 2.9 Paste Product Link (Add via Link)

Admin-controlled UI for the Paste Product Link screen. Can live in bootstrap-config or a separate endpoint.

| Field | Type | Fallback | Description |
|-------|------|----------|-------------|
| `add_via_link_title` | string | "Add via Link" | AppBar title. |
| `paste_product_link_heading` | string | "Paste Product Link" | Main heading. |
| `paste_product_link_subtitle` | string | "Paste the product URL from any international store to add it to your Zayer cart." | Subtitle. |
| `paste_button_label` | string | "PASTE" | Button inside URL field. |
| `invalid_link_message` | string | "Invalid or unsupported link" | Error text for invalid URL. |
| `view_supported_stores_link` | string | "View supported stores" | Link under invalid error. |
| `add_to_cart_button` | string | "Add to Cart" | Bottom CTA label. |

### 2.10 Store Landing Page & WebView

Admin-controlled store metadata and PDP detection rules.

| Field | Type | Description |
|-------|------|-------------|
| `stores` | array | List of supported stores for Markets and WebView. |
| Per store: `id` | string | Unique store key (e.g. "amazon_us"). Must match store keys used in app: `"amazon"`, `"ebay"`, `"walmart"`, `"etsy"`, `"aliexpress"`. |
| Per store: `name` | string | Display name (e.g. "Amazon US"). |
| Per store: `name_ar` | string | Arabic display name (optional). |
| Per store: `logo_url` | string | Store logo image URL. |
| Per store: `country` | string | Store country (e.g. "USA"). |
| Per store: `store_url` | string | Base store URL (e.g. "https://www.amazon.com"). |
| Per store: `badges` | object | Badges to display: `{ "official": true, "secure": true, "verified": true }`. |
| Per store: `categories` | array | Categories list for "What you can shop" (e.g. ["Electronics", "Fashion"]). |
| Per store: `pdp_rules` | object | PDP detection rules: `{ "url_patterns": ["/dp/", "/gp/product/"], "exclude_patterns": ["/s?", "/gp/bestsellers"] }`. |
| Per store: `extraction_enabled` | bool | Whether product extraction is enabled for this store (default: true). |
| Per store: `supported_currencies` | array | Supported currencies for this store: `["USD", "EUR", "GBP", "ILS"]`. |

**Note:** Product extraction is currently implemented client-side using JavaScript injection. Backend can provide extraction rules or fallback to server-side extraction if client-side fails.

### 2.11 Empty-State Screens (Favorites, Notifications, Orders, Cart)

Configurable strings and illustration URLs for empty-state screens. Can live in bootstrap-config or a separate endpoint.

**Favorites empty:**

| Field | Fallback | Description |
|-------|----------|-------------|
| `favorites_empty_title` | "No favorites yet" | Title. |
| `favorites_empty_subtitle` | "Save products from any store and we'll track prices and stock for you." | Subtitle. |
| `favorites_empty_image_url` | `""` | Illustration URL. Empty → placeholder icon. |
| `favorites_empty_primary_cta_text` | "Browse Stores" | Primary button. |

**Notifications empty:**

| Field | Fallback | Description |
|-------|----------|-------------|
| `notifications_empty_title` | "You're all caught up 🎉" | Title. |
| `notifications_empty_subtitle` | "We'll notify you about your orders, shipments, payments, and support updates." | Subtitle. |
| `notifications_empty_image_url` | `""` | Illustration URL. Empty → placeholder. |
| `notifications_empty_primary_cta_text` | "Track My Orders" | Primary button. |

**Orders empty:**

| Field | Fallback | Description |
|-------|----------|-------------|
| `orders_empty_title` | "You don't have any orders yet." | Title. |
| `orders_empty_subtitle` | "Explore global markets and start shopping from international stores." | Subtitle. |
| `orders_empty_image_url` | `""` | Illustration URL. Empty → placeholder. |
| `orders_empty_primary_cta_text` | "Start Shopping" | Primary button. |

**Cart empty:**

| Field | Fallback | Description |
|-------|----------|-------------|
| `cart_empty_title` | "Your cart is empty" | Title. |
| `cart_empty_subtitle` | "Start adding products from global stores by pasting their links." | Subtitle. |
| `cart_empty_image_url` | `""` | Illustration URL. Empty → ZAYER placeholder. |
| `cart_empty_primary_cta_text` | "Add Product via Link" | Primary button. |
| `cart_empty_secondary_cta_text` | "Browse Stores" | Secondary button. |

**Note:** All app copy is English by default; Arabic is enabled only via in-app language toggle later (no mixed text).

### 2.12 Settings & Preferences, Notification Settings, Orders List, Review & Pay

Configurable labels, defaults, and options for the four screens. Can live in bootstrap-config or a separate endpoint.

**Settings & Preferences:**

| Field | Fallback | Description |
|-------|----------|-------------|
| `settings_section_general` | "GENERAL" | Section header. |
| `settings_section_shipping` | "SHIPPING & LOGISTICS" | Section header. |
| `settings_section_communication` | "COMMUNICATION" | Section header. |
| `settings_section_support` | "SUPPORT & PRIVACY" | Section header. |
| `settings_app_language` | "App Language" | Row label. |
| `settings_display_currency` | "Display Currency" | Row label. |
| `settings_currency_warning` | (info box text) | Warning when changing currency. |
| `settings_warehouse_list` | array | List of warehouses: `{ "id", "label" }` (e.g. Delaware US). |
| `settings_currencies` | array | Supported currencies: `{ "code", "symbol" }` (e.g. USD, \$). |
| `settings_smart_consolidation_default` | true | Default for Smart Consolidation toggle. |
| `settings_auto_insurance_default` | false | Default for Auto-Insurance toggle (can be disabled by admin). |
| `settings_footer_server` | "Server: Region-West-1" | Footer server label. |
| `settings_sign_out` | "Sign Out" | Button label. |
| `settings_delete_account` | "Delete Account" | Destructive card title/label. |

**Notification Settings:**

| Field | Fallback | Description |
|-------|----------|-------------|
| `notification_settings_title` | "Notification Settings" | AppBar title. |
| `notification_section_global` | "GLOBAL CHANNELS" | Section header. |
| `notification_section_order` | "ORDER & SHIPMENT" | Section header. |
| `notification_section_customs` | "CUSTOMS & COMPLIANCE" | Section header. |
| `notification_section_payments` | "PAYMENTS" | Section header. |
| `notification_section_promotions` | "PROMOTIONS" | Section header. |
| `notification_section_quiet` | "QUIET HOURS" | Section header. |
| `notification_customs_info` | (info box text) | Customs & compliance info. |
| `notification_quiet_hours_default_from` | "22:00" | Default quiet hours start (24h). |
| `notification_quiet_hours_default_to` | "07:00" | Default quiet hours end (24h). |
| `notification_save_button` | "Save Preferences" | Sticky button label. |
| Toggle defaults | (per channel) | push_enabled, email_enabled, order_updates, etc. |

**Orders List:**

| Field | Fallback | Description |
|-------|----------|-------------|
| `orders_tab_all` | "All" | Tab label. |
| `orders_tab_in_progress` | "In Progress" | Tab label. |
| `orders_tab_delivered` | "Delivered" | Tab label. |
| `orders_tab_cancelled` | "Cancelled" | Tab label. |
| `orders_status_in_transit` | "IN TRANSIT" | Status pill text. |
| `orders_status_delivered` | "DELIVERED" | Status pill text. |
| `orders_status_cancelled` | "CANCELLED" | Status pill text. |
| `orders_track_button` | "Track Order" | Button label. |
| `orders_buy_again_button` | "Buy Again" | Button label. |
| `orders_view_details_button` | "View Details" | Button label. |

**Review & Pay (Checkout):**

| Field | Fallback | Description |
|-------|----------|-------------|
| `checkout_title` | "Review & Pay" | AppBar title. |
| `checkout_shipping_to` | "Shipping to" | Label. |
| `checkout_change` | "Change" | Link label. |
| `checkout_consolidation_message` | "You saved {amount} with consolidation." | Consolidation benefit text. |
| `checkout_wallet_balance` | "Wallet balance" | Label. |
| `checkout_price_details` | "Price Details" | Section title. |
| `checkout_subtotal` | "Subtotal" | Row label. |
| `checkout_shipping` | "Shipping" | Row label. |
| `checkout_insurance` | "Insurance" | Row label. |
| `checkout_promo_placeholder` | "Promo Code" | Input placeholder. |
| `checkout_apply` | "Apply" | Button label. |
| `checkout_confirm_button` | "Confirm & Pay {total}" | Sticky button label. |
| `checkout_secure_caption` | "Secure payment" | Caption under button. |
| `checkout_fee_labels` | (subtotal, shipping, insurance, etc.) | Admin can override fee line labels. |

### 2.13 Account / Profile Remote Config (optional)

Admin-controlled UI for Profile & Compliance screen. Can live in bootstrap-config or a separate endpoint.

| Field | Type | Fallback | Description |
|-------|------|----------|-------------|
| `profile_labels` | object | — | Labels for section headers, tiles, buttons (e.g. `profile_title`, `full_legal_name`, `upload_id_button`). |
| `version_string` | string | `"Zayer v1.0.0"` | Footer app version. Use package_info_plus or config. |
| `enable_delete_account` | bool | true | Show/hide "Delete Account" button. |
| `enable_kyc_card` | bool | true | Show/hide Identity Verification card. |

---

## 3. Auth & Language Toggles (Admin-Controlled, Future)

The following can be exposed in bootstrap-config or a separate remote-config endpoint. For now the app uses fallbacks.

| Field | Type | Fallback | Description |
|-------|------|----------|-------------|
| `default_locale` | string | `en` | App start language. |
| `supported_locales` | array | `["en","ar"]` | Locales the app supports. |
| `show_language_toggle` | bool | `true` | Whether to show EN/AR toggle in AppBar (auth, onboarding). |
| `force_rtl` | bool | false | Optional; when AR selected, RTL is applied automatically. |

### 3.1 Auth Copy (Login)

| Field | Example | Description |
|-------|---------|-------------|
| `auth_login_title` | Login | AppBar title |
| `auth_login_heading` | Welcome back | Main heading |
| `auth_login_forgot_password` | Forgot password? | Link text |
| `auth_login_button` | Login | Primary button |
| `auth_login_otp_link` | Login with OTP instead | Secondary link |
| `auth_login_otp_helper` | No password needed | Helper text |
| `auth_login_or_continue` | OR CONTINUE WITH | Divider text |
| `auth_login_apple` | Apple | Social button |
| `auth_login_google` | Google | Social button |
| `auth_login_create_account` | Already have an account? Create Account | Bottom row |

### 3.2 Auth Copy (Register / Join Zayer)

| Field | Example |
|-------|---------|
| `auth_register_title` | Join Zayer |
| `auth_register_heading` | Join Zayer |
| `auth_register_subtitle` | Create your account to start shopping globally. |
| `auth_register_full_name` | Full Name |
| `auth_register_phone` | Phone Number |
| `auth_register_country` | Country |
| `auth_register_city` | City |
| `auth_register_password` | Password |
| `auth_register_password_req_*` | (3 requirement lines) |
| `auth_register_referral` | Have a referral code? |
| `auth_register_button` | Create Account |
| `auth_register_login_link` | Already have an account? Login |

### 3.3 OTP Copy

| Field | Example |
|-------|---------|
| `otp_title` | Verify Phone Number |
| `otp_subtitle` | We've sent a 6-digit code to |
| `otp_edit` | Edit |
| `otp_resend_in` | Resend in |
| `otp_verify` | Verify |
| `otp_terms` | By verifying, you agree to... |

### 3.4 Social & Legal

| Field | Type | Description |
|-------|------|-------------|
| `social_login_enabled` | object | `{ "apple": true, "google": true }` — toggles per provider. |
| `legal_links` | object | `{ "terms_url": "...", "privacy_url": "..." }` for OTP terms and footer links. |

**Note:** For now the app uses fallback strings from l10n (ARB files). When API is ready, these fields override per-locale.

---

## 4. Localization Rules

- **Default language:** English (`en`). Arabic is only used when the user taps the **EN/AR** toggle (onboarding top-left, auth AppBar top-right, or Settings).
- **Fallback:** For any bilingual field, if the requested language (e.g. `title_ar`) is missing or empty, the app uses the English value.
- **Direction:** When language is AR, the app uses RTL (`TextDirection.rtl`) for onboarding, splash, and auth screens; MaterialApp also gets the correct locale and builder-based direction.

---

## 5. Caching and Refresh

- **In-memory cache:** First successful fetch is stored; subsequent reads use cache until refresh.
- **Refresh:** User taps **Retry** on Splash or Onboarding error screen → cache is cleared and config is re-fetched.
- **No TTL in app yet:** Optional: backend can send `cache_max_age_seconds` and the app can refetch after that interval.

---

## 6. Implementation References

- **Models:** `lib/core/config/models/app_bootstrap_config.dart`  
  - `ThemeConfig`, `SplashConfig`, `OnboardingPageConfig`, `AppBootstrapConfig`  
  - All parse snake_case JSON and apply fallbacks.
- **Provider:** `lib/core/config/app_config_provider.dart`  
  - `bootstrapConfigProvider` (AsyncValue<AppBootstrapConfig>), `bootstrapConfigRefresh(ref)`.
- **Theme:** `lib/core/theme/app_theme.dart`  
  - `AppTheme.fromConfig(ThemeConfig)` builds Material 3 theme from config; default primary `#1E66F5` when config is loading or missing.

## 7. Product Extraction & WebView Implementation

**Status:** ✅ IMPLEMENTED - See `PRODUCT_EXTRACTION_IMPLEMENTATION.md` for detailed documentation.

**Key Files:**
- `lib/features/store_webview/store_webview_screen.dart` - Main WebView screen with product detection
- `lib/features/store_webview/extractors/product_data_extractor.dart` - JavaScript extraction scripts per store
- `lib/features/store_webview/rules/webview_import_rules.dart` - PDP detection rules
- `lib/features/store_webview/models/detected_product.dart` - Product data model
- `lib/core/import/normalize_url.dart` - URL normalization and store detection
- `lib/features/product_import/confirm_product_screen.dart` - Product confirmation screen

**Supported Stores:**
- Amazon (`amazon`) - `/dp/{ASIN}`, `/gp/product/{ASIN}`
- eBay (`ebay`) - `/itm/{id}`
- Walmart (`walmart`) - `/ip/{product-name}`
- Etsy (`etsy`) - `/listing/{id}`
- AliExpress (`aliexpress`) - `/item/{id}.html`

**Supported Currencies:**
- USD, EUR, GBP, ILS (Israeli Shekel), AED, SAR, EGP
- Automatic conversion to USD for calculations
- Exchange rates currently estimated (backend should provide real-time rates via API)

## 7. Product Extraction & WebView Implementation

**Status:** ✅ IMPLEMENTED - See `PRODUCT_EXTRACTION_IMPLEMENTATION.md` for detailed documentation.

**Key Files:**
- `lib/features/store_webview/store_webview_screen.dart` - Main WebView screen with product detection
- `lib/features/store_webview/extractors/product_data_extractor.dart` - JavaScript extraction scripts per store
- `lib/features/store_webview/rules/webview_import_rules.dart` - PDP detection rules
- `lib/features/store_webview/models/detected_product.dart` - Product data model
- `lib/core/import/normalize_url.dart` - URL normalization and store detection
- `lib/features/product_import/confirm_product_screen.dart` - Product confirmation screen

**Supported Stores:**
- Amazon (`amazon`) - `/dp/{ASIN}`, `/gp/product/{ASIN}`
- eBay (`ebay`) - `/itm/{id}`
- Walmart (`walmart`) - `/ip/{product-name}`
- Etsy (`etsy`) - `/listing/{id}`
- AliExpress (`aliexpress`) - `/item/{id}.html`

**Supported Currencies:**
- USD, EUR, GBP, ILS (Israeli Shekel), AED, SAR, EGP
- Automatic conversion to USD for calculations
- Exchange rates currently estimated (backend should provide real-time rates via API)

---

## 7. Sample Response (minimal)

```json
{
  "theme": {
    "primary_color": "1E66F5",
    "background_color": "FFFFFF",
    "text_color": "0B1220",
    "muted_text_color": "6B7280"
  },
  "splash": {
    "logo_url": "https://example.com/logo.png",
    "title_en": "Zayer",
    "title_ar": "زير",
    "subtitle_en": "Shop globally, delivered locally",
    "subtitle_ar": "تسوق عالميًا، توصيل محلي"
  },
  "onboarding": [
    {
      "image_url": "https://example.com/onboard1.png",
      "title_en": "Shop from Global Stores",
      "title_ar": "تسوق من متاجر العالم",
      "description_en": "Access millions of products...",
      "description_ar": "الوصول إلى ملايين المنتجات..."
    }
  ]
}
```
