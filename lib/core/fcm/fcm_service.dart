import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_payload.dart';
import 'notification_route_mapper.dart';

/// Callbacks used by [FcmService] to integrate with app (auth, navigation).
typedef OnNotificationTap = void Function(NotificationNavigationTarget target);
typedef OnTokenReady = void Function(String token);
typedef OnForegroundMessage = void Function(RemoteMessage message);

/// Central FCM setup: permission, token, foreground/background/terminated handling.
/// Call [setup] once when the app has context (e.g. from [ZayerApp] builder).
class FcmService {
  FcmService._();

  static bool _initialized = false;
  static OnNotificationTap? _onNotificationTap;
  static OnTokenReady? _onTokenReady;
  static OnForegroundMessage? _onForegroundMessageCallback;

  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Call once at app startup with callbacks that have access to ref/auth.
  /// [onNotificationTap] is called when user taps a notification (any state).
  /// [onTokenReady] is called with FCM token for backend registration; call
  /// your token update API (e.g. AuthRepository.updateFcmToken) inside it.
  static Future<void> setup({
    required OnNotificationTap onNotificationTap,
    required OnTokenReady onTokenReady,
    OnForegroundMessage? onForegroundMessage,
  }) async {
    if (_initialized) return;
    _onNotificationTap = onNotificationTap;
    _onTokenReady = onTokenReady;
    _onForegroundMessageCallback = onForegroundMessage;

    try {
      if (Platform.isIOS) {
        final settings = await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          announcement: false,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
        );
        if (settings.authorizationStatus != AuthorizationStatus.authorized &&
            settings.authorizationStatus != AuthorizationStatus.provisional) {
          if (kDebugMode) {
            debugPrint('FCM: User declined notification permission');
          }
          _initialized = true;
          return;
        }
      }

      const android = AndroidInitializationSettings('notification_icon');
      const ios = DarwinInitializationSettings();
      await _initializeLocalNotifications(android: android, ios: ios);
      if (Platform.isAndroid) {
        const channel = AndroidNotificationChannel(
          'fcm_foreground_channel',
          'Notifications',
          description: 'App notifications',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      if (Platform.isIOS) {
        await _firebaseMessaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      await _requestTokenAndNotify();

      _firebaseMessaging.onTokenRefresh.listen((_) {
        _requestTokenAndNotify();
      });

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        final target =
            _parseMessageData(initialMessage.data) ??
            const NotificationNavigationTarget(
              route: '/notifications',
              targetType: 'fallback',
            );
        _onNotificationTap?.call(target);
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('FCM setup error: $e');
        debugPrint('$st');
      }
    }
    _initialized = true;
  }

  static void _onDidReceiveNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final appPayload = AppNotificationPayload.fromMap(map);
      final target =
          mapPayloadToTarget(appPayload) ??
          const NotificationNavigationTarget(
            route: '/notifications',
            targetType: 'fallback',
          );
      if (kDebugMode) {
        debugPrint('FCM: notification tap -> route: ${target.route}, targetType: ${target.targetType}');
      }
      _onNotificationTap?.call(target);
    } catch (e) {
      if (kDebugMode) debugPrint('FCM: tap payload parse error: $e');
      _onNotificationTap?.call(const NotificationNavigationTarget(
        route: '/notifications',
        targetType: 'fallback',
      ));
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    if (data.isEmpty) return;
    if (kDebugMode) {
      debugPrint('FCM: foreground message received; data keys: ${data.keys.join(", ")}');
    }
    final title = message.notification?.title ?? 'Notification';
    final body = message.notification?.body ?? '';
    _showLocalNotification(
      title: title,
      body: body,
      payload: data,
    );
    try {
      final appPayload = AppNotificationPayload.fromMap(data);
      final target = mapPayloadToTarget(appPayload);
      if (kDebugMode) {
        debugPrint('FCM: payload parsed -> target: ${target?.route ?? "fallback"}');
      }
    } catch (_) {}
    _onForegroundMessageCallback?.call(message);
  }

  static void _onMessageOpenedApp(RemoteMessage message) {
    final target =
        _parseMessageData(message.data) ??
        const NotificationNavigationTarget(
          route: '/notifications',
          targetType: 'fallback',
        );
    _onNotificationTap?.call(target);
  }

  static NotificationNavigationTarget? _parseMessageData(Map<String, dynamic> data) {
    if (data.isEmpty) return null;
    try {
      final payload = AppNotificationPayload.fromMap(data);
      final target = mapPayloadToTarget(payload);
      if (kDebugMode && target != null) {
        debugPrint('FCM: route target resolved -> ${target.route} (${target.targetType})');
      }
      return target;
    } catch (e) {
      if (kDebugMode) debugPrint('FCM: parseMessageData error: $e');
      return null;
    }
  }

  static Future<void> _requestTokenAndNotify() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null && token.isNotEmpty) {
        if (kDebugMode) debugPrint('FCM token: ${token.substring(0, 20)}...');
        _onTokenReady?.call(token);
      }
      await _firebaseMessaging.subscribeToTopic('all');
    } catch (e) {
      if (kDebugMode) debugPrint('FCM getToken error: $e');
    }
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    const android = AndroidNotificationDetails(
      'fcm_foreground_channel',
      'Notifications',
      channelDescription: 'App notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
    );
    const ios = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: ios);
    final payloadJson = jsonEncode(payload);
    try {
      // Use dynamic to support plugin signature differences across platforms/tests.
      final plugin = _localNotifications as dynamic;
      await plugin.show(
        payload.hashCode % 0x7FFFFFFF,
        title,
        body,
        details,
        payload: payloadJson,
      );
    } catch (_) {
      try {
        final plugin = _localNotifications as dynamic;
        await plugin.show(
          id: payload.hashCode % 0x7FFFFFFF,
          title: title,
          body: body,
          notificationDetails: details,
          payload: payloadJson,
        );
      } catch (_) {}
    }
  }

  static Future<void> _initializeLocalNotifications({
    required AndroidInitializationSettings android,
    required DarwinInitializationSettings ios,
  }) async {
    try {
      final plugin = _localNotifications as dynamic;
      await plugin.initialize(
        InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );
    } catch (_) {
      try {
        final plugin = _localNotifications as dynamic;
        await plugin.initialize(
          initializationSettings: InitializationSettings(android: android, iOS: ios),
          onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
        );
      } catch (_) {}
    }
  }

  /// Returns current FCM token if already initialized; otherwise null.
  static Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (_) {
      return null;
    }
  }
}
