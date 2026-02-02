/// Stub for platforms where dart:io is not available (e.g. web).
/// WebView is not supported on web when using webview_flutter.
bool get isWebViewSupported => false;
