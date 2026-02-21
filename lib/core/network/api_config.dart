/// API base URL. Replace with your backend URL (e.g. from env/flavor).
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.zayer.com',
);

/// Cart items endpoint. POST to add item.
const String kCartItemsPath = '/api/cart/items';
