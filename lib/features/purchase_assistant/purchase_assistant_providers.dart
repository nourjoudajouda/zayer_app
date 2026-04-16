import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/purchase_assistant_request_model.dart';
import 'purchase_assistant_repository_api.dart';

/// User's Purchase Assistant requests (full lifecycle). Used by list + hub badge.
final purchaseAssistantRequestsProvider =
    FutureProvider<List<PurchaseAssistantRequestModel>>((ref) async {
  final repo = PurchaseAssistantRepositoryApi();
  return repo.list();
});

void invalidatePurchaseAssistantRequests(WidgetRef ref) {
  ref.invalidate(purchaseAssistantRequestsProvider);
}
