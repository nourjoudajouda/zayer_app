import 'package:flutter/foundation.dart';

/// Human-readable device label for auth/session APIs (no dart:io — web-safe).
String deviceNameForApi() {
  if (kIsWeb) {
    return 'web';
  }
  return defaultTargetPlatform.name;
}
