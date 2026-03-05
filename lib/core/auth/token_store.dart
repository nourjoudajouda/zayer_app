import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Storage key for the auth token.
const String _kTokenKey = 'auth_token';

/// Handles secure storage of the Bearer token for API auth.
abstract class TokenStore {
  Future<String?> getToken();
  Future<void> setToken(String token);
  Future<void> clearToken();
  Future<bool> hasToken();
}

class TokenStoreImpl implements TokenStore {
  TokenStoreImpl({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> getToken() => _storage.read(key: _kTokenKey);

  @override
  Future<void> setToken(String token) => _storage.write(key: _kTokenKey, value: token);

  @override
  Future<void> clearToken() => _storage.delete(key: _kTokenKey);

  @override
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
