// ignore_for_file: unnecessary_null_comparison

import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  String? token = '';

  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

Future<void> initialNotification() async {
  // 1️⃣ Request permission first (iOS only matters)
  if (Platform.isIOS) {
    NotificationSettings settings =
        await firebaseMessaging.requestPermission(
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
      log('User declined notifications');
      return; // Stop here if user didn't allow
    }
  }

  // 2️⃣ Initialize local notifications
  var initializationSettingsAndroid =
      AndroidInitializationSettings('notification_icon');
  var initializationSettingsIOS = DarwinInitializationSettings();
  var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
    // onDidReceiveNotificationResponse: onSelectNotification,
  );

  // 3️⃣ Set foreground notification options (iOS)
  await firebaseMessaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // 4️⃣ Get the FCM token and subscribe to topic
  await getToken();

  // 5️⃣ Listen for messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Map data = message.data;

    // if (message.notification != null) {
    //   showNotification(
    //     message.notification!.title ?? '',
    //     message.notification!.body ?? '',
    //     data.toString(),
    //   );
    // }
  });
}

Future<String?> getToken() async {
  try {
    // iOS already requested permission in initialNotification
    token = await firebaseMessaging.getToken();
    log('FCM Token: $token');

    // Subscribe to topic AFTER token is available
    await firebaseMessaging.subscribeToTopic('all');
  } catch (e) {
    log('Error getting token: $e');
  }

  return token;
}
}
