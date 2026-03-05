import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/fcm/fcm_providers.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    tokenStore: ref.watch(tokenStoreProvider),
    fcmService: ref.watch(fcmServiceProvider),
  );
});
