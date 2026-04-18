import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';

/// One row from GET /api/me/activities.
class AccountActivityItem {
  const AccountActivityItem({
    required this.id,
    required this.actionType,
    required this.title,
    this.description,
    required this.meta,
    required this.createdAtIso,
  });

  final String id;
  final String actionType;
  final String title;
  final String? description;
  final Map<String, dynamic> meta;
  final String createdAtIso;

  static AccountActivityItem? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    final id = (j['id'] ?? '').toString();
    if (id.isEmpty) return null;
    final meta = j['meta'];
    return AccountActivityItem(
      id: id,
      actionType: (j['action_type'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      description: j['description'] as String?,
      meta: meta is Map<String, dynamic> ? meta : {},
      createdAtIso: (j['created_at'] ?? '').toString(),
    );
  }
}

Future<List<AccountActivityItem>> _fetchActivities(int limit) async {
  final res = await ApiClient.instance.get<Map<String, dynamic>>(
    '/api/me/activities?limit=$limit',
  );
  final raw = res.data?['activities'];
  if (raw is! List) return [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(AccountActivityItem.fromJson)
      .whereType<AccountActivityItem>()
      .toList();
}

final accountActivitiesPreviewProvider =
    FutureProvider.autoDispose<List<AccountActivityItem>>((ref) async {
  return _fetchActivities(8);
});

final accountActivitiesFullProvider =
    FutureProvider.autoDispose<List<AccountActivityItem>>((ref) async {
  return _fetchActivities(50);
});
