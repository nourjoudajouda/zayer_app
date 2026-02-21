# Zayer App Documentation

This directory contains comprehensive documentation for the Zayer Flutter application.

## 📚 Documentation Files

### Core Documentation

1. **ADMIN_REMOTE_CONFIG.md**
   - Remote bootstrap configuration schema
   - Admin-controlled content (theme, splash, onboarding, stores)
   - API endpoint specifications for remote config
   - Localization rules and fallbacks

2. **API_TODO_CHECKLIST.md**
   - Phased API integration checklist
   - Endpoint specifications for all features
   - Request/response examples
   - Backend integration requirements

3. **WEBVIEW_IMPORT_RULES.md**
   - WebView store browsing rules
   - Product Detail Page (PDP) detection
   - URL normalization and validation
   - Store whitelist requirements

4. **PRODUCT_EXTRACTION_IMPLEMENTATION.md** ⭐ **NEW**
   - Complete implementation guide for product data extraction
   - Multi-store support (Amazon, eBay, Walmart, Etsy, AliExpress)
   - JavaScript injection scripts
   - Currency conversion and image handling
   - Backend API requirements
   - Code examples and testing checklist

5. **ANDROID_BUILD.md**
   - Android build configuration
   - Build instructions and requirements

## 🚀 Quick Start for Backend Team

### Priority 1: Product Extraction APIs
See `PRODUCT_EXTRACTION_IMPLEMENTATION.md` section "Backend Requirements":
- Exchange Rates API (`GET /api/exchange-rates`)
- Product Import API (`POST /api/products/import`)
- Cart Management API (`POST /api/cart/add`)

### Priority 2: Remote Config
See `ADMIN_REMOTE_CONFIG.md`:
- Bootstrap Config API (`GET /api/bootstrap-config`)
- Store Management APIs

### Priority 3: User & Profile
See `API_TODO_CHECKLIST.md` Phase 3:
- Auth endpoints
- Profile management
- Settings and preferences

## 📋 Implementation Status

### ✅ Completed Features
- Product data extraction from 5 stores (Amazon, eBay, Walmart, Etsy, AliExpress)
- Real-time JavaScript-based extraction
- Currency conversion (USD, EUR, GBP, ILS, AED, SAR, EGP)
- Image URL cleaning and validation
- Loading states and error handling
- Navigation flow (Add to cart → Confirm → Return to store)

### ⏳ Pending Backend Integration
- Exchange rates API (currently using estimated rates)
- Product import API (currently mock)
- Cart management API (currently mock)
- Store whitelist validation
- Real-time product validation

## 🔗 Related Files

- **App Code:** `lib/features/store_webview/` - WebView and extraction implementation
- **Models:** `lib/features/store_webview/models/` - Product data models
- **Extractors:** `lib/features/store_webview/extractors/` - JavaScript extraction scripts
- **Config:** `lib/core/config/` - Remote config implementation

## 📝 Notes

- All API endpoints should use **snake_case** for JSON fields (Laravel convention)
- Product extraction is client-side; backend should validate and sanitize all data
- Exchange rates are currently estimated; backend must provide real-time rates
- See individual documentation files for detailed specifications

## 🤝 Contributing

When adding new features:
1. Update relevant documentation files
2. Add API endpoint specifications to `API_TODO_CHECKLIST.md`
3. Update implementation status in this README
4. Add code examples if applicable
