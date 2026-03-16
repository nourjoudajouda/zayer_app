# In-App Notification Center

This document describes how server notifications are displayed inside the app and how navigation/read-state works.

## Data source

- Notifications are fetched from `GET /api/notifications` via `NotificationsRepository.fetchNotifications()`.
- Each item is mapped into `NotificationItem` with fields:
  - `title`, `subtitle`, `timeAgo`
  - `read` and `important`
  - `category` (raw backend type string, future-ready)
  - `actionRoute` / `actionLabel` (optional)

## Display (Notifications screen)

- Screen: `NotificationsListScreen` (`/notifications`)
- UI shows:
  - **Title** (bold when unread)
  - **Body** (`subtitle`, 2 lines max)
  - **Timestamp** (`timeAgo`) aligned on the same row as title
  - **Unread dot** on the left for unread items
  - **Category pill** (derived from filter type + raw category string)
  - Optional **action button** (`actionLabel`) that opens the same destination as tapping the card

Empty and loading states remain consistent with existing app patterns and `EmptyStateScaffold`.

## Read / unread behavior

- Backend read state is respected via the `read` boolean returned from the API.
- When the user opens a notification from the in-app list:
  - The item is marked read **immediately in-session** (local override) for better UX.
  - A best-effort backend call is attempted via `NotificationsRepository.markRead(id)` (multiple candidate endpoints tried, failures are ignored).
- “Mark all as read”:
  - Marks all visible items read in-session immediately.
  - Attempts best-effort backend calls via `NotificationsRepository.markAllRead()`.

This structure keeps the Flutter side ready even if backend read endpoints are still being finalized.

## Navigation (from notification center)

- If `NotificationItem.actionRoute` is:
  - a full app path like `/order-detail/123` → navigates directly
  - `route_key:id` or `route_key|id` → mapped using the existing notification route mapper
  - `route_key` → mapped using the existing route mapper with safe fallback
- Mapping helper: `resolveNotificationActionRoute(...)`

If the route cannot be resolved, navigation safely falls back to the notifications list.

## Push → in-app consistency

- When a foreground push notification arrives, the app invalidates the notifications list provider so the in-app center reflects new notifications.
- A subtle unread indicator foundation is provided:
  - Home header bell shows a dot when there are unread items.
  - Profile “Notifications” tile shows a dot when there are unread items.

## Next task

- Final release readiness polish (copy, localization, edge-case UX)
OR
- Advanced admin reporting / analytics refinements

