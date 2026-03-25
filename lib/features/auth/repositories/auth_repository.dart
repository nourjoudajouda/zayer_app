import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:zayer_app/core/fcm/fcm_service.dart';
import 'package:zayer_app/core/platform/device_locale_region.dart';
import 'package:zayer_app/core/platform/device_platform.dart';
import 'package:zayer_app/core/platform/session_device_label.dart';

import '../device_name_for_api.dart';
import '../../../core/auth/token_store.dart';
import '../../../core/network/api_client.dart';
import '../models/auth_result.dart';
import '../models/country_city.dart';

/// Auth API repository. Handles register, login, OTP, forgot, logout.
abstract class AuthRepository {
  Future<AuthResult> register({
    required String phone,
    required String fullName,
    required String password,
    String? countryId,
    String? cityId,
  });
  Future<AuthResult> login({
    required String phone,
    required String password,
    String? appCountry,
  });
  /// Request OTP for passwordless login (user must already be registered).
  Future<AuthResult> requestLoginOtp({required String phone});
  Future<AuthResult> verifyOtp({
    required String phone,
    required String code,
    String mode = 'signup',
    String? password,
    String? passwordConfirmation,
    String? appCountry,
  });
  Future<AuthResult> forgotPassword({required String phone});
  Future<void> logout();
  Future<void> updateFcmToken();
  Future<List<CountryItem>> getCountries();
  Future<List<CityItem>> getCities({String? countryId, String? countryCode});
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required TokenStore tokenStore,
    // FcmService? fcmService,
    Dio? dio,
  })  : _tokenStore = tokenStore,
        // _fcmService = fcmService,
        _dio = dio ?? ApiClient.instance;

  final TokenStore _tokenStore;
  // final FcmService? _fcmService;
  final Dio _dio;

  /// FCM + device metadata for login / verify-otp (matches Laravel AuthController).
  Future<Map<String, dynamic>> _fcmDevicePayload({String? appCountry}) async {
    final fcmToken = await FcmService.getToken();
    final dt = kIsWeb ? 'web' : deviceType;
    final model = await sessionDeviceLabelForApi();
    final payload = <String, dynamic>{
      'device_type': dt,
      'platform': dt,
      'device_name': deviceNameForApi(),
      'device_model': model,
    };
    final explicit = appCountry?.trim();
    final country = (explicit != null && explicit.isNotEmpty)
        ? explicit
        : deviceRegionLabelForSession();
    if (country != null && country.isNotEmpty) {
      payload['app_country'] =
          country.length > 191 ? country.substring(0, 191) : country;
    }
    if (fcmToken != null && fcmToken.isNotEmpty) {
      payload['fcm_token'] = fcmToken;
    }
    return payload;
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'] as String?;
      if (msg != null && msg.isNotEmpty) return msg;
      final errors = data['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        if (first is String) return first;
      }
    }
    return e.response?.statusMessage ?? e.message ?? 'Request failed';
  }

  /// Register. Sends only fields accepted by API:
  /// full_name, phone, password, password_confirmation, country_id?, city_id?
  @override
  Future<AuthResult> register({
    required String phone,
    required String fullName,
    required String password,
    String? countryId,
    String? cityId,
  }) async {
    try {
      final data = <String, dynamic>{
        'full_name': fullName,
        'phone': phone,
        'password': password,
        'password_confirmation': password,
      };
      if (countryId != null && countryId.isNotEmpty) {
        data['country_id'] = countryId;
      }
      if (cityId != null && cityId.isNotEmpty) {
        data['city_id'] = cityId;
      }
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/auth/register',
        data: data,
        options: Options(
          contentType: 'application/json',
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      final resData = res.data;
      if (res.statusCode == 201 && resData != null) {
        final devOtp = kDebugMode ? _readOtpFromResponse(resData) : null;
        return AuthRequiresOtp(
          phone: (resData['phone'] ?? phone).toString(),
          userId: resData['user_id'] as int?,
          mode: 'signup',
          devOtp: devOtp,
        );
      }
      return AuthFailure(_extractMessage(
        DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        ),
      ));
    } on DioException catch (e) {
      return AuthFailure(_extractMessage(e));
    }
  }

  @override
  Future<AuthResult> login({
    required String phone,
    required String password,
    String? appCountry,
  }) async {
    try {
      final fcmToken = await FcmService.getToken();
      if (kDebugMode && fcmToken != null && fcmToken.isNotEmpty) {
        final preview =
            fcmToken.length > 10 ? '${fcmToken.substring(0, 10)}…' : fcmToken;
        // Debug-only preview of FCM token; do not log full token in production.
        // ignore: avoid_print
        print('FCM token (preview): $preview');
      }
      final data = <String, dynamic>{
        'phone': phone,
        'password': password,
      };
      data.addAll(await _fcmDevicePayload(appCountry: appCountry));
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: data,
        options: Options(
          contentType: 'application/json',
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      final responseData = res.data;
      if (res.statusCode == 200 && responseData != null) {
        final token = responseData['token'] as String?;
        if (token != null && token.isNotEmpty) {
          await _tokenStore.setToken(token);
          unawaited(updateFcmToken());
          return AuthSuccess(token: token);
        }
      }
      return AuthFailure(_extractMessage(
        DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        ),
      ));
    } on DioException catch (e) {
      return AuthFailure(_extractMessage(e));
    }
  }

  @override
  Future<AuthResult> requestLoginOtp({required String phone}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/auth/login-otp',
        data: {'phone': phone},
        options: Options(
          contentType: 'application/json',
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        final devOtp = kDebugMode ? _readOtpFromResponse(data) : null;
        return AuthRequiresOtp(
          phone: (data['phone'] ?? phone).toString(),
          mode: 'login',
          devOtp: devOtp,
        );
      }
      return AuthFailure(_extractMessage(
        DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        ),
      ));
    } on DioException catch (e) {
      return AuthFailure(_extractMessage(e));
    }
  }

  @override
  Future<AuthResult> verifyOtp({
    required String phone,
    required String code,
    String mode = 'signup',
    String? password,
    String? passwordConfirmation,
    String? appCountry,
  }) async {
    try {
      final body = <String, dynamic>{
        'phone': phone,
        'code': code,
        'mode': mode,
      };
      if (mode == 'reset' && password != null) {
        body['password'] = password;
        body['password_confirmation'] = passwordConfirmation ?? password;
      }
      body.addAll(await _fcmDevicePayload(appCountry: appCountry));
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/auth/verify-otp',
        data: body,
        options: Options(
          contentType: 'application/json',
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      final responseData = res.data;
      if (res.statusCode == 200 && responseData != null) {
        final token = responseData['token'] as String?;
        if (token != null && token.isNotEmpty) {
          await _tokenStore.setToken(token);
          unawaited(updateFcmToken());
          return AuthSuccess(token: token);
        }
      }
      return AuthFailure(_extractMessage(
        DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        ),
      ));
    } on DioException catch (e) {
      return AuthFailure(_extractMessage(e));
    }
  }

  @override
  Future<AuthResult> forgotPassword({required String phone}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/auth/forgot-password',
        data: {'phone': phone},
        options: Options(
          contentType: 'application/json',
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        final devOtp = kDebugMode ? _readOtpFromResponse(data) : null;
        return AuthRequiresOtp(
          phone: (data['phone'] ?? phone).toString(),
          mode: 'reset',
          devOtp: devOtp,
        );
      }
      return AuthFailure(_extractMessage(
        DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        ),
      ));
    } on DioException catch (e) {
      return AuthFailure(_extractMessage(e));
    }
  }

  /// Read OTP from API response when returned in dev (e.g. otp, code).
  static String? _readOtpFromResponse(Map<String, dynamic> data) {
    final otp = data['otp'] ?? data['code'];
    if (otp == null) return null;
    final s = otp.toString().trim();
    return s.isEmpty ? null : s;
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
    } catch (_) {}
    await _tokenStore.clearToken();
    ApiClient.onLogout();
  }

  @override
  Future<void> updateFcmToken() async {
    final token = await _tokenStore.getToken();
    if (token == null || token.isEmpty) return;
    final fcmToken = await FcmService.getToken();
    if (fcmToken == null || fcmToken.isEmpty) return;
    final dt = kIsWeb ? 'web' : deviceType;
    final model = await sessionDeviceLabelForApi();
    final region = deviceRegionLabelForSession();
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/api/me/fcm-token',
        data: {
          'fcm_token': fcmToken,
          'device_type': dt,
          'platform': dt,
          'device_name': deviceNameForApi(),
          'device_model': model,
          if (region != null && region.isNotEmpty) 'app_country': region,
        },
        options: Options(validateStatus: (s) => s != null && s < 500),
      );
    } catch (_) {
      // Do not block app; token registration is best-effort
    }
  }

  @override
  Future<List<CountryItem>> getCountries() async {
    final res = await _dio.get<dynamic>('/api/countries');
    final raw = res.data;
    List list;
    if (raw is String) {
      try {
        list = jsonDecode(raw) as List;
      } catch (_) {
        return [];
      }
    } else if (raw is List) {
      list = raw;
    } else {
      return [];
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(CountryItem.fromJson)
        .toList();
  }

  @override
  Future<List<CityItem>> getCities({
    String? countryId,
    String? countryCode,
  }) async {
    final queryParams = <String, String>{};
    if (countryId != null && countryId.isNotEmpty) {
      queryParams['country_id'] = countryId;
      if (countryCode != null && countryCode.isNotEmpty) {
        queryParams['country_code'] = countryCode;
      } else if (int.tryParse(countryId) == null) {
        queryParams['country_code'] = countryId;
      }
    } else if (countryCode != null && countryCode.isNotEmpty) {
      queryParams['country_code'] = countryCode;
    }
    final res = await _dio.get<dynamic>(
      '/api/cities',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final raw = res.data;
    List list;
    if (raw is String) {
      try {
        list = jsonDecode(raw) as List;
      } catch (_) {
        return [];
      }
    } else if (raw is List) {
      list = raw;
    } else {
      return [];
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(CityItem.fromJson)
        .toList();
  }
}
