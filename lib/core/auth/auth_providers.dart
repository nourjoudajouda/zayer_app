import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'token_store.dart';

/// Provides [TokenStore] for secure token read/write.
/// Uses the same storage as ApiClient's interceptor.
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStoreImpl());
