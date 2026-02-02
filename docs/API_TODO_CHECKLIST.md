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

- [ ] **`POST /api/product-import/preview`** — Accept product URL, return metadata (name, price, store, image, weight, dimensions). Request: `{ "url": "https://..." }`. Response: `{ "name", "price", "store_name", "country", "image_url", "weight", "dimensions", "canonical_url" }` or error. Backend should normalize URLs and return `canonical_url` in the preview response.
- [ ] **`GET /api/stores/supported`** — List supported stores for Paste Link (whitelist).
- [ ] **`POST /api/cart/items`** — Add item to cart (from auto-filled or manual entry). Request: `{ "url", "name", "price", "quantity", "store_id", "image_url?", "weight?", "dimensions?" }`.

---

## Phase 4: Stores / WebView & Import Pipeline

- [ ] **`GET /api/home`** — Home dashboard (promos, markets, popular_stores). **`GET /api/stores`** — Stores list. **`GET /api/stores/{id}`** — Store landing. **Stores list:** e.g. `GET /api/stores` for Home “Markets / Stores”.
- [ ] **WebView rules:** See `docs/WEBVIEW_IMPORT_RULES.md` for planned store URL rules, PDP detection, and “Add to Zayer Cart” import pipeline (high level).

---

## Phase 5: Caching & Offline (optional)

- [ ] **Config version/ETag:** Support cache headers or `version` in bootstrap config to avoid unnecessary refetches.
- [ ] **Offline fallback:** Use last successful bootstrap config when offline and show banner or retry when back online.

---

## Notes

- Keep **snake_case** in API JSON to match Laravel and existing models.
- All admin-controlled content (splash, onboarding, theme) must remain config-driven; no hardcoded marketing copy in the app except fallbacks on API failure.
