import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-session local overrides for read state (foundation until backend read-state is fully wired).
final locallyReadNotificationIdsProvider =
    NotifierProvider<LocallyReadNotificationIdsNotifier, Set<String>>(
  LocallyReadNotificationIdsNotifier.new,
);

/// In-session local overrides for deleted notifications (hide from list).
final locallyDeletedNotificationIdsProvider =
    NotifierProvider<LocallyDeletedNotificationIdsNotifier, Set<String>>(
  LocallyDeletedNotificationIdsNotifier.new,
);

class LocallyReadNotificationIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void markRead(String id) {
    if (id.trim().isEmpty) return;
    state = {...state, id};
  }

  void markAllRead(Iterable<String> ids) {
    state = {...state, ...ids.where((e) => e.trim().isNotEmpty)};
  }

  void clear() {
    state = <String>{};
  }
}

class LocallyDeletedNotificationIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void markDeleted(String id) {
    if (id.trim().isEmpty) return;
    state = {...state, id};
  }

  void markAllDeleted(Iterable<String> ids) {
    state = {...state, ...ids.where((e) => e.trim().isNotEmpty)};
  }

  void clear() {
    state = <String>{};
  }
}

