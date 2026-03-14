# Payment launch flow (Square checkout) – summary

## Where payment launch was integrated

- **Screen:** Review & Pay → **Confirm & Pay** button (`lib/features/checkout/review_pay_screen.dart`).
- **API:** `POST /api/orders/{orderId}/pay` is called from `startOrderPayment(orderId)` in `lib/features/checkout/providers/checkout_review_providers.dart` (using the app’s existing `ApiClient`).
- **Response model:** `lib/features/checkout/models/payment_start_response.dart` (`PaymentStartResponse`: `paymentId`, `reference`, `checkoutUrl`, `status`).
- **WebView screen:** `lib/features/checkout/payment_webview_screen.dart` opens the `checkout_url` in an in-app WebView (same `webview_flutter` and design patterns as the rest of the app).
- **Route:** `AppRoutes.paymentWebView` = `/payment` with query `url=...`, registered in `lib/core/routing/app_router.dart`.

## What happens when the user taps Pay

1. Button shows **Processing...** and is disabled.
2. **POST /api/checkout/confirm** runs (existing flow); cart/orders/wallet are invalidated on success.
3. **POST /api/orders/{orderId}/pay** runs to get the Square checkout URL.
4. **If `checkout_url` is returned:** app navigates to Order Detail, then pushes the **payment WebView** with that URL. User completes or cancels in the WebView and closes to return to Order Detail.
5. **If the pay request fails or no `checkout_url`:** app still goes to Order Detail and shows a SnackBar with the error (e.g. network error, no payment link, unauthorized).

## Error handling covered

- Backend returns no `checkout_url`: user sees “No payment link received” and lands on Order Detail.
- Network/timeout: “Connection error. Check your network.” or “Could not start payment.”
- Unauthorized (401): “Please sign in to pay.”
- WebView page load failure: error state with “Open in browser” fallback.
- Unsupported platform (e.g. desktop): message that payment isn’t supported in-app and “Open in browser” option.

## What to implement next (payment completion sync)

- **Return URL / deep link:** When the backend supports a dedicated success/cancel return URL or app deep link, handle that in the WebView (e.g. `NavigationDelegate.onNavigationRequest` or URL scheme) to close the WebView and optionally refresh order status or show a success screen.
- **Polling or webhook-based status:** After the user closes the WebView, consider polling the order/payment status or relying on backend webhooks so the Order Detail (and orders list) show “Paid” or “Payment pending” once the backend has updated.
- **No change to Laravel in this task:** All of the above is Flutter-only; backend changes are out of scope for this implementation.
