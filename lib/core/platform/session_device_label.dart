import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import '../../features/auth/device_name_for_api.dart';

/// Rich label for Sanctum session metadata (brand, model, OS version).
Future<String> sessionDeviceLabelForApi() async {
  if (kIsWeb) {
    final w = await DeviceInfoPlugin().webBrowserInfo;
    final v = w.appVersion ?? '';
    return '${w.browserName.name} ${v.isNotEmpty ? v : ''}'.trim();
  }
  final plugin = DeviceInfoPlugin();
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      final a = await plugin.androidInfo;
      final brand = (a.brand.isNotEmpty ? a.brand : a.manufacturer).trim();
      final model = a.model.trim();
      final release = a.version.release;
      return '$brand $model · Android $release';
    case TargetPlatform.iOS:
      final i = await plugin.iosInfo;
      return '${i.name} · ${i.model} · iOS ${i.systemVersion}';
    default:
      return deviceNameForApi();
  }
}
