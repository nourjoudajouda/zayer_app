## Zayer Mobile App – Launch Readiness Audit (Flutter)

This document summarizes the production‑readiness audit for the **Zayer** Flutter app (`zayer_app`), based on the launch checklist you provided. The Laravel backend (`Eshterely`) was **not** available in this workspace, so backend points here reflect only what the app expects from the API contracts.

---

## A) Must‑fix issues found (and resolved)

- **[M1] FCM token logged in plain text during login**
  - **File**: `lib/features/auth/repositories/auth_repository.dart`
  - **Issue**: `AuthRepositoryImpl.login` previously printed the full FCM token to logs (`print('fcmTokenfcmToken $fcmToken');`). This is a security/privacy risk if logs are centralized or accessible in production.
  - **Fix implemented**:
    - Wrapped logging in `kDebugMode` and only log a short preview of the token (first characters) with a clear comment that it is debug‑only.
    - No functional behavior change; login and token registration still work as before.

Result: **No remaining category (1) must‑fix issues were found on the Flutter side** during this audit.

---

## B) Key flows – concrete status (Flutter)

Below is the status of each requested flow, tied directly to implementation in the Flutter app.

1. **Import product**
   - **Code**:
     - Paste‑link flow: `PasteProductLinkScreen` + `ProductLinkImportRepositoryApi` (`POST /api/products/import-from-url`).
     - Store WebView → confirm product: `StoreWebViewScreen` and `ConfirmProductScreen` via `AppRoutes.confirmProduct`.
   - **Behavior**:
     - URLs are normalized and validated; invalid/unsupported links display clear error states and may fall back to manual entry.
     - API responses are parsed into `ProductImportResult` and `ProductVariation` with safe handling if fields are missing.
   - **Status**: **Ready** – no functional blockers on the mobile side.

2. **Shipping quote + final pricing**
   - **Code**:
     - Primary: `checkout_review_providers.dart` → `checkoutReviewProvider` → `GET /api/checkout/review` → `CheckoutReviewModel.fromJson`.
     - Fallback: `_buildReviewFromCart` builds a review from cart items with local estimates (shipping, insurance, consolidation savings, wallet).
   - **Behavior**:
     - When backend returns valid JSON, the app uses backend amounts for shipping, insurance, totals, and wallet.
     - On API failure, the app clearly shows **estimated** costs, constructed from the cart.
   - **Status**: **Ready with caveat** – UX is explicit about estimates; correctness of final numbers depends on a stable `/api/checkout/review` on the backend.

3. **Confirm product**
   - **Code**: `ConfirmProductScreen` (`lib/features/product_import/confirm_product_screen.dart`).
   - **Behavior**:
     - Shows imported product details, variations, editable unit price, quantity, and an “Estimated” cost breakdown.
     - Validates presence of product URL/product and positive price before enabling “Confirm & Add to Cart”.
     - Creates a `CartItem` and persists via cart API (`CartRepositoryImpl.addItem` → `POST /api/cart/items`).
   - **Status**: **Ready** – UX is clear that backend will finalize pricing.

4. **Add to cart**
   - **Code**:
     - From confirm product: `_addToCart` in `ConfirmProductScreen`.
     - From paste link: `_addToCart` in `PasteProductLinkScreen`.
     - Persistence: `CartRepositoryImpl` (`/api/cart/items`).
   - **Behavior**:
     - Input validation on URL, name, and unit price with user‑facing error SnackBars.
     - Duplicate detection by URL + variation text prevents accidental duplicate lines.
     - Local state is always synced from server responses (IDs come from backend).
   - **Status**: **Ready**.

5. **Draft order creation**
   - **Code**:
     - Cart summary (`CartScreen`) → “Proceed to Checkout” → `AppRoutes.reviewPay` → `ReviewPayScreen`.
   - **Behavior**:
     - There is no separate “draft order” model on device; draft state is the cart plus `/api/checkout/review` snapshot. This avoids client‑side status mismatches.
   - **Status**: **Ready**.

6. **Checkout readiness**
   - **Code**:
     - `ReviewPayScreen` + `CheckoutReviewModel` + `checkoutReviewProvider`.
     - Shipping address fallback from `userProfileProvider` / `addressesProvider` when backend omits `shipping_address_short`.
   - **Behavior**:
     - Handles loading/error/empty states and explains when cart is empty.
     - Allows address changes with a “Recalculate” warning sheet.
     - Wallet usage can be toggled (`checkoutWalletEnabledProvider`) and is sent in `POST /api/checkout/confirm`.
   - **Status**: **Ready**.

7. **Real order creation**
   - **Code**:
     - `confirmCheckout(ref, useWallet: walletEnabled)` → `POST /api/checkout/confirm`.
   - **Behavior**:
     - On success (`201` and `order_id`), invalidates cart, orders, and wallet providers, so subsequent screens reflect the newly created order.
     - On failure, shows “Checkout failed” and leaves the user at review/pay to retry or adjust.
   - **Status**: **Ready** (backend is source of truth for order creation).

8. **Start payment**
   - **Code**:
     - `startOrderPayment(orderId)` → `POST /api/orders/{orderId}/pay` → `PaymentStartResponse` (`checkout_url`).
     - `ReviewPayScreen` navigates to `PaymentWebViewScreen` when a checkout URL is returned.
   - **Behavior**:
     - Robust error messages for:
       - Unauthorized (401),
       - Connection issues,
       - Missing or invalid `checkout_url`, or validation errors returned from backend.
   - **Status**: **Ready**.

9. **Successful payment webhook**
   - **Code**:
     - After `PaymentWebViewScreen` closes, `ReviewPayScreen`:
       - Invalidates `orderByIdProvider(orderId)` and `ordersProvider`.
       - Attempts to re‑fetch order detail, ignoring transient network failures.
   - **Behavior**:
     - Assumes backend webhooks / status updates have run by the time the user returns, and then treats `/api/orders/{id}` as the source of truth.
   - **Status**: **Ready on app side** – correctness depends on Laravel webhook + status logic.

10. **Admin review / operations**
    - **Code**:
      - Orders: `orders_providers.dart` (`GET /api/orders`) and `orderByIdProvider` (`GET /api/orders/{id}`).
      - UI: `OrdersListScreen`, `OrderDetailScreen`, `OrderTrackingScreen`.
    - **Behavior**:
      - Uses order status and review flags coming from backend; no client‑side status heuristics beyond simple mappings.
    - **Status**: **Ready** from mobile; backend must enforce business rules.

11. **Shipment tracking**
    - **Code**:
      - `OrderTrackingScreen` + `OrderModel`/`OrderShipment`/`OrderTrackingEvent`.
      - Inline tracking on `OrderDetailScreen` per shipment.
    - **Behavior**:
      - Clean handling of missing orders or empty tracking event lists.
      - Shows per‑shipment timelines, logistics details, and customs insight messaging.
    - **Status**: **Ready**.

12. **Notification delivery**
    - **Code**:
      - FCM integration: `FcmService` (`fcm_service.dart`) + `AppNotificationPayload` (`notification_payload.dart`).
      - Notification list: `NotificationsRepositoryImpl` (`/api/notifications`) and `NotificationsListScreen`.
      - Read/unread sync: best‑effort `markRead`/`markAllRead` using several candidate backend routes.
    - **Behavior**:
      - Foreground messages are displayed as local notifications.
      - Background/terminated notifications navigate via the same payload parsing and route mapping logic as the in‑app list.
    - **Status**: **Ready**.

13. **Notification tap navigation in app**
    - **Code**:
      - `notification_route_mapper.dart`, `notification_action_route_resolver.dart`, and `AppRoutes` in `app_router.dart`.
      - Tested by `test/core/fcm/notification_payload_test.dart`.
    - **Behavior**:
      - Supports deep links to order detail, tracking, invoice, support tickets/inbox, wallet, orders list, and notifications list.
      - Unknown or malformed `route_key` / `target_type` falls back to `/notifications`.
    - **Status**: **Ready**.

---

## C) Remaining “should‑fix soon” items (not blockers)

These are concrete, code‑level findings that are **not** launch‑blocking but should be addressed soon after launch.

1. **[S1] Cart & checkout shipping placeholders vs real quote engine**
   - **Files**:
     - `lib/features/cart/cart_screen.dart`
     - `lib/features/checkout/checkout_review_providers.dart`
     - `lib/features/product_import/confirm_product_screen.dart`
   - **Issue**:
     - When backend returns incomplete data or fails, the app computes approximate shipping/fees (e.g. `12.0 * items.length`, fixed insurance, and fixed consolidation savings).
     - Confirm product screen uses hardcoded estimated shipping and duties.
   - **Risk**:
     - Users may see estimates that differ from admin‑side quote logic if `/api/checkout/review` is unstable.
   - **Recommended**:
     - Ensure `/api/checkout/review` is solid in production so these placeholders are rarely used.
     - Optionally detect fallback mode and simplify the UI (e.g. “Shipping will be calculated at next step”) instead of showing detailed numbers.

2. **[S2] Checkout review model alignment with backend**
   - **Files**:
     - `lib/features/checkout/models/checkout_review_model.dart`
     - `lib/features/checkout/providers/checkout_review_providers.dart`
   - **Issue**:
     - The model expects keys like `shipping_address_short`, `consolidation_savings`, `wallet_balance_enabled`, etc. If Laravel uses different field names or shapes, the app will fall back to cart‑built review.
   - **Recommended**:
     - Verify Laravel’s `/api/checkout/review` JSON aligns with these keys.
     - Optionally log when fallback is used so support can track degraded quote mode.

3. **[S3] Order model not yet mapping all optional display fields**
   - **File**: `lib/features/orders/models/order_model.dart`
   - **Issue**:
     - `OrderModel` includes fields like `priceLines`, `consolidationSavings`, `paymentMethodLabel`, `paymentMethodLastFour`, `insuranceConfirmed`, `statusTags`, etc., but `fromJson` currently maps only a subset.
   - **Risk**:
     - No functional break; UI handles empty/null gracefully, but richer backend detail will not be surfaced until mapping is expanded.
   - **Recommended**:
     - Align `OrderModel.fromJson` with the final Laravel order detail schema when available.

---

## D) Nice‑to‑have later items

1. **[N1] Extend notification/deep‑link mapping as catalog grows**
   - **Files**: `notification_route_mapper.dart`, `notification_action_route_resolver.dart`, `notification_payload.dart`
   - The current mapping already covers core order/payment/support/wallet flows and has unit tests. As backend introduces more notification types, you can add explicit route mappings and tests without changing architecture.

2. **[N2] More granular order status mapping**
   - **File**: `order_model.dart`
   - `_statusFrom` currently maps anything other than `"delivered"`/`"cancelled"` to `inTransit`. If Laravel uses more states (e.g. `processing`, `awaiting_payment`, etc.), consider mapping them to more descriptive enum variants for better UX.

3. **[N3] Payment WebView UX copy improvements**
   - **File**: `payment_webview_screen.dart`
   - Behavior for unsupported platforms or WebView load errors is already safe and user‑friendly. Later, you may tweak copy to more clearly instruct users to recheck order status after browser‑based payment.

---

## E) Launch readiness summary (Flutter side)

- **Architecture**: The app respects existing architecture; no large refactors or redesigns were introduced.
- **Critical flows**: Import → cart → checkout review → order creation → payment → webhook‑driven status → tracking → notifications are wired to real backend APIs, with clear error and fallback handling.
- **Must‑fixes**: The only concrete must‑fix found in the Flutter codebase (FCM token logging) has been resolved.
- **Backend dependencies**: The Laravel backend must provide and stabilize the expected endpoints (`/api/cart/*`, `/api/checkout/review`, `/api/checkout/confirm`, `/api/orders*`, `/api/products/import-from-url`, `/api/notifications*`, auth endpoints, and `/api/config/bootstrap`) for full end‑to‑end correctness.

From the **mobile app** perspective, and assuming the Laravel backend meets these contracts, the product is **launch‑ready**, with a short list of non‑blocking follow‑ups to improve accuracy and richness after launch.

