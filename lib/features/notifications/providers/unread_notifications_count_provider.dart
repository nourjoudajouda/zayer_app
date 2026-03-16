import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notifications_list_provider.dart';

/// Lightweight foundation for badges/indicators.
/// Uses the notifications list's `read` flag (plus local overrides).
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final asyncList = ref.watch(notificationsListProvider);
  final list = asyncList.valueOrNull ?? const [];
  return list.where((n) => !n.read).length;
});

