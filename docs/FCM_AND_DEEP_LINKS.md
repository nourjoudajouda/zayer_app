# FCM and Deep-Link Navigation

This document describes how Firebase Cloud Messaging (FCM) and notification-driven deep linking work in the Eshterely Flutter app.

## FCM Initialization

- **Where**: Firebase is initialized in `main.dart` with `Firebase.initializeApp()`. FCM is configured in `FcmService.setup()`, which is invoked from the app builder in `app.dart` so it has access to Riverpod ref (for auth and pending navigation).
- **Single run**: `FcmService.setup()` runs once; a static `_initialized` flag prevents duplicate setup.
- **Flow**:
  1. Request notification permission (iOS).
  2. Initialize `flutter_local_notifications` (for foreground in-app display and tap handling).
  3. Create Android notification channel for foreground notifications.
  4. Request FCM token and call `onTokenReady` callback (used to register token with backend).
  5. Subscribe to `onTokenRefresh` and re-call `onTokenReady` when the token changes.
  6. Register `FirebaseMessaging.onMessage` (foreground), `onMessageOpenedApp` (background tap), and handle `getInitialMessage()` (terminated launch from notification).

No re-initialization of Firebase is done elsewhere; the existing Firebase setup is kept intact.

## Token Registration

- **Endpoint**: `PATCH /api/me/fcm-token` with body `{ "fcm_token": "<token>", "device_type": "android"|"ios"|"web" }`.
- **Who calls it**: The `onTokenReady` callback passed to `FcmService.setup()` calls `AuthRepository.updateFcmToken()`, which uses the app’s existing authenticated API client.
- **When**: After FCM returns a token (at setup) and on token refresh. `MainShell` also calls `updateFcmToken()` once when the user is inside the main shell (logged-in area).
- **Behavior**: Token registration is best-effort. If the request fails (e.g. no network or 401), the app does not block or crash; errors are swallowed so startup and usage continue normally.
- **Platform**: `device_type` is set via a small platform helper: `ios` / `android` on mobile, `web` on web.

## Foreground Notification Handling

- When the app is in the **foreground** and an FCM message arrives, `FirebaseMessaging.onMessage` is used.
- The message is shown to the user via **local notifications** (`flutter_local_notifications`), using the same notification icon/channel as the rest of the app.
- Title/body come from `message.notification`; the full `message.data` map is passed as the local notification payload so that when the user **taps** the notification, the same deep-link logic is used as for background/terminated.

No new UI or visual language is introduced; behavior is consistent with the existing design.

## Notification Tap / Deep-Link Handling

- **Payload fields** (from backend): `target_type`, `target_id`, `route_key`, and optionally `meta` (or `payload`). These are parsed by `AppNotificationPayload` and mapped to routes by `notification_route_mapper.dart`.
- **Navigation targets** (at least):
  - Order detail: `/order-detail/:id`
  - Order tracking: `/order-tracking/:id`
  - Order invoice: `/order-invoice/:id`
  - Support ticket chat: `/support/ticket/:id`
  - Wallet: `/wallet`
  - Notifications list: `/notifications`
  - Orders list: `/orders`
  - Support inbox: `/support-inbox`
- **Flow**: Notification data (from FCM or from the local notification payload on tap) is parsed → `mapPayloadToTarget()` returns a `NotificationNavigationTarget` (with a `route` string) → the app navigates with `context.go(target.route)` when the user is authenticated.
- **Integration**: Uses the existing **GoRouter** setup; route names and paths match `AppRoutes` in `app_router.dart`. A small `pendingNotificationTargetProvider` (Riverpod) holds a pending target; the app and splash screen consume it and call `context.go(...)` so no hardcoded navigation hacks are required.

## App Launch States

- **Foreground**: User sees a local notification; tap is handled via `onDidReceiveNotificationResponse` (local notifications), which parses the payload and sets the pending target; the app’s listener then runs and navigates.
- **Background**: User taps the system notification → `FirebaseMessaging.onMessageOpenedApp` runs → payload is parsed and pending target is set → listener navigates when the app is in the foreground again.
- **Terminated**: On launch from a notification, `getInitialMessage()` is used in `FcmService.setup()`. The resulting target is stored in the same pending provider. The **splash screen** checks this pending target when it finishes; if the user is logged in, it navigates to the target route instead of home; otherwise it goes to onboarding/register.

So notification-driven navigation is handled for foreground, background, and terminated cases using the proper FCM callbacks and app startup flow.

## Routing Integration

- Deep links use the same paths as GoRouter (e.g. `/order-detail/123`, `/support/ticket/456`, `/wallet`, `/notifications`).
- Navigation is done via `context.go(target.route)` from a place that has router context (app builder and splash). A single **pending notification provider** feeds both the in-app listener and the splash screen, keeping behavior consistent and avoiding brittle or duplicated logic.

## Notification Payload Model

- **AppNotificationPayload**: Built from the raw FCM `data` map; exposes `target_type`, `target_id`, `route_key`, and `meta`.
- **NotificationNavigationTarget**: Holds `route` (path string), `targetType`, optional `targetId`, and optional `meta` for the destination screen.
- New notification types (e.g. payment_success, order_processing, tracking_assigned, shipment_delivered, support_reply, admin_broadcast) can be supported by extending `notification_route_mapper.dart`: add new `route_key` or `target_type` cases and return the appropriate `NotificationNavigationTarget`.

## Graceful Fallbacks

- **Payload missing `target_type` / unknown `route_key`**: Mapper returns a fallback target with route `/notifications` (or the same path as `AppRoutes.notifications`). FCM service uses this when parsing returns null so the user still lands on a safe screen.
- **Missing `target_id`** (for routes that need an id): Mapper returns a list/summary screen (e.g. orders list, support inbox) instead of a detail screen.
- **User not authenticated**: When handling a pending notification (from listener or splash), the app checks auth (e.g. `tokenStoreProvider.hasToken()`). If not logged in, the pending target is cleared and the user is sent to onboarding/register instead of the deep-link target.
- **Backend sends a payload for a screen not implemented**: Unknown `route_key` or `target_type` falls back to the notifications list so the app never crashes and the user sees a valid screen.

## Future-Ready Design

- New notification types can be added by extending `_routeFromRouteKey` and `_routeFromTargetType` in `notification_route_mapper.dart`.
- Payload model and mapper are separate from FCM transport and from GoRouter, so backend or route changes can be handled in one place.

## Tests and Verification

- **Unit tests**: `test/core/fcm/notification_payload_test.dart` covers payload parsing and route mapping (order_detail, order_tracking, support_ticket, wallet, fallbacks, unknown keys, missing id).
- **Manual checks**:
  - Send a test notification with `target_type: "order"`, `target_id: "<valid_order_id>"` and confirm the app opens order detail (or tracking if meta requests it).
  - Same for support ticket and wallet.
  - Open app from a notification when app was terminated and confirm splash finishes and navigates to the target when logged in, or to onboarding when not.
  - Confirm foreground notification shows and tap navigates correctly.
  - Confirm token is sent to backend after login and after token refresh (e.g. inspect network or backend logs).

## Next Steps

- **Notifications list / in-app notification center**: Enrich the notifications list screen and in-app notification center (e.g. mark read, filters, pagination).
- **Tracking screen**: If not already complete, finish tracking screen integration and ensure notification payloads that point to tracking use the correct route and params.
