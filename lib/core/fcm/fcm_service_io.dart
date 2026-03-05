import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

Future<String?> getFcmTokenInternal() async {
  try {
    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return null;
      }
    }
    return await FirebaseMessaging.instance.getToken();
  } catch (_) {
    return null;
  }
}
