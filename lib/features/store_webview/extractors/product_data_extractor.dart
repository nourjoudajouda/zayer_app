/// Product data extraction from different stores using JavaScript injection.
/// Each store has its own extraction logic based on DOM structure.
class ProductDataExtractor {
  /// Extract product data from Amazon
  static String getAmazonExtractionScript() {
    const dollarSign = r'$';
    return '''
      (function() {
        try {
          // Extract product title
          let title = null;
          const titleSelectors = [
            '#productTitle',
            'h1.a-size-large.product-title-word-break',
            'h1#title',
            '[data-feature-name="title"]',
            '.a-size-large.product-title-word-break',
          ];
          
          for (const selector of titleSelectors) {
            const element = document.querySelector(selector);
            if (element) {
              title = element.textContent?.trim() || element.innerText?.trim();
              if (title) break;
            }
          }

          // Extract price
          let price = null;
          let currency = 'USD';
          const priceSelectors = [
            '.a-price-whole',
            '.a-price .a-offscreen',
            '#priceblock_ourprice',
            '#priceblock_dealprice',
            '.a-price[data-a-color="price"] .a-offscreen',
            '.a-price .a-price-whole',
            '[data-a-color="price"] .a-offscreen',
            '.a-price.a-text-price .a-offscreen',
          ];

          for (const selector of priceSelectors) {
            const element = document.querySelector(selector);
            if (element) {
              let priceText = element.textContent?.trim() || element.innerText?.trim() || element.getAttribute('aria-label');
              
              if (!priceText && element.parentElement) {
                priceText = element.parentElement.textContent?.trim() || element.parentElement.innerText?.trim();
              }
              
              if (!priceText) {
                priceText = element.getAttribute('data-a-price') || element.getAttribute('data-price');
              }
              
              if (priceText) {
                const priceMatch = priceText.match(/[\\d,]+(?:\\.[\\d]{2})?/);
                if (priceMatch) {
                  price = parseFloat(priceMatch[0].replace(/,/g, ''));
                  
                  if (priceText.includes('$dollarSign') || priceText.includes('USD')) {
                    currency = 'USD';
                  } else if (priceText.includes('€') || priceText.includes('EUR')) {
                    currency = 'EUR';
                  } else if (priceText.includes('£') || priceText.includes('GBP')) {
                    currency = 'GBP';
                  } else if (priceText.includes('₪') || priceText.includes('ILS') || priceText.includes('NIS') || priceText.includes('שקל')) {
                    currency = 'ILS';
                  }
                  
                  if (price && !isNaN(price)) break;
                }
              }
            }
          }

          // Extract product image
          let imageUrl = null;
          const imageSelectors = [
            '#landingImage',
            '#imgBlkFront',
            '#main-image',
            '.a-dynamic-image',
            '[data-a-image-name="landingImage"]',
            'img[data-old-hires]',
          ];

          for (const selector of imageSelectors) {
            const element = document.querySelector(selector);
            if (element) {
              imageUrl = element.src || element.getAttribute('data-old-hires') || element.getAttribute('data-src');
              
              // Clean and validate image URL
              if (imageUrl) {
                // Remove query parameters that might cause issues
                imageUrl = imageUrl.split('?')[0];
                
                // Convert relative URLs to absolute
                if (imageUrl.startsWith('//')) {
                  imageUrl = 'https:' + imageUrl;
                } else if (imageUrl.startsWith('/')) {
                  imageUrl = window.location.origin + imageUrl;
                }
                
                // Only use if it's a valid HTTP(S) URL
                if (imageUrl.startsWith('http')) {
                  break;
                }
              }
            }
          }

          // Extract ASIN
          let productId = null;
          const urlMatch = window.location.href.match(/\\/dp\\/([A-Z0-9]{10})/);
          if (urlMatch) {
            productId = urlMatch[1];
          } else {
            const asinElement = document.querySelector('[data-asin]');
            if (asinElement) {
              productId = asinElement.getAttribute('data-asin');
            }
          }

          return JSON.stringify({
            success: true,
            title: title,
            price: price,
            currency: currency,
            imageUrl: imageUrl,
            productId: productId,
          });
        } catch (error) {
          return JSON.stringify({
            success: false,
            error: error.toString(),
          });
        }
      })();
    ''';
  }

  /// Extract product data from eBay
  static String getEbayExtractionScript() {
    const dollarSign = r'$';
    return '''
      (function() {
        try {
          // Extract product title
          let title = null;
          const titleSelectors = [
            '#x-item-title-label',
            'h1[itemprop="name"]',
            'h1.it-ttl',
            '.x-item-title-label',
            'h1',
          ];
          
          for (const selector of titleSelectors) {
            const element = document.querySelector(selector);
            if (element) {
              title = element.textContent?.trim() || element.innerText?.trim();
              if (title) break;
            }
          }

          // Extract price
          let price = null;
          let currency = 'USD';
          const priceSelectors = [
            '#prcIsum',
            '.notranslate',
            '[itemprop="price"]',
            '.u-flL.condText',
            '.notranslate.mm-price',
          ];

          for (const selector of priceSelectors) {
            const element = document.querySelector(selector);
            if (element) {
              let priceText = element.textContent?.trim() || element.innerText?.trim() || element.getAttribute('content');
              
              if (!priceText && element.parentElement) {
                priceText = element.parentElement.textContent?.trim() || element.parentElement.innerText?.trim();
              }
              
              if (priceText) {
                const priceMatch = priceText.match(/[\\d,]+(?:\\.[\\d]{2})?/);
                if (priceMatch) {
                  price = parseFloat(priceMatch[0].replace(/,/g, ''));
                  
                  if (priceText.includes('$dollarSign') || priceText.includes('USD')) {
                    currency = 'USD';
                  } else if (priceText.includes('€') || priceText.includes('EUR')) {
                    currency = 'EUR';
                  } else if (priceText.includes('£') || priceText.includes('GBP')) {
                    currency = 'GBP';
                  } else if (priceText.includes('₪') || priceText.includes('ILS') || priceText.includes('NIS') || priceText.includes('שקל')) {
                    currency = 'ILS';
                  }
                  
                  if (price && !isNaN(price)) break;
                }
              }
            }
          }

          // Extract product image
          let imageUrl = null;
          const imageSelectors = [
            '#icImg',
            '#vi_main_img_fs',
            '.img.img500',
            '[itemprop="image"]',
            'img[data-testid="product-image"]',
          ];

          for (const selector of imageSelectors) {
            const element = document.querySelector(selector);
            if (element) {
              imageUrl = element.src || element.getAttribute('data-src') || element.getAttribute('data-zoom-src');
              
              // Clean and validate image URL
              if (imageUrl) {
                imageUrl = imageUrl.split('?')[0];
                if (imageUrl.startsWith('//')) {
                  imageUrl = 'https:' + imageUrl;
                } else if (imageUrl.startsWith('/')) {
                  imageUrl = window.location.origin + imageUrl;
                }
                if (imageUrl.startsWith('http')) break;
              }
            }
          }

          // Extract item ID
          let productId = null;
          const urlMatch = window.location.href.match(/\\/itm\\/(\\d+)/);
          if (urlMatch) {
            productId = urlMatch[1];
          } else {
            const itemIdElement = document.querySelector('[data-item-id]');
            if (itemIdElement) {
              productId = itemIdElement.getAttribute('data-item-id');
            }
          }

          return JSON.stringify({
            success: true,
            title: title,
            price: price,
            currency: currency,
            imageUrl: imageUrl,
            productId: productId,
          });
        } catch (error) {
          return JSON.stringify({
            success: false,
            error: error.toString(),
          });
        }
      })();
    ''';
  }

  /// Extract product data from Walmart
  static String getWalmartExtractionScript() {
    const dollarSign = r'$';
    return '''
      (function() {
        try {
          // Extract product title
          let title = null;
          const titleSelectors = [
            'h1[itemprop="name"]',
            'h1.prod-ProductTitle',
            '[data-automation-id="product-title"]',
            'h1',
          ];
          
          for (const selector of titleSelectors) {
            const element = document.querySelector(selector);
            if (element) {
              title = element.textContent?.trim() || element.innerText?.trim();
              if (title) break;
            }
          }

          // Extract price
          let price = null;
          let currency = 'USD';
          const priceSelectors = [
            '[itemprop="price"]',
            '.price-current',
            '[data-automation-id="product-price"]',
            '.prod-PriceHero .price',
          ];

          for (const selector of priceSelectors) {
            const element = document.querySelector(selector);
            if (element) {
              let priceText = element.textContent?.trim() || element.innerText?.trim() || element.getAttribute('content');
              
              if (!priceText && element.parentElement) {
                priceText = element.parentElement.textContent?.trim() || element.parentElement.innerText?.trim();
              }
              
              if (priceText) {
                const priceMatch = priceText.match(/[\\d,]+(?:\\.[\\d]{2})?/);
                if (priceMatch) {
                  price = parseFloat(priceMatch[0].replace(/,/g, ''));
                  
                  if (priceText.includes('$dollarSign') || priceText.includes('USD')) {
                    currency = 'USD';
                  }
                  
                  if (price && !isNaN(price)) break;
                }
              }
            }
          }

          // Extract product image
          let imageUrl = null;
          const imageSelectors = [
            '[data-automation-id="product-image"]',
            '.prod-hero-image img',
            '[itemprop="image"]',
            '.prod-hero-image-container img',
          ];

          for (const selector of imageSelectors) {
            const element = document.querySelector(selector);
            if (element) {
              imageUrl = element.src || element.getAttribute('data-src') || element.getAttribute('data-lazy-src');
              
              // Clean and validate image URL
              if (imageUrl) {
                imageUrl = imageUrl.split('?')[0];
                if (imageUrl.startsWith('//')) {
                  imageUrl = 'https:' + imageUrl;
                } else if (imageUrl.startsWith('/')) {
                  imageUrl = window.location.origin + imageUrl;
                }
                if (imageUrl.startsWith('http')) break;
              }
            }
          }

          // Extract product ID
          let productId = null;
          const urlMatch = window.location.href.match(/\\/ip\\/([^\\/]+)/);
          if (urlMatch) {
            productId = urlMatch[1];
          }

          return JSON.stringify({
            success: true,
            title: title,
            price: price,
            currency: currency,
            imageUrl: imageUrl,
            productId: productId,
          });
        } catch (error) {
          return JSON.stringify({
            success: false,
            error: error.toString(),
          });
        }
      })();
    ''';
  }

  /// Extract product data from Etsy
  static String getEtsyExtractionScript() {
    const dollarSign = r'$';
    return '''
      (function() {
        try {
          // Extract product title
          let title = null;
          const titleSelectors = [
            'h1[data-buy-box-listing-title]',
            'h1.wt-text-body-01',
            'h1',
          ];
          
          for (const selector of titleSelectors) {
            const element = document.querySelector(selector);
            if (element) {
              title = element.textContent?.trim() || element.innerText?.trim();
              if (title) break;
            }
          }

          // Extract price
          let price = null;
          let currency = 'USD';
          const priceSelectors = [
            '.wt-text-title-larger',
            '[data-buy-box-region] .wt-text-title-larger',
            '.wt-text-title-03',
          ];

          for (const selector of priceSelectors) {
            const element = document.querySelector(selector);
            if (element) {
              let priceText = element.textContent?.trim() || element.innerText?.trim();
              
              if (priceText) {
                const priceMatch = priceText.match(/[\\d,]+(?:\\.[\\d]{2})?/);
                if (priceMatch) {
                  price = parseFloat(priceMatch[0].replace(/,/g, ''));
                  
                  if (priceText.includes('$dollarSign') || priceText.includes('USD')) {
                    currency = 'USD';
                  } else if (priceText.includes('€') || priceText.includes('EUR')) {
                    currency = 'EUR';
                  } else if (priceText.includes('£') || priceText.includes('GBP')) {
                    currency = 'GBP';
                  } else if (priceText.includes('₪') || priceText.includes('ILS') || priceText.includes('NIS') || priceText.includes('שקל')) {
                    currency = 'ILS';
                  }
                  
                  if (price && !isNaN(price)) break;
                }
              }
            }
          }

          // Extract product image
          let imageUrl = null;
          const imageSelectors = [
            '#listing-page-image',
            '.wt-max-width-full',
            '[data-buy-box-listing-image] img',
          ];

          for (const selector of imageSelectors) {
            const element = document.querySelector(selector);
            if (element) {
              imageUrl = element.src || element.getAttribute('data-src');
              
              // Clean and validate image URL
              if (imageUrl) {
                imageUrl = imageUrl.split('?')[0];
                if (imageUrl.startsWith('//')) {
                  imageUrl = 'https:' + imageUrl;
                } else if (imageUrl.startsWith('/')) {
                  imageUrl = window.location.origin + imageUrl;
                }
                if (imageUrl.startsWith('http')) break;
              }
            }
          }

          // Extract listing ID
          let productId = null;
          const urlMatch = window.location.href.match(/\\/listing\\/(\\d+)/);
          if (urlMatch) {
            productId = urlMatch[1];
          }

          return JSON.stringify({
            success: true,
            title: title,
            price: price,
            currency: currency,
            imageUrl: imageUrl,
            productId: productId,
          });
        } catch (error) {
          return JSON.stringify({
            success: false,
            error: error.toString(),
          });
        }
      })();
    ''';
  }

  /// Get extraction script based on store key
  static String? getExtractionScript(String storeKey) {
    switch (storeKey.toLowerCase()) {
      case 'amazon':
        return getAmazonExtractionScript();
      case 'ebay':
        return getEbayExtractionScript();
      case 'walmart':
        return getWalmartExtractionScript();
      case 'etsy':
        return getEtsyExtractionScript();
      default:
        return null;
    }
  }
}
