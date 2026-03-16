# API Contract Audit — Flutter (Eshterely)

**Scope:** Flutter app only. No backend code changes.  
**Purpose:** Document exactly what the app expects from the backend for API usage, models, routes, payloads, and status values.  
**Date:** 2025-03-16.

---

## 1. All API Calls Used by Flutter

| # | Area | Method | Endpoint | Flutter Location |
|---|------|--------|----------|------------------|
| 1 | Auth | POST | `/api/auth/register` | `auth_repository.dart` |
| 2 | Auth | POST | `/api/auth/login` | `auth_repository.dart` |
| 3 | Auth | POST | `/api/auth/verify-otp` | `auth_repository.dart` |
| 4 | Auth | POST | `/api/auth/forgot-password` | `auth_repository.dart` |
| 5 | Auth | POST | `/api/auth/logout` | `auth_repository.dart` |
| 6 | Auth | GET | `/api/countries` | `auth_repository.dart` |
| 7 | Auth | GET | `/api/cities` | `auth_repository.dart` |
| 8 | Profile | GET | `/api/me` | `profile_repository_impl.dart` |
| 9 | Profile | PATCH | `/api/me` | `profile_repository_impl.dart` |
| 10 | Profile | POST | `/api/me/avatar` | `profile_repository_impl.dart` |
| 11 | Profile | GET | `/api/me/compliance` | `profile_repository_impl.dart` |
| 12 | Addresses | GET | `/api/me/addresses` | `address_repository_impl.dart` |
| 13 | Addresses | POST | `/api/me/addresses` | `address_repository_impl.dart` |
| 14 | Addresses | PATCH | `/api/me/addresses/{id}` | `address_repository_impl.dart` |
| 15 | Addresses | POST | `/api/me/addresses/{addressId}/default` | `address_repository_impl.dart` |
| 16 | FCM | PATCH | `/api/me/fcm-token` | `auth_repository.dart` |
| 17 | Config | GET | `/api/config/bootstrap` | `app_config_repository.dart` |
| 18 | Product import | POST | `/api/products/import-from-url` | `product_link_import_repository_api.dart` |
| 19 | Cart | GET | `/api/cart/items` | `cart_repository.dart` |
| 20 | Cart | POST | `/api/cart/items` | `cart_repository.dart` |
| 21 | Cart | PATCH | `/api/cart/items/{id}` | `cart_repository.dart` |
| 22 | Cart | DELETE | `/api/cart/items/{id}` | `cart_repository.dart` |
| 23 | Cart | DELETE | `/api/cart` | `cart_repository.dart` |
| 24 | Checkout | GET | `/api/checkout/review` | `checkout_review_providers.dart` |
| 25 | Checkout | POST | `/api/checkout/confirm` | `checkout_review_providers.dart` |
| 26 | Payment | POST | `/api/orders/{orderId}/pay` | `checkout_review_providers.dart` |
| 27 | Orders | GET | `/api/orders` | `orders_providers.dart` |
| 28 | Orders | GET | `/api/orders/{id}` | `orders_providers.dart` |
| 29 | Favorites | GET | `/api/favorites` | `favorites_providers.dart` |
| 30 | Favorites | POST | `/api/favorites` | `store_webview_screen.dart` |
| 31 | Favorites | DELETE | `/api/favorites/{id}` | `favorites_screen.dart` |
| 32 | Wallet | GET | `/api/wallet` | `wallet_providers.dart` |
| 33 | Wallet | GET | `/api/wallet/activity` | `wallet_providers.dart` |
| 34 | Wallet | POST | `/api/wallet/top-up` | `top_up_wallet_screen.dart` |
| 35 | Notifications | GET | `/api/notifications` | `notifications_repository.dart` |
| 36 | Notifications | PATCH | (see below) | `notifications_repository.dart` |
| 37 | Notification prefs | GET | `/api/me/notification-preferences` | `notification_prefs_providers.dart` |
| 38 | Settings | GET | `/api/me/settings` | `settings_providers.dart` |
| 39 | Settings | GET | `/api/warehouses` | `settings_providers.dart` |
| 40 | Sessions | GET | `/api/me/sessions` | `active_sessions_screen.dart` |

**Note:** There is **no** dedicated “shipping quote”, “confirm product”, or “draft order” API. Confirm Product screen uses mock shipping/duties; checkout review can come from GET `/api/checkout/review` or from a cart-built fallback.

---

## 2. Expected Request/Response Contracts

### 2.1 Auth

- **POST `/api/auth/register`**  
  - **Body:** `full_name`, `phone`, `password`, `password_confirmation`, optional `country_id`, `city_id`.  
  - **Success (201):** `phone` (string), optional `user_id` (int), optional `otp`/`code` (dev only).  
  - **Error:** `message` (string) or `errors` (map of field → list of strings).  
  - **Flutter:** Returns `AuthRequiresOtp(phone, userId, mode: 'signup')` or `AuthFailure(message)`.

- **POST `/api/auth/login`**  
  - **Body:** `phone`, `password`, optional `fcm_token`, optional `device_type` (`web`|`android`|`ios`).  
  - **Success (200):** `token` (string).  
  - **Error:** same as above.  
  - **Flutter:** Saves token, returns `AuthSuccess(token)` or `AuthFailure`.

- **POST `/api/auth/verify-otp`**  
  - **Body:** `phone`, `code`, `mode` (`signup`|`reset`), optional `password`/`password_confirmation` when `mode == 'reset'`, optional `fcm_token`, `device_type`.  
  - **Success (200):** `token` (string).  
  - **Error:** same.  
  - **Flutter:** Saves token, returns `AuthSuccess` or `AuthFailure`.

- **POST `/api/auth/forgot-password`**  
  - **Body:** `phone`.  
  - **Success (200):** `phone`, optional `otp`/`code` (dev).  
  - **Flutter:** Returns `AuthRequiresOtp(phone, mode: 'reset')` or `AuthFailure`.

- **POST `/api/auth/logout`**  
  - **Body:** none (auth via Bearer).  
  - **Flutter:** Clears token locally; errors are swallowed.

- **GET `/api/countries`**  
  - **Response:** JSON array of objects.  
  - **Fields per item:** `id` or `code`, `name`, optional `flag_emoji`, `dial_code`.  
  - **Model:** `CountryItem` (`country_city.dart`).

- **GET `/api/cities`**  
  - **Query:** `country_id` and/or `country_code`.  
  - **Response:** JSON array. Per item: `id` or `code`, `name`.  
  - **Model:** `CityItem` (`country_city.dart`).

### 2.2 FCM token

- **PATCH `/api/me/fcm-token`**  
  - **Body:** `fcm_token` (string), `device_type` (string).  
  - **Flutter:** Best-effort; errors are swallowed. Called from app startup and main shell (token refresh).  
  - **Duplicate flow:** Token is also sent in **login** and **verify-otp** bodies. Backend should treat PATCH as upsert; avoid double-registration or conflicting semantics.

### 2.3 Profile

- **GET `/api/me`**  
  - **Response:** `display_name` or `name`, `full_legal_name` or `full_name`, `verified`, `last_verified_at`, `date_of_birth`, `primary_address`, `primary_address_country`, `is_default`, `is_address_locked`, `avatar_url`.  
  - **Model:** `UserProfile` (`user_profile_model.dart`).

- **PATCH `/api/me`**  
  - **Body:** optional `full_legal_name`, `display_name`, `date_of_birth`.  
  - **Flutter:** Then refetches profile via GET `/api/me`.

- **POST `/api/me/avatar`**  
  - **Body:** `multipart/form-data`, field `avatar` (file).  
  - **Flutter:** No response shape required; UI refetches profile.

- **GET `/api/me/compliance`**  
  - **Response:** `action_required` (bool), optional `expiry_date`, `description`.  
  - **Model:** `ComplianceStatus` (`user_profile_model.dart`).

### 2.4 Addresses

- **GET `/api/me/addresses`**  
  - **Response:** Array of address objects.  
  - **Fields:** `id`, `address_line`, `country_id`, `country_name`, `city_id`, `city_name`, `phone`, `is_default`, `nickname`, `address_type` (`home`|`office`|`other`), `area_district`, `street_address`, `building_villa_suite`, `is_verified`, `is_residential`, `linked_to_active_order`, `is_locked`, `lat`, `lng`.  
  - **Model:** `Address` (`address_model.dart`, `_addressFromJson`).

- **POST `/api/me/addresses`**  
  - **Body:** `country_id`, `country_name`, `city_id`, `city_name`, `address_line`, `street_address`, `area_district`, `building_villa_suite`, `phone`, `is_default`, `nickname`, `address_type`, optional `lat`, `lng`.

- **PATCH `/api/me/addresses/{id}`**  
  - **Body:** same as POST (without id in body).

- **POST `/api/me/addresses/{addressId}/default`**  
  - **Body:** none.  
  - **Flutter:** No response shape required.

### 2.5 Config

- **GET `/api/config/bootstrap`**  
  - **Response:** `theme` (primary_color, background_color, text_color, muted_text_color), `splash` (logo_url, title_en/ar, subtitle_en/ar, progress_text_en/ar), `onboarding` (array of image_url, title_en/ar, description_en/ar), `markets` (title, subtitle, countries, featured_stores), `promo_banners`, `api_base_url`, `development_mode`, `app_name`, `app_icon_url`.  
  - **Model:** `AppBootstrapConfig` (`app_bootstrap_config.dart`).  
  - **Note:** Can be called before auth; base URL may be overridden and persisted from `api_base_url`.

### 2.6 Product import

- **POST `/api/products/import-from-url`**  
  - **Body:** `url` (string, canonical product URL).  
  - **Success response:** `name`, `price` (number), `store_name`, `country`, `image_url`, `canonical_url`, optional `variations` (array).  
  - **Variation item:** `type` or `label`, `options` (list of strings), optional `prices` (list of numbers).  
  - **Models:** `ProductImportResult`, `ProductVariation` (`product_import_result.dart`, `product_variation.dart`).  
  - **Flutter:** Throws if no product data; variations parsed with fallbacks.

### 2.7 Cart

- **GET `/api/cart/items`**  
  - **Response:** Array of cart item objects.  
  - **Fields:** `id` (required for updates/deletes), `url` or `product_url`/`productUrl`, `name`, `price` or `unit_price`/`unitPrice`, `quantity`, `currency`, `image_url`, `store_key`, `store_name`, `product_id`, `country`, `source`, `review_status` (`pending_review`|`reviewed`|`rejected`), `shipping_cost`, `variation_text`, dimensions/weight fields.  
  - **Model:** `CartItem` (`cart_item_model.dart`). **Risk:** `id` and `name` are cast as non-null String; missing `id` can cause parse issues (see §5).

- **POST `/api/cart/items`**  
  - **Body:** `url`, `name`, `price`, `quantity`, `currency`, optional `image_url`, `store_key`, `store_name`, `product_id`, `country`, `source`, optional `variation_text`, `weight`, `weight_unit`, `length`, `width`, `height`, `dimension_unit`.  
  - **Expected success (201):** Object with at least `id` (used as string for subsequent PATCH/DELETE). Other fields same as cart item.  
  - **Flutter:** Appends to local list using response; if backend omits `id`, app now falls back to a generated id (minimal fix applied).

- **PATCH `/api/cart/items/{id}`**  
  - **Body:** `quantity` (int).  
  - **Flutter:** Updates local list by id.

- **DELETE `/api/cart/items/{id}`**, **DELETE `/api/cart`**  
  - **Flutter:** No response shape required.

### 2.8 Checkout

- **GET `/api/checkout/review`**  
  - **Response:** `shipping_address_short`, `consolidation_savings`, `wallet_balance_enabled`, `wallet_balance`, `subtotal`, `shipping`, `insurance`, `total`, `shipments` (array).  
  - **Shipment:** `origin_label`, `reviewed`, `items` (array of `name`, `price`, `quantity`, `eta`, `image_url`, `reviewed`, `shipping_cost`).  
  - **Model:** `CheckoutReviewModel` (`checkout_review_model.dart`).  
  - **Flutter:** If `shipping_address_short` is empty, app fills from profile/addresses.

- **POST `/api/checkout/confirm`**  
  - **Body:** `use_wallet_balance` (bool).  
  - **Success (201):** `order_id`, `order_number` (both used as strings).  
  - **Flutter:** Uses these to navigate to payment or order detail.

- **POST `/api/orders/{orderId}/pay`**  
  - **Body:** none (or empty).  
  - **Success (200/201):** `payment_id` (int or string), `reference`, `checkout_url` (string), `status`.  
  - **Model:** `PaymentStartResponse` (`payment_start_response.dart`).  
  - **Flutter:** Opens `checkout_url` in WebView; treats missing/empty `checkout_url` as error.

### 2.9 Orders

- **GET `/api/orders`**  
  - **Response:** Array of order objects.  
  - **Fields:** `id`, `order_number`, `origin` (`multi_origin`|`turkey`|`usa`), `status` (§3), `placed_date`, `delivered_on`, `total_amount`, `refund_status`, `estimated_delivery`, `shipping_address`, `shipments` (array).  
  - **Shipment:** `id`, `country_code`, `country_label`, `shipping_method`, `eta`, `items`, `tracking_events`, `subtotal`, `shipping_fee`, `customs_duties`.  
  - **Item:** `id`, `name`, `store_name`, `sku`, `price`, `quantity`, `image_url`.  
  - **Tracking event:** `title`, `subtitle`, `is_highlighted`.  
  - **Model:** `OrderModel` (`order_model.dart`).  
  - **Note:** Flutter does **not** parse `price_lines`, `consolidation_savings`, `payment_method_label`, `invoice_issue_date`, `transaction_id` from list/detail; backend can send them for future use.

- **GET `/api/orders/{id}`**  
  - **Response:** Same shape as single order object above.  
  - **Flutter:** Same `OrderModel.fromJson`; fallback to list cache if request fails.

### 2.10 Favorites

- **GET `/api/favorites`**  
  - **Response:** Array. Per item: `id`, `source_key`, `source_label`, `title`, `price`, `currency`, `price_drop`, `tracking_on`, `stock_status` (`in_stock`|`low_stock`|`out_of_stock`), `stock_label`, `image_url`.  
  - **Model:** `FavoriteItem` (`favorite_item.dart`).

- **POST `/api/favorites`**  
  - **Body:** `source_key`, `source_label`, `title`, `price`, `currency`, `image_url`, `product_url`.  
  - **Flutter:** No response shape required; invalidates list.

- **DELETE `/api/favorites/{id}`**  
  - **Flutter:** No response shape required; invalidates list.

### 2.11 Wallet

- **GET `/api/wallet`**  
  - **Response:** `available`, `pending`, `promo` (numbers).  
  - **Model:** `WalletBalance` (`wallet_model.dart`).

- **GET `/api/wallet/activity`**  
  - **Response:** Array. Per item: `id`, `type` (`payment`|`payments`|`refund`|`refunds`|else top-ups), `title`, `date_time`, `amount`, `subtitle`, `is_credit`.  
  - **Model:** `WalletTransaction` (`wallet_model.dart`).

- **POST `/api/wallet/top-up`**  
  - **Body:** `amount` (number).  
  - **Flutter:** No response shape required; invalidates balance and activity.

### 2.12 Notifications

- **GET `/api/notifications`**  
  - **Response:** Array. Per item: `id`, `type`, `title`, `subtitle`, `time_ago`, `read`, `important`, `action_label`, `action_route`.  
  - **Model:** `NotificationItem` (`notification_item.dart`).  
  - **Flutter:** Drops items with empty `id`.

- **Mark read (single):** App tries in order until one succeeds (2xx):  
  - `PATCH /api/notifications/{id}/read` (no body)  
  - `PATCH /api/notifications/{id}/mark-read` (no body)  
  - `PATCH /api/notifications/{id}` with body `{ "read": true }`  
  - **Flutter:** Best-effort; errors swallowed.

- **Mark all read:** App tries until one succeeds:  
  - `PATCH /api/notifications/mark-all-read`  
  - `PATCH /api/notifications/read-all`  
  - `PATCH /api/notifications/mark_read_all`  
  - **Flutter:** Best-effort; no body.

### 2.13 Notification preferences

- **GET `/api/me/notification-preferences`**  
  - **Response:** `push_enabled`, `email_enabled`, `sms_enabled`, `live_status_updates`, `quiet_hours_enabled`, `quiet_hours_from`, `quiet_hours_to` (strings like `22:00`, `07:00`).  
  - **Model:** `NotificationPrefsModel` (`notification_prefs_model.dart`).  
  - **Note:** Flutter does not persist PATCH for prefs in this audit; UI has toggles that could be wired later.

### 2.14 Settings & warehouses

- **GET `/api/me/settings`**  
  - **Response:** `language_code`, `language_label`, `currency_code`, `currency_symbol`, `default_warehouse_id`, `default_warehouse_label`, `smart_consolidation_enabled`, `auto_insurance_enabled`.  
  - **Model:** `AppSettingsModel` (in `settings_providers.dart`).

- **GET `/api/warehouses`**  
  - **Response:** Array of `{ "id": string, "label": string }`.  
  - **Flutter:** Skips items with empty `id`.

### 2.15 Sessions

- **GET `/api/me/sessions`**  
  - **Response:** Array. Per item: (model expects fields suitable for “active sessions” list; exact keys not fully defined in a single model file; screen uses list for display).  
  - **Flutter:** `active_sessions_screen.dart` uses raw list.

### 2.16 Error response shape (global)

- **Expected:** JSON with `message` (string) and/or `errors` (map: field → list of strings).  
- **Auth 401:** App clears token and can redirect to login.  
- **Flutter:** `_extractMessage` in auth, `_messageFromResponse` in checkout; first error from `errors` or `message` used as user-facing text.

---

## 3. Status Values Expected by Flutter

### 3.1 Order status

- **Values:** `in_transit` (or any unrecognized → mapped to in-transit), `delivered`, `cancelled`.  
- **Source:** `OrderModel._statusFrom` in `order_model.dart`.  
- **Risk:** If backend uses e.g. `pending`, `processing`, `shipped`, they are all treated as “in transit”.

### 3.2 Order origin

- **Values:** `multi_origin`, `turkey`, `usa`.  
- **Source:** `OrderModel._originFrom`.  
- **Default:** Unrecognized → `usa`.

### 3.3 Cart item review status

- **Values:** `pending_review`, `reviewed`, `rejected`.  
- **Source:** `CartItem.fromJson` / `CartItemReviewStatus` in `cart_item_model.dart`.

### 3.4 Notification type (list)

- **Values:** Normalized from `type` / `category`: `orders`|`order`|`order_update`|`payment_update` → orders; `shipments`|`shipment`|`shipment_update`|`tracking_update` → shipments; `promo`|`promotion` → promo; else heuristic (contains “ship”/“track” → shipments, “promo”/“offer” → promo, else orders).  
- **Source:** `NotificationItem.fromJson` in `notification_item.dart`.

### 3.5 Favorite stock status

- **Values:** `in_stock`, `low_stock`, `out_of_stock`.  
- **Source:** `FavoriteItem.fromJson` in `favorite_item.dart`.

### 3.6 Wallet activity type

- **Values:** `payment`|`payments`, `refund`|`refunds`, else treated as top-ups.  
- **Source:** `wallet_providers.dart`.

### 3.7 Address type

- **Values:** `home`, `office`, `other`.  
- **Source:** `address_repository_impl.dart` (`_addressFromJson`, `_addressTypeToString`).

### 3.8 Payment start response

- **Flutter only uses `checkout_url` and `status` (string);** no enum. Backend can use any status string; app does not branch on it beyond having a non-empty checkout URL.

---

## 4. Notification (FCM) Payload Expectations

- **Source:** `AppNotificationPayload` in `notification_payload.dart`; routing in `notification_route_mapper.dart`.  
- **Data payload keys (snake_case preferred):**  
  - `target_type` — e.g. `order`, `support_ticket`, `wallet`, `shipment`, `payment`.  
  - `target_id` — e.g. order id, ticket id.  
  - `route_key` — preferred for routing; see list below.  
  - `notification_id` or `notificationId` or `id` — for read-state sync.  
  - `meta` or `payload` — optional map for screen context (e.g. `meta.screen == 'tracking'` for order opens tracking).  
- **Flutter does not require:** `type` or `reference_id` at top level for navigation; `target_type` + `target_id` or `route_key` drive navigation.

### 4.1 Route keys supported for deep links

- **Order:** `order_detail`, `order-detail`, `order_tracking`, `order-tracking`, `tracking`, `order_invoice`, `order-invoice`, `payment`, `payment_status`, `order_payment`, `orders`.  
- **Support:** `support_ticket`, `support-ticket`, `support_ticket_chat`, `support_inbox`.  
- **Wallet:** `wallet`.  
- **Notifications:** `notifications`, `notification_list`.  
- **Target types (when no route_key):** `order`, `support_ticket`/`support`, `wallet`, `payment`, `shipment`, `notification`/`notifications`.  
- **Fallback:** If no match, app opens notifications list.  
- **Risk:** Backend must send one of these `route_key` or `target_type` values for correct in-app navigation; otherwise user lands on notifications list.

---

## 5. Mismatches or Risks

1. **Cart GET/POST and `id`/`name`:**  
   - `CartItem.fromJson` uses `id: json['id'] as String` and `name: json['name'] as String`. If backend returns numeric `id` or omits `id`/`name`, parsing can throw.  
   - **Fix applied:** POST add-item response: if backend omits `id`, app now uses `generateCartItemId()` so the added item has a valid id. GET response items with missing `id` are still a risk (consider backend always returning `id` or Flutter relaxing to `(json['id']?.toString() ?? '')` and similar for `name`).

2. **Order status set is small:**  
   - Only `delivered`, `cancelled`, and default “in transit”. Statuses like `pending`, `processing`, `paid`, `shipped` are all shown as “in transit”. Backend may need to map to these three or Flutter extended.

3. **Notification mark-read endpoints:**  
   - App tries three different single-read and three different mark-all-read paths. Backend should implement at least one of each set to avoid silent no-op.

4. **FCM token sent in three places:**  
   - Login body, verify-otp body, and PATCH `/api/me/fcm-token`. Risk of duplicate or conflicting registration; backend should define single source of truth (e.g. PATCH as upsert, login/verify only when no token stored).

5. **Checkout review fallback:**  
   - If GET `/api/checkout/review` fails, Flutter builds review from cart + profile/addresses with hardcoded insurance/consolidation/wallet. Totals may not match backend if backend uses different rules.

6. **Order model:**  
   - Flutter does not read `price_lines`, `consolidation_savings`, `payment_method_label`, `invoice_issue_date`, `transaction_id` from API. Safe to send; not displayed yet.

7. **Payment start:**  
   - App requires `checkout_url` (non-empty string). If backend returns different key (e.g. `payment_url`) or only a payment id, flow breaks.

8. **Countries/cities:**  
   - Response can be JSON string (decoded to list) or list. Flutter handles both; backend should prefer JSON array.

9. **Deep links:**  
   - All notification deep-link targets (order detail, tracking, invoice, support ticket, wallet) assume routes exist. If backend sends `route_key` or `target_type` not in the mapper, user is sent to notifications list.

10. **Confirm Product / shipping quote:**  
    - No backend call; shipping/duties are mock. Any future “shipping quote” or “confirm product” API would need to be added and wired.

---

## 6. Minimal Fix Applied

- **Cart repository — POST `/api/cart/items` response:**  
  If the backend does not return `id` in the created cart item, `CartItem.fromJson` would receive `id: null` and throw (non-null `String`).  
  **Change:** Use `res.data!['id']?.toString() ?? generateCartItemId()` so the added item always has a string id.  
  **File:** `lib/features/cart/repositories/cart_repository.dart`.

---

## 7. Handoff to Backend

- **Implement at least one of each:**  
  - Single notification read: `PATCH /api/notifications/{id}/read` or `mark-read` or `PATCH /api/notifications/{id}` with `read: true`.  
  - Mark all read: `PATCH /api/notifications/mark-all-read` or `read-all` or `mark_read_all`.

- **Cart:**  
  - Always return `id` (string or number; app converts to string) and `name` in GET `/api/cart/items` and in POST `/api/cart/items` response to avoid parse errors.

- **Orders:**  
  - Use status values `delivered`, `cancelled`, or (for any other state) rely on app mapping to “in transit”. If backend needs more granular UI, agree on either backend mapping or Flutter enum extension.  
  - Use origin values `multi_origin`, `turkey`, `usa`.

- **Payment start:**  
  - Return `checkout_url` (string) in POST `/api/orders/{orderId}/pay`; app ignores other keys for opening WebView.

- **FCM:**  
  - Send `target_type`, `target_id`, and optionally `route_key`, `notification_id`, `meta` in data payload. Use supported `route_key`/`target_type` values (§4.1) for correct deep links.  
  - Prefer one canonical way to register/update FCM token (e.g. PATCH `/api/me/fcm-token`) and document whether login/verify-otp also register token or only create session.

- **Errors:**  
  - Use `message` (string) and/or `errors` (object with array values) for consistent user-facing messages.

- **Bootstrap:**  
  - If admin sets `api_base_url`, ensure it is the base URL (no trailing path) so Flutter can prefix all paths correctly.

This document is the single source of truth for what the Flutter app expects from the backend; use it for reconciliation and API alignment.
