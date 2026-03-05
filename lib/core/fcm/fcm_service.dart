import 'fcm_service_io.dart' if (dart.library.html) 'fcm_service_web.dart' as impl;

/// Service to obtain FCM token for push notifications.
/// Returns null if Firebase is not configured or token cannot be obtained.
abstract class FcmService {
  Future<String?> getToken();
}

class FcmServiceImpl implements FcmService {
  @override
  Future<String?> getToken() async => impl.getFcmTokenInternal();
}
