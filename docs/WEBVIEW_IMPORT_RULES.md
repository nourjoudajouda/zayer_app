# WebView & Import Rules (Planned)

High-level rules for in-app store WebViews and the future “Add to Zayer Cart” / import pipeline. Not yet implemented in code; this doc defines the intended behavior for backend and app.

---

## 1. Store WebView

- **Route:** `/store?url=...` (encoded store URL).
- **Behavior:** Full-screen WebView loads the given URL. App bar has back button; optional future bottom overlay for “Add to Zayer Cart”.
- **Stores:** Served from admin (e.g. list of allowed store URLs or store keys). Home “Markets / Stores” can later be driven by API (e.g. `GET /api/stores`).

---

## 2. Allowed Stores / URL Rules (Planned)

- **Whitelist:** Only URLs belonging to configured stores (e.g. amazon.com, ebay.com, etc.) should be openable in the in-app WebView.
- **Rules (to be defined in backend):**
  - Store key (e.g. `amazon_us`).
  - Base URL pattern(s) (e.g. `https://www.amazon.com/*`, `https://amazon.com/*`).
  - Optional: country/market variants (e.g. amazon.ae, amazon.sa).
- **App:** Before opening `/store?url=...`, validate URL against allowed list; if invalid, show error or fallback.

---

## 3. PDP Detection (Product Detail Page) (Planned)

- **Goal:** Detect when the user is on a product page (PDP) so the app can show “Add to Zayer Cart” and extract product data.
- **Approach (high level):**
  - **URL patterns:** Per-store rules for PDP URLs (e.g. `/dp/`, `/gp/product/` for Amazon).
  - **Optional:** Backend endpoint that accepts current URL and returns whether it’s a PDP plus structured product info (title, price, image, etc.).
- **App:** When PDP is detected (by URL rule and/or API), show the bottom overlay and enable “Add to Zayer Cart”.

---

## 4. Import Pipeline (Planned)

- **Steps (high level):**
  1. User browses store in WebView and lands on a PDP.
  2. App detects PDP (URL + optional API).
  3. User taps “Add to Zayer Cart”.
  4. App sends to backend: store key, product URL, and optionally scraped or API-returned product fields.
  5. Backend validates URL, fetches/validates product, creates or updates “Zayer Cart” item (e.g. in DB), returns success/error.
  6. App shows confirmation and optionally updates cart badge or navigates to cart.
- **Security:** Validate and sanitize URLs and product data on backend; do not trust client-only scraping for pricing/availability.
- **Rate limiting / abuse:** Throttle add-to-cart and scraping endpoints per user/IP.

---

## 5. Account / Profile Independence

Account settings and profile (Profile & Compliance screen) are independent from the WebView import flow. Profile handles user info, KYC, address, and preferences. WebView import is for store browsing and "Add to Zayer Cart" only.

---

## 6. Store Directory Config

The store directory (Explore Markets screen) provides `store_id` and `store_url` used when opening WebView and by the future "Add to Zayer Cart" import pipeline. Store config comes from remote config or `GET /api/stores/:id`.

### 6.1 Paste Link & WebView Import Consistency

The Paste Product Link flow (Add via Link screen) must use the same store rules and parsing strategy as the WebView import. Supported stores, URL validation, and product extraction should be defined once in backend and shared by both: (1) in-app WebView PDP detection + "Add to Zayer Cart", and (2) Paste Link URL submission + preview API.

### 6.2 URL Normalization

URL normalization (canonicalization) is required before PDP detection and import. Amazon URLs must normalize to `https://www.amazon.com/dp/{ASIN}` to avoid wrong parsing from query params or extra path segments. The app implements `normalizeProductUrl()` for this; backend should apply the same rules and return `canonical_url` in the preview response.

---

## 6.2 URL Normalization (Canonicalization)

URL normalization is required before PDP detection and product import. Both WebView import and Paste Link must normalize URLs to ensure consistent product identification.

**Amazon:** Normalize all product URLs to `/dp/{ASIN}` format:
- Extract ASIN from `/dp/{ASIN}`, `/gp/product/{ASIN}`, `/product/{ASIN}`, or query params.
- Canonical form: `https://www.amazon.com/dp/{ASIN}`

**eBay:** Extract item ID from `/itm/{id}` or `item=...` query param when possible.

**Other stores:** Pass through but mark as `storeKey="unknown"` for manual fallback.

App-side normalization is implemented in `lib/core/import/normalize_url.dart`. Backend should also normalize and return `canonical_url` in preview response.

## 6.3 PDP Detection Implementation

**Current MVP Implementation:**
- PDP detection uses URL pattern matching in `WebViewImportRules` (`lib/features/store_webview/rules/webview_import_rules.dart`)
- Amazon: Detects `/dp/`, `/gp/product/`, `/product/` patterns (excludes search `/s?`, bestsellers, homepage)
- eBay: Detects `/itm/` pattern
- Future stores: Walmart `/ip/`, Etsy `/listing/`, AliExpress `/item/`

**Detection triggers:**
- `onPageStarted`, `onPageFinished`, and `onNavigationRequest` in WebView
- When PDP detected, overlay appears with detected product info (mock data)
- Overlay includes: green "DETECTED BY ZAYER" header, thumbnail, price, "Add to Zayer Cart", favorite button

**Scalability:**
- Rules engine supports per-store patterns
- Backend should provide rules via config (`GET /api/stores/:id/pdp-rules` or bootstrap)
- Future: JS injection for more complex detection (check DOM elements, structured data)

---

## 7. Current App Implementation

- **Implemented:** `StoreWebViewScreen` with `initialUrl`, back button, loading indicator, and a placeholder bottom overlay (hidden by default).
- **Not yet implemented:** Store whitelist, PDP detection, “Add to Zayer Cart” API, or import pipeline; these depend on backend and product rules defined above.

---

## 9. Backend TODOs (for reference)

- Define store list and URL rules (whitelist + PDP patterns).
- Implement PDP detection endpoint (optional) or document URL rules for app.
- Implement “Add to Zayer Cart” (or equivalent) API and import pipeline.
- Implement cart and order flows as needed.

---

## 10. Admin-Managed Store List & Product Import

- **Store list:** Admin-managed list of allowed stores (e.g. via `GET /api/stores` or bootstrap-config). Each store has: key, name, base URL patterns, PDP detection rules.
- **Product import triggers:** PDP detection rules per store (URL patterns like `/dp/`, `/gp/product/` for Amazon). Backend can expose rules in config or provide a `POST /detect-pdp` endpoint that accepts current URL and returns `{ "is_pdp": true, "product": {...} }`.
- **Data needed from backend for product import parsing:** Product URL, store key, title, price, image URL, availability. Backend validates and scrapes/fetches; app sends URL + store key, backend returns or persists product data.
