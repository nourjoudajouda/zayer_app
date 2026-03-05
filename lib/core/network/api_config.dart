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
