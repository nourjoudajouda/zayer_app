# WebView & Import Rules

High-level rules for in-app store WebViews and "Add to Zayer Cart" / import pipeline. **Status: IMPLEMENTED** - Product extraction is now working for multiple stores. See `PRODUCT_EXTRACTION_IMPLEMENTATION.md` for detailed implementation.

---

## 1. Store WebView

- **Route:** `/store?url=...` (encoded store URL).
- **Behavior:** Full-screen WebView loads the given URL. App bar has back button; bottom overlay appears when product page is detected.
- **Stores:** Served from admin (e.g. list of allowed store URLs or store keys). Home "Markets / Stores" can later be driven by API (e.g. `GET /api/stores`).

---

## 2. Allowed Stores / URL Rules (Planned)

- **Whitelist:** Only URLs belonging to configured stores (e.g. amazon.com, ebay.com, etc.) should be openable in the in-app WebView.
- **Rules (to be defined in backend):**
  - Store key (e.g. `amazon_us`).
  - Base URL pattern(s) (e.g. `https://www.amazon.com/*`, `https://amazon.com/*`).
  - Optional: country/market variants (e.g. amazon.ae, amazon.sa).
- **App:** Before opening `/store?url=...`, validate URL against allowed list; if invalid, show error or fallback.

---

## 3. PDP Detection (Product Detail Page) ✅ IMPLEMENTED

- **Goal:** Detect when the user is on a product page (PDP) so the app can show "Add to Zayer Cart" and extract product data.
- **Approach (implemented):**
  - **URL patterns:** Per-store rules for PDP URLs (e.g. `/dp/`, `/gp/product/` for Amazon).
  - **JavaScript injection:** Real-time DOM extraction for product data (title, price, image, etc.).
  - **Backend endpoint (optional):** Can accept current URL and return whether it's a PDP plus structured product info.
- **App:** When PDP is detected (by URL rule), JavaScript extracts product data and shows the bottom overlay with "Add to Zayer Cart".

---

## 4. Import Pipeline ✅ IMPLEMENTED (Client-Side)

- **Steps (implemented):**
  1. User browses store in WebView and lands on a PDP.
  2. App detects PDP (URL pattern matching).
  3. App extracts product data using JavaScript injection.
  4. User taps "Add to Zayer Cart".
  5. App navigates to Confirm Product screen with extracted data.
  6. User confirms and adds to cart (currently mock).
  7. App returns to Store Landing screen.
- **Security:** Backend should validate and sanitize URLs and product data; do not trust client-only scraping for pricing/availability.
- **Rate limiting / abuse:** Backend should throttle add-to-cart and scraping endpoints per user/IP.

---

## 5. Account / Profile Independence

Account settings and profile (Profile & Compliance screen) are independent from the WebView import flow. Profile handles user info, KYC, address, and preferences. WebView import is for store browsing and "Add to Zayer Cart" only.

---

## 6. Store Directory Config

The store directory (Explore Markets screen) provides `store_id` and `store_url` used when opening WebView and by the "Add to Zayer Cart" import pipeline. Store config comes from remote config or `GET /api/stores/:id`.

### 6.1 Paste Link & WebView Import Consistency

The Paste Product Link flow (Add via Link screen) must use the same store rules and parsing strategy as the WebView import. Supported stores, URL validation, and product extraction should be defined once in backend and shared by both: (1) in-app WebView PDP detection + "Add to Zayer Cart", and (2) Paste Link URL submission + preview API.

### 6.2 URL Normalization ✅ IMPLEMENTED

URL normalization (canonicalization) is required before PDP detection and import. Amazon URLs must normalize to `https://www.amazon.com/dp/{ASIN}` to avoid wrong parsing from query params or extra path segments. The app implements `normalizeProductUrl()` for this; backend should apply the same rules and return `canonical_url` in the preview response.

**Implemented normalization:**
- Amazon: `/dp/{ASIN}`, `/gp/product/{ASIN}`, `/product/{ASIN}` → `https://www.amazon.com/dp/{ASIN}`
- eBay: `/itm/{id}` → Extract item ID
- Walmart: `/ip/{product-name}` → Extract product ID
- Etsy: `/listing/{id}` → Extract listing ID
- AliExpress: `/item/{id}.html` → Extract item ID

---

## 6.3 PDP Detection Implementation ✅ COMPLETED

**Current Implementation:**
- ✅ PDP detection uses URL pattern matching in `WebViewImportRules` (`lib/features/store_webview/rules/webview_import_rules.dart`)
- ✅ **Amazon**: Detects `/dp/`, `/gp/product/`, `/product/` patterns (excludes search `/s?`, bestsellers, homepage)
- ✅ **eBay**: Detects `/itm/` pattern
- ✅ **Walmart**: Detects `/ip/` pattern
- ✅ **Etsy**: Detects `/listing/` pattern
- ✅ **AliExpress**: Detects `/item/{id}.html` pattern (URL normalization only)

**Detection triggers:**
- `onPageStarted`, `onPageFinished`, and `onNavigationRequest` in WebView
- When PDP detected, overlay appears with **real extracted product data**
- Overlay includes: green "DETECTED BY ZAYER" header, product image, title, price with currency, "Add to Zayer Cart", favorite button
- Loading indicator shown during data extraction

**Product Data Extraction:**
- ✅ JavaScript injection for real-time data extraction from DOM
- ✅ Extracts: title, price, currency, image URL, product ID
- ✅ Supports multiple currencies: USD, EUR, GBP, ILS, AED, SAR, EGP
- ✅ Automatic currency conversion to USD for calculations
- ✅ Image URL cleaning and validation
- ✅ Per-store extraction scripts in `lib/features/store_webview/extractors/product_data_extractor.dart`

**Scalability:**
- Rules engine supports per-store patterns
- Backend should provide rules via config (`GET /api/stores/:id/pdp-rules` or bootstrap)
- ✅ JS injection implemented for DOM-based detection and data extraction

---

## 7. Current App Implementation ✅ IMPLEMENTED

**✅ IMPLEMENTED:**
- `StoreWebViewScreen` with `initialUrl`, back button, loading indicator
- ✅ **PDP Detection** - URL pattern matching for multiple stores
- ✅ **Product Data Extraction** - JavaScript injection for real product data
- ✅ **Product Overlay** - Shows extracted product details with image, price, currency
- ✅ **Loading States** - Page loading + extraction loading indicators
- ✅ **Currency Conversion** - Automatic conversion to USD with exchange rates
- ✅ **Image Handling** - URL cleaning, validation, caching with `CachedNetworkImage`
- ✅ **Navigation Flow** - Add to cart → Confirm screen → Return to store landing
- ✅ **Multi-Store Support** - Amazon, eBay, Walmart, Etsy, AliExpress

**⏳ PENDING (Backend Required):**
- Store whitelist validation
- "Add to Zayer Cart" API endpoint
- Product import pipeline (currently mock)
- Real-time exchange rates API
- Cart management API

---

## 9. Backend TODOs (for reference)

- ✅ Define store list and URL rules (whitelist + PDP patterns) - **App-side implemented**
- ⏳ Implement PDP detection endpoint (optional) or document URL rules for app - **App-side working, backend optional**
- ⏳ Implement "Add to Zayer Cart" (or equivalent) API and import pipeline - **Pending backend**
- ⏳ Implement cart and order flows as needed - **Pending backend**

---

## 10. Admin-Managed Store List & Product Import

- **Store list:** Admin-managed list of allowed stores (e.g. via `GET /api/stores` or bootstrap-config). Each store has: key, name, base URL patterns, PDP detection rules.
- **Product import triggers:** ✅ PDP detection rules per store (URL patterns like `/dp/`, `/gp/product/` for Amazon) - **Implemented in app**
- **Data extraction:** ✅ Client-side JavaScript extraction extracts product URL, store key, title, price, currency, image URL, product ID - **Implemented**
- **Backend validation:** ⏳ Backend should validate and scrape/fetch; app sends URL + store key + extracted data, backend returns or persists product data - **Pending backend**
