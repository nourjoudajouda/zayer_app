import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/token_store.dart';
import 'api_config.dart';

const String _kStorageKeyApiBaseUrl = 'api_base_url';

/// On web, if base URL is the emulator value, use localhost for Laravel dev.
String get _effectiveBaseUrl {
  if (kIsWeb && kApiBaseUrl == 'http://10.0.2.2') {
    return 'http://localhost:8000';
  }
  return kApiBaseUrl;
}

/// Dio singleton for API calls with auth interceptor.
/// Base URL can be overridden from admin via bootstrap [api_base_url].
class ApiClient {
  ApiClient._();

  static Dio? _instance;
  static TokenStore? _tokenStore;
  static const FlutterSecureStorage _urlStorage = FlutterSecureStorage();

  /// Initialize the client. Call once at app startup (async to load saved API URL).
  static Future<void> init({required TokenStore tokenStore, Dio? dio}) async {
    _tokenStore = tokenStore;
    final baseUrl = await _getResolvedBaseUrl();
    _instance = dio ?? _createDio(baseUrl);
  }

  /// Legacy sync init; prefers [init] (async) so saved URL from admin is used.
  static void initSync({required TokenStore tokenStore, Dio? dio}) {
    _tokenStore = tokenStore;
    _instance = dio ?? _createDio(_effectiveBaseUrl);
  }

  static Future<String> _getResolvedBaseUrl() async {
    final saved = await _urlStorage.read(key: _kStorageKeyApiBaseUrl);
    if (saved != null && saved.trim().isNotEmpty) return saved.trim();
    return _effectiveBaseUrl;
  }

  static Dio _createDio(String baseUrl) {
    final normalized = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return Dio(
      BaseOptions(
        baseUrl: normalized,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    )..interceptors.add(_AuthInterceptor(_tokenStore!));
  }

  /// Set base URL from admin (bootstrap api_base_url). Persists for next launch.
  static Future<void> setBaseUrlFromAdmin(String url) async {
    if (url.trim().isEmpty) return;
    final normalized = url.trim().endsWith('/')
        ? url.trim().substring(0, url.trim().length - 1)
        : url.trim();
    await _urlStorage.write(key: _kStorageKeyApiBaseUrl, value: normalized);
    final dio = _instance;
    if (dio != null) dio.options.baseUrl = normalized;
  }

  /// Get the shared Dio instance. Throws if [init] was not called.
  static Dio get instance {
    final dio = _instance;
    if (dio == null) {
      throw StateError(
        'ApiClient not initialized. Call ApiClient.init(tokenStore: ...) at startup.',
      );
    }
    return dio;
  }

  /// Call this when user logs out to clear token and optionally reset.
  static void onLogout() {
    _tokenStore?.clearToken();
  }

  /// Current base URL in use (for dev screen / debugging).
  static String? get currentBaseUrl => _instance?.options.baseUrl;
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._tokenStore);

  final TokenStore _tokenStore;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStore.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await _tokenStore.clearToken();
      // Emit a special error that the app can use to redirect to login.
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: err.error,
        ),
      );
    } else {
      handler.next(err);
    }
  }
}
