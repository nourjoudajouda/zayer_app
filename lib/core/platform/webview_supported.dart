// Platform check for WebView support.
// webview_flutter only has implementations for Android and iOS.
// On Windows, Linux, and Web, no implementation is set → runtime crash if we use WebView.
// Use this to show a fallback UI instead of instantiating WebView on unsupported platforms.
import 'webview_supported_stub.dart'
    if (dart.library.io) 'webview_supported_io.dart' as impl;

bool get isWebViewSupported => impl.isWebViewSupported;
