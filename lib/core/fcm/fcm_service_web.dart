import 'package:firebase_messaging/firebase_messaging.dart';

Future<String?> getFcmTokenInternal() async {
  try {
    return await FirebaseMessaging.instance.getToken();
  } catch (_) {
    return null;
  }
}
