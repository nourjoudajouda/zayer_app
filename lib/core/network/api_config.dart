/// Production API base (admin: https://eshterely.duosparktech.com/public/admin).
const String kProductionApiBaseUrl = 'https://eshterely.duosparktech.com/public';

/// API base URL. Set via --dart-define=API_BASE_URL=... or uses [kProductionApiBaseUrl].
/// - Production (default): https://eshterely.duosparktech.com/public
/// - Emulator: http://10.0.2.2
/// - Browser (Chrome): when default on web, ApiClient uses localhost:8000 for dev
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: kProductionApiBaseUrl,
);

/// Cart items path.
const String kCartItemsPath = '/api/cart/items';

/// Converts a relative avatar/asset URL from the API to an absolute URL.
/// Use when displaying images (e.g. CachedNetworkImageProvider) since the API
/// returns paths like `/storage/avatars/xxx.png` which need the base URL.
String? resolveAssetUrl(String? url, [String? baseUrl]) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  final base = (baseUrl ?? kApiBaseUrl).trim();
  final normalizedBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  final path = url.startsWith('/') ? url : '/$url';
  return '$normalizedBase$path';
}
