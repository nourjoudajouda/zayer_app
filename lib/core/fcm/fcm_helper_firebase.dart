// ignore_for_file: unnecessary_null_comparison

import 'package:zayer_app/core/fcm/fcm_service.dart';

/// Legacy helper; FCM is now configured via [FcmService.setup] in the app.
/// [getToken] delegates to [FcmService.getToken].
@Deprecated('Use FcmService.getToken() and FcmService.setup() instead')
class NotificationHelper {
  Future<String?> getToken() => FcmService.getToken();
}
