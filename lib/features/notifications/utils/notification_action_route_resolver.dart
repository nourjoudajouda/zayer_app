import '../../../core/fcm/notification_payload.dart';
import '../../../core/fcm/notification_route_mapper.dart';

/// Resolves backend `action_route` strings into an in-app GoRouter path.
///
/// Supported formats (best-effort):
/// - `/some/path` (already a GoRouter path)
/// - `route_key:id` or `route_key|id`
/// - `route_key` (mapped via route mapper, falls back to notifications list)
String? resolveNotificationActionRoute(String? raw) {
  final v = raw?.trim();
  if (v == null || v.isEmpty) return null;

  if (v.startsWith('/')) return v;

  final sep = v.contains(':') ? ':' : (v.contains('|') ? '|' : null);
  if (sep != null) {
    final parts = v.split(sep);
    final routeKey = parts.isNotEmpty ? parts.first.trim() : '';
    final id = parts.length > 1 ? parts[1].trim() : null;
    final payload = AppNotificationPayload.fromMap({
      'route_key': routeKey,
      'target_id': id,
    });
    return mapPayloadToTarget(payload)?.route;
  }

  final payload = AppNotificationPayload.fromMap({'route_key': v});
  return mapPayloadToTarget(payload)?.route;
}

