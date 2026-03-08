import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    tokenStore: ref.watch(tokenStoreProvider),
  );
});

/// True while logout API is in progress (e.g. for loader on profile logout button).
final authLoggingOutProvider = StateProvider<bool>((ref) => false);
