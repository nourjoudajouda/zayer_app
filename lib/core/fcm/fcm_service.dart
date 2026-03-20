import 'dart:convert';
import 'dart:io';
// Uint8List is re-exported by package:flutter/foundation.dart.

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
  static const String _channelId = 'fcm_high_importance_v2';
  static const String _channelName = 'High Priority Notifications';

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

      if (Platform.isAndroid) {
        await _requestAndroidNotificationPermission();
      }

      const android = AndroidInitializationSettings('notification_icon');
      const ios = DarwinInitializationSettings();
      await _initializeLocalNotifications(android: android, ios: ios);
      if (Platform.isAndroid) {
        const channel = AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'App notifications',
          importance: Importance.max,
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
    if (kDebugMode) {
      debugPrint('FCM: foreground message received; data keys: ${data.keys.join(", ")}');
    }
    final title = message.notification?.title ?? 'Notification';
    final body = message.notification?.body ?? '';
    final imageUrl = (data['image_url'] ?? '').toString();
    _showLocalNotification(
      title: title,
      body: body,
      // Some providers/flows may send "notification-only" messages (empty data).
      // Still show a foreground notification; payload remains best-effort.
      payload: data.isNotEmpty ? data : <String, dynamic>{},
      imageUrl: imageUrl.trim().isEmpty ? null : imageUrl.trim(),
    );
    try {
      if (data.isNotEmpty) {
        final appPayload = AppNotificationPayload.fromMap(data);
        final target = mapPayloadToTarget(appPayload);
        if (kDebugMode) {
          debugPrint('FCM: payload parsed -> target: ${target?.route ?? "fallback"}');
        }
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

  /// Requests notification permission on Android 13+ (API 33+).
  /// Uses Firebase Messaging's requestPermission which triggers the system
  /// POST_NOTIFICATIONS dialog. No-op on older Android; FCM token flow continues either way.
  static Future<void> _requestAndroidNotificationPermission() async {
    try {
      if (kDebugMode) {
        debugPrint('FCM: Requesting Android notification permission');
      }
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
      if (kDebugMode) {
        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          debugPrint('FCM: Android notification permission granted');
        } else {
          debugPrint('FCM: Android notification permission denied or not determined');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM: Android notification permission request error: $e');
      }
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
    String? imageUrl,
  }) async {
    Uint8List? imageBytes;
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      try {
        final uri = Uri.parse(imageUrl.trim());
        final httpClient = HttpClient();
        final request = await httpClient.getUrl(uri);
        final response = await request.close();
        if (response.statusCode == 200) {
          imageBytes = Uint8List.fromList(await consolidateHttpClientResponseBytes(response));
        }
        httpClient.close();
      } catch (_) {
        // Best-effort: ignore image download failures.
        imageBytes = null;
      }
    }

    final android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'App notifications',
      icon: 'notification_icon',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      ticker: 'notification',
      visibility: NotificationVisibility.public,
      largeIcon: imageBytes != null ? ByteArrayAndroidBitmap(imageBytes) : null,
    );
    final ios = DarwinNotificationDetails();
    final details = NotificationDetails(android: android, iOS: ios);
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
