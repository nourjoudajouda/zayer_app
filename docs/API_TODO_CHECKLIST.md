# API TODO Checklist

Phases for replacing mock data with real Laravel (or other) backend APIs.

---

## Phase 1: Bootstrap / Remote Config

- [ ] **Endpoint:** `GET /api/bootstrap-config` (or equivalent). See `ADMIN_REMOTE_CONFIG.md` for schema.
- [ ] **Response shape:** `{ "theme", "splash", "onboarding", "home", "stores" }` — home includes `promo_carousel`, `markets`, `popular_stores`.
- [ ] **Response:** JSON matching `docs/ADMIN_REMOTE_CONFIG.md` (theme, splash, onboarding; snake_case).
- [ ] **Replace mock:** In `lib/core/config/app_config_repository.dart`:
  - Add `AppConfigRepositoryApi implements AppConfigRepository` using Dio.
  - Call `dio.get<Map<String, dynamic>>('/api/bootstrap-config')`, then `AppBootstrapConfig.fromJson(response.data!)`.
  - Wire repository in `app_config_provider.dart` (e.g. via a provider or env flag) so the app uses API instead of mock.
- [ ] **Error handling:** Map HTTP/network errors to user-friendly message; keep Retry and fallback config behavior.

---

## Phase 2: Auth (when needed)

### Endpoints

| Method | Endpoint | Description | Payload example |
|--------|----------|-------------|-----------------|
| POST | `/auth/register` | Create account | `{ "full_name", "phone", "country_code", "country", "city", "password" }` |
| POST | `/auth/login` | Login with phone + password | `{ "phone", "password" }` |
| POST | `/auth/request-otp` | Send OTP to phone | `{ "phone", "country_code" }` |
| POST | `/auth/verify-otp` | Verify OTP and get token | `{ "phone", "otp" }` |
| POST | `/auth/reset-password` | Request reset code (forgot password) | `{ "phone", "country_code" }` |
| POST | `/auth/confirm-reset` | Confirm reset with code + new password | `{ "phone", "otp", "new_password" }` |
| POST | `/auth/social` | Apple/Google sign-in (optional) | `{ "provider", "id_token" }` |
| GET | `/countries` | List countries for dropdown | `[]` or `{ "items": [...] }` |
| GET | `/cities?country=XX` | List cities by country | `?country=US` |

### Validations

- Phone: required, valid format per country.
- Password: min 8 chars, at least one number, one special char (match register requirements).
- OTP: 6 digits.

### Other

- [ ] **Token storage:** Secure storage for auth token; attach to Dio interceptors.
- [ ] **Logout / session expiry:** Clear token and redirect to login/register as needed.

---

## Phase 3: User & Profile

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/me` | User profile |
| PATCH | `/api/me` | Update name, dob |
| POST | `/api/me/avatar` | Upload avatar image |
| GET | `/api/me/compliance` | KYC status, expiry, actionRequired |
| GET | `/api/me/address` | Default shipping address |
| POST | `/api/logout` | Logout |
| DELETE | `/api/me` | Delete account |

### Request / Response Examples (snake_case)

**GET /api/me** response:
```json
{
  "display_name": "Hazem",
  "verified": true,
  "last_verified_at": "2025-01-15",
  "full_legal_name": "Hazem Al-Masri",
  "date_of_birth": "1990-01-01",
  "avatar_url": "https://...",
  "primary_address": "123 Main Street, Apt 4B\nNew York, NY 10001",
  "primary_address_country": "United States",
  "is_default": true,
  "is_address_locked": false
}
```

**PATCH /api/me** request:
```json
{ "full_legal_name": "...", "date_of_birth": "..." }
```

**POST /api/me/avatar** request: `multipart/form-data` with `avatar` file field. Response: `{ "avatar_url": "https://..." }`.

**GET /api/me/compliance** response:
```json
{
  "action_required": true,
  "expiry_date": "2026-03-01",
  "description": "Your government-issued ID is required..."
}
```

**GET /api/me/address** response:
```json
{
  "address": "123 Main Street...",
  "country": "United States",
  "is_default": true,
  "is_locked": false
}
```

- [ ] **Sync with locale:** Optionally persist language preference (EN/AR) on backend.

---

## Phase 3.5: Markets

- [ ] **`GET /api/markets`** — Countries list for filter chips. Response: `{ "countries": [ { "code", "name", "flag_emoji" } ] }`.
- [ ] **`GET /api/stores?country=US&featured=1`** — Stores list, optional country and featured filters.
- [ ] **`GET /api/stores/:id`** — Store details for landing page.

---

## Phase 3.6: Paste Product Link / Product Import

- [ ] **`POST /api/product-import/preview`** — Accept product URL, return metadata (name, price, store, image, weight, dimensions). Request: `{ "url": "https://..." }`. Response: `{ "name", "price", "currency", "store_name", "store_key", "country", "image_url", "weight", "dimensions", "canonical_url", "product_id" }` or error. Backend should normalize URLs and return `canonical_url` in the preview response.
- [ ] **`GET /api/stores/supported`** — List supported stores for Paste Link (whitelist). Response should include store keys: `["amazon", "ebay", "walmart", "etsy", "aliexpress"]`.
- [ ] **`POST /api/cart/items`** — Add item to cart (from auto-filled or manual entry). Request: `{ "url", "canonical_url", "name", "price", "currency", "quantity", "store_id", "store_key", "image_url?", "product_id?", "weight?", "dimensions?" }`.
- [ ] **`GET /api/exchange-rates`** — Get current exchange rates for currency conversion. Response: `{ "rates": { "USD": 1.0, "EUR": 1.08, "GBP": 1.27, "ILS": 0.27, ... }, "last_updated": "2026-02-20T10:00:00Z" }`. Used for converting non-USD prices to USD for calculations.

---

## Phase 3.7: Favorites, Notifications, Orders, Cart (Empty-State Screens → API)

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/favorites` | List user's favorite products. |
| POST | `/api/favorites` | Add or remove favorite (payload: `product_id`, `action`: add/remove). |
| GET | `/api/notifications` | List user's notifications. |
| DELETE | `/api/notifications` | Clear all notifications. |
| GET | `/api/orders` | List user's orders. |
| GET | `/api/cart` | List cart items. |
| POST | `/api/cart/items` | Add item via link or manual entry (see Phase 3.6). |

---

## Phase 3.8: Settings, Notification Preferences, Orders List, Checkout Review & Pay

Screens: Settings & Preferences, Advanced Notification Control, Orders list, Review & Pay. Mock data in app; replace with API below.

### Settings & Preferences

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/me/settings` | User settings (language, currency, warehouse, smart_consolidation, auto_insurance, notification_summary, server_region). |
| PATCH | `/api/me/settings` | Update settings (toggles, selected currency, warehouse). |

### Notification Preferences

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/me/notification-preferences` | Notification channels (push, email, order_updates, shipment_updates, customs_compliance, payment_reminders, promotions) and quiet_hours (from, to). |
| PATCH | `/api/me/notification-preferences` | Save preferences (same shape). |

### Orders List

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/orders` | List user orders. Query: `?status=all|in_progress|delivered|cancelled`. Response: array of order objects (id, origin, status, order_number, placed_date, delivered_on, total_amount, refund_status, estimated_delivery, etc.). |

### Checkout Review & Confirm

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/checkout/review` | Review payload: shipping_address, consolidation_savings, shipments (origin_label, items with name, price, quantity, eta), wallet_balance, price_breakdown (subtotal, shipping, insurance), total. |
| POST | `/api/checkout/confirm` | Confirm & pay. Payload: use_wallet_balance, promo_code (optional). Response: success or error. |

---

## Phase 4: Stores / WebView & Import Pipeline ✅ PARTIALLY IMPLEMENTED

- [ ] **`GET /api/home`** — Home dashboard (promos, markets, popular_stores). **`GET /api/stores`** — Stores list. **`GET /api/stores/{id}`** — Store landing. **Stores list:** e.g. `GET /api/stores` for Home "Markets / Stores".
- ✅ **WebView rules:** See `docs/WEBVIEW_IMPORT_RULES.md` and `docs/PRODUCT_EXTRACTION_IMPLEMENTATION.md` for implemented store URL rules, PDP detection, and product extraction.
- [ ] **`POST /api/products/import`** — Import product from WebView extraction. Request: `{ "store_key": "amazon", "product_url": "https://...", "canonical_url": "https://...", "title": "...", "price": 99.99, "currency": "USD", "image_url": "...", "product_id": "B08XYZ" }`. Response: `{ "success": true, "product_id": "zayer_product_123", "cart_item_id": "cart_item_456" }`.
- [ ] **`GET /api/stores/{id}/pdp-rules`** — Get PDP detection rules for a store. Response: `{ "url_patterns": ["/dp/", "/gp/product/"], "exclude_patterns": ["/s?", "/gp/bestsellers"] }`.
- [ ] **`GET /api/exchange-rates`** — Get current exchange rates for currency conversion. Response: `{ "rates": { "USD": 1.0, "EUR": 1.08, "GBP": 1.27, "ILS": 0.27, "AED": 0.27, "SAR": 0.27, "EGP": 0.032 }, "last_updated": "2026-02-20T10:00:00Z" }`. Used for converting non-USD prices to USD for calculations. **Priority: HIGH** - Currently using estimated rates.

**Current Status:**
- ✅ Client-side product extraction implemented and working
- ✅ Multi-store support (Amazon, eBay, Walmart, Etsy, AliExpress)
- ✅ Currency detection and conversion (estimated rates)
- ⏳ Backend API endpoints pending

---

## Phase 5: Caching & Offline (optional)

- [ ] **Config version/ETag:** Support cache headers or `version` in bootstrap config to avoid unnecessary refetches.
- [ ] **Offline fallback:** Use last successful bootstrap config when offline and show banner or retry when back online.

---

## Notes

- Keep **snake_case** in API JSON to match Laravel and existing models.
- All admin-controlled content (splash, onboarding, theme) must remain config-driven; no hardcoded marketing copy in the app except fallbacks on API failure.
- **Product Extraction:** Client-side extraction is implemented; backend should validate and sanitize all product data before saving.
