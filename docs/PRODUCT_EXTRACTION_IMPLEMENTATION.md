# Product Data Extraction Implementation

**Last Updated:** February 2026  
**Status:** ✅ IMPLEMENTED - Production Ready

## Overview
This document describes the **implemented** product data extraction system from various e-commerce stores using JavaScript injection in WebView. This feature is fully functional and ready for backend integration.

## Features Implemented

### 1. Multi-Store Support
The app supports product data extraction from multiple stores:
- **Amazon** - `/dp/{ASIN}`, `/gp/product/{ASIN}`
- **eBay** - `/itm/{id}`
- **Walmart** - `/ip/{product-name}`
- **Etsy** - `/listing/{id}`
- **AliExpress** - `/item/{id}.html` (URL normalization only)

### 2. Product Data Extraction
For each store, the app extracts:
- **Product Title** - Multiple selectors per store for reliability
- **Price** - With currency detection (USD, EUR, GBP, ILS)
- **Product Image** - With URL cleaning and validation
- **Product ID** - Store-specific identifiers (ASIN, Item ID, etc.)

### 3. Currency Conversion
- Automatic currency detection from price text
- Conversion to USD for consistent calculations
- Support for multiple currencies:
  - USD (1.0)
  - EUR (1.08)
  - GBP (1.27)
  - ILS/NIS/₪ (0.27) - Israeli Shekel
  - AED (0.27)
  - SAR (0.27)
  - EGP (0.032)

**Note:** Exchange rates are currently estimated. In production, use real-time rates from an API.

### 4. Image URL Cleaning
- Removes query parameters that might cause issues
- Converts relative URLs to absolute:
  - `//example.com/image.jpg` → `https://example.com/image.jpg`
  - `/image.jpg` → `https://domain.com/image.jpg`
- Validates URLs before use

### 5. Loading States
- **Page Loading** - Shows spinner while WebView loads
- **Extraction Loading** - Shows "Extracting product data..." message during data extraction
- **Product Detected** - Shows overlay with product details

### 6. Navigation Flow
1. User opens store in WebView
2. User navigates to product page
3. App detects PDP (Product Detail Page) via URL patterns
4. App extracts product data using JavaScript injection
5. App shows overlay with product details
6. User clicks "Add to Zayer Cart"
7. App navigates to Confirm Product screen
8. User confirms and adds to cart
9. App returns to Store Landing screen

## File Structure

```
lib/
├── features/
│   ├── store_webview/
│   │   ├── extractors/
│   │   │   └── product_data_extractor.dart  # JavaScript extraction scripts
│   │   ├── models/
│   │   │   └── detected_product.dart        # Product data model
│   │   ├── rules/
│   │   │   └── webview_import_rules.dart     # PDP detection rules
│   │   ├── widgets/
│   │   │   └── detected_product_overlay.dart # Product overlay UI
│   │   └── store_webview_screen.dart        # Main WebView screen
│   └── product_import/
│       └── confirm_product_screen.dart       # Product confirmation screen
└── core/
    └── import/
        └── normalize_url.dart                # URL normalization
```

## Implementation Details

### JavaScript Extraction Scripts
Each store has a dedicated extraction script in `product_data_extractor.dart`:
- `getAmazonExtractionScript()`
- `getEbayExtractionScript()`
- `getWalmartExtractionScript()`
- `getEtsyExtractionScript()`

Scripts are injected into WebView using `runJavaScriptReturningResult()`.

### PDP Detection
URL patterns are checked in `webview_import_rules.dart`:
- Amazon: `/dp/`, `/gp/product/`, `/product/`
- eBay: `/itm/`
- Walmart: `/ip/`
- Etsy: `/listing/`

### Data Flow
1. **URL Detection** → `WebViewImportRules.detectPdp(url)`
2. **Data Extraction** → `ProductDataExtractor.getExtractionScript(storeKey)`
3. **JavaScript Execution** → `runJavaScriptReturningResult(script)`
4. **Data Parsing** → `_parseProductData(jsonString)`
5. **UI Update** → `setState()` with `DetectedProduct`

## Backend Requirements

### API Endpoints Needed

#### 1. Exchange Rates API
```
GET /api/exchange-rates
Response: {
  "rates": {
    "USD": 1.0,
    "EUR": 1.08,
    "GBP": 1.27,
    "ILS": 0.27,
    ...
  },
  "lastUpdated": "2026-02-20T10:00:00Z"
}
```

#### 2. Product Import API
```
POST /api/products/import
Body: {
  "storeKey": "amazon",
  "productUrl": "https://www.amazon.com/dp/B08XYZ",
  "title": "Product Name",
  "price": 99.99,
  "currency": "USD",
  "imageUrl": "https://...",
  "productId": "B08XYZ"
}
Response: {
  "success": true,
  "productId": "zayer_product_123",
  "cartItemId": "cart_item_456"
}
```

#### 3. Cart Management API
```
POST /api/cart/add
Body: {
  "productId": "zayer_product_123",
  "quantity": 1
}
Response: {
  "success": true,
  "cartItemId": "cart_item_456",
  "cartTotal": 99.99
}
```

## Known Issues & Future Improvements

### Current Limitations
1. **Exchange Rates** - Using estimated rates, need real-time API
2. **Image URLs** - Some stores may have dynamic image URLs that change
3. **Price Extraction** - May fail on complex pricing structures (variants, discounts)
4. **Store Support** - Limited to stores with predictable URL patterns

### Future Enhancements
1. **Real-time Exchange Rates** - Integrate with exchange rate API
2. **More Stores** - Add support for more e-commerce platforms
3. **Price Tracking** - Track price changes over time
4. **Product Variants** - Support for products with multiple variants
5. **Backend Extraction** - Move extraction logic to backend for better reliability
6. **Caching** - Cache extracted product data to reduce API calls
7. **Error Handling** - Better error messages and retry mechanisms

## Testing Checklist

- [x] Amazon product extraction
- [x] eBay product extraction
- [x] Walmart product extraction
- [x] Etsy product extraction
- [x] Currency conversion (USD, EUR, GBP, ILS)
- [x] Image URL cleaning and validation
- [x] Loading states during extraction
- [x] Navigation flow after adding to cart
- [ ] Error handling for failed extractions
- [ ] Edge cases (missing data, invalid URLs)
- [ ] Performance testing with multiple products

## Notes for Backend Team

1. **Exchange Rates**: Implement `/api/exchange-rates` endpoint with real-time rates
2. **Product Import**: Create endpoint to save imported products
3. **Cart API**: Implement cart management endpoints
4. **Validation**: Validate product data before saving
5. **Rate Limiting**: Consider rate limiting for extraction requests
6. **Monitoring**: Monitor extraction success rates per store
7. **Fallback**: Consider backend extraction as fallback if client-side fails

## Code Examples

### Adding a New Store

1. Add extraction script in `product_data_extractor.dart`:
```dart
static String getNewStoreExtractionScript() {
  return '''
    (function() {
      // Extraction logic here
    })();
  ''';
}
```

2. Add URL normalization in `normalize_url.dart`:
```dart
if (host.contains('newstore.')) {
  final productId = _extractNewStoreProductId(uri);
  return NormalizedUrlResult(
    canonicalUrl: url,
    storeKey: 'newstore',
    productId: productId,
    wasModified: wasModified,
  );
}
```

3. Add PDP detection in `webview_import_rules.dart`:
```dart
if (normalized.storeKey == 'newstore') {
  if (_isNewStorePdp(url)) {
    return PdpDetectionResult(
      isPdp: true,
      product: DetectedProduct.mockNewStore(...),
    );
  }
}
```

4. Add to `getExtractionScript()`:
```dart
case 'newstore':
  return getNewStoreExtractionScript();
```
