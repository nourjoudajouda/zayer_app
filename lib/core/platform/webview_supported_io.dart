import 'dart:io';

/// Returns true only on Android and iOS.
/// webview_flutter has no platform implementation for Windows, Linux, or Web.
bool get isWebViewSupported => Platform.isAndroid || Platform.isIOS;
