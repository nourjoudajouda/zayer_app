## App Flow Fixes Report (Flutter-only)

Scope: targeted **fix-and-polish** pass for user-facing flows that were misleading or brittle.  
Constraints honored: **Flutter app only**, no backend edits, no redesign, no hardcoded shipping/duties/taxes/payment outcomes.

## Summary of fixes (screen-by-screen)

### 1) Confirm Product (`lib/features/product_import/confirm_product_screen.dart`)
- Removed **mock/hardcoded** shipping + duties pricing and any “final-looking” totals.
- Cost breakdown now shows:
  - **Product subtotal** based on quantity
  - **Shipping** as **Pending Review** (until backend provides a quote)
  - **Total** as **Pending Review** (no fabricated totals)
- Quantity changes consistently update the displayed product subtotal.
- Replaced the old success dialog with the shared **bottom-sheet success UX**.

### 2) Add-via-Link flow (`lib/features/paste_link/paste_product_link_screen.dart`)
- Ensured “Add to Cart” has **real behavior** with:
  - validation feedback (no silent no-op)
  - loading state
  - error snackbar if the backend/cart action fails
- On success, shows the same **modern bottom sheet** success UX:
  - primary: **Go to Cart**
  - secondary: **Continue Shopping**

### 3) Added-to-cart success UX (shared)
- Added shared bottom sheet: `lib/core/widgets/add_to_cart_success_sheet.dart`
- Used by both Confirm Product and Add-via-Link screens.

### 4) Cart (`lib/features/placeholders/cart_screen.dart`, `lib/features/cart/providers/cart_providers.dart`)
- Removed placeholder shipping values (e.g. `12.0 * items.length`).
- Shipping and Total are now **honest**:
  - show a real amount only when items are **reviewed** and backend provides `shippingCost`
  - otherwise render **Pending review** (no contradictory “Pending review” + final shipping number)
- Quantity updates now refresh from backend after update/remove so any server-side recalculation can be reflected.

### 5) Review & Pay (`lib/features/checkout/review_pay_screen.dart`, `lib/features/checkout/models/checkout_review_model.dart`)
- Checkout review is now **backend-source-of-truth only** (no local fabricated fallback totals).
- Added parsing for backend-provided:
  - `amount_due_now` (or similar) to compute the real **amount due now**
  - `wallet_applied` if present
- Confirm CTA is now honest:
  - **Confirm Order** when amount due now is \(0\)
  - **Confirm & Pay $X.XX** when amount due now is \(> 0\)
- Payment launch behavior:
  - Only starts Square WebView when backend provides a real `checkout_url`
  - Avoids duplicate navigation; opens WebView first, then routes to Order Details
  - Refreshes order state after WebView return

### 6) Payment flow resilience
- Reduced mixed success+error UX:
  - No longer navigates to order details and then immediately launches WebView as a separate navigation “surprise”
  - When WebView fails to load, user gets a clear message and still lands in a sane order state

### 7) Order Details (`lib/features/orders/order_detail_screen.dart`)
- Restored item image rendering using the order snapshot `image_url` when provided.
- Removed the non-functional info icon on the shipping address card.
- Avoided showing empty/fake shipping method text.
- Improved SKU display to avoid “SKU:” when empty.

### 8) Order Tracking (`lib/features/orders/order_tracking_screen.dart`, `lib/features/orders/models/order_model.dart`)
- Tracking presentation is now **event-driven**:
  - Shows backend `tracking_events` for any shipment/country (not US-only).
  - If no events exist, renders a polished, honest empty state (“updates will appear once handed to carrier”).
- Removed fake “Last updated: 14 mins ago”.
- Customs insight is now shown only when backend provides customs duties data.
- Improved order shipment parsing so backend-provided logistics fields can appear:
  - `gross_weight_kg`, `dimensions`, `insurance_confirmed`, `status_tags`

### 9) Notifications list
- No breaking changes made. Existing polished screen remains compatible.

### 10) My Addresses crash (`lib/features/profile/repositories/address_repository_impl.dart`)
- Fixed crash `type 'int' is not a subtype of type 'String?'` by using safe conversions for fields that sometimes arrive as `int`/`String`.

### 11) Wallet Top Up (`lib/features/wallet/top_up_wallet_screen.dart`)
- Top-up is now **real-or-honest**:
  - If backend returns `checkout_url`, launches the Square WebView and refreshes wallet after return.
  - If backend does **not** return a payment launch URL, the UI no longer claims success; it shows an honest “not available right now” message.

## Backend-dependent limitations (still present)
- **Confirm Product** cannot show real shipping/duties totals until the backend provides a quote/final pricing payload for that pre-cart state.
- **Wallet top-up** requires backend to return a `checkout_url` (or equivalent) for Square; without it, the app intentionally does not pretend funds were added.
- **Checkout review** amount-due-now accuracy depends on backend sending `amount_due_now` (or an equivalent numeric source-of-truth field).

## Manual verification checklist

### Confirm Product
- [ ] Quantity +/- updates product subtotal.
- [ ] Shipping/Total do not show invented numbers (should show Pending Review).
- [ ] Add to Cart shows bottom sheet with **Go to Cart** / **Continue Shopping**.

### Add via Link
- [ ] Missing name/price prevents add; user sees a clear prompt.
- [ ] Successful add shows bottom sheet with correct CTAs.
- [ ] Add failure shows a visible error message (not silent).

### Cart
- [ ] Pending-review items do not show definitive shipping totals.
- [ ] Quantity change triggers backend refresh (shipping/totals update if backend provides).
- [ ] Summary shows **Pending review** when shipping is not confirmed.

### Review & Pay
- [ ] If backend says due-now is 0 → button says **Confirm Order** and does not open payment WebView.
- [ ] If due-now > 0 → button says **Confirm & Pay $X.XX** and opens Square WebView using backend URL.
- [ ] Returning from WebView refreshes order state and lands on the correct order details.

### Order Details / Tracking
- [ ] Order item image shows when backend provides `image_url`.
- [ ] Tracking shows events timeline when events exist; otherwise shows the empty state (no fake statuses).

### Addresses
- [ ] My Addresses loads even when backend sends `city_id` (or other fields) as an `int`.

### Wallet Top Up
- [ ] If backend returns `checkout_url`, WebView opens and wallet refreshes on return.
- [ ] If backend does not support top-up, user is told honestly and no “added to wallet” message appears.

## Readiness assessment (for these flows)
- **Misleading pricing and fake totals removed** from Confirm Product, Cart, and Checkout fallback codepaths.
- **Payment and wallet top-up behaviors are now backend-driven**, reducing confusing “error but continued” states.
- Remaining gaps are primarily **backend payload availability** (quotes, due-now, top-up checkout URL), and the UI now reflects those gaps honestly instead of fabricating values.

