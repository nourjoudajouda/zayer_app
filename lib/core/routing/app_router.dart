import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/cart/cart_empty_screen.dart';
import '../../features/placeholders/cart_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/markets/markets_screen.dart';
import '../../features/checkout/review_pay_screen.dart';
import '../../features/notifications/notification_settings_screen.dart';
import '../../features/notifications/notifications_list_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/orders/order_invoice_screen.dart';
import '../../features/orders/order_tracking_screen.dart';
import '../../features/orders/orders_list_screen.dart';
import '../../features/placeholders/coming_soon_screen.dart';
import '../../features/profile/add_edit_address_screen.dart';
import '../../features/security/active_sessions_screen.dart';
import '../../features/security/change_password_screen.dart';
import '../../features/security/security_access_screen.dart';
import '../../features/security/recent_activity_screen.dart';
import '../../features/security/two_factor_screen.dart';
import '../../features/profile/edit_date_of_birth_screen.dart';
import '../../features/profile/edit_profile_name_screen.dart';
import '../../features/profile/my_addresses_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/support/contact_support_screen.dart';
import '../../features/support/support_inbox_screen.dart';
import '../../features/support/support_request_submitted_screen.dart';
import '../../features/support/support_ticket_chat_screen.dart';
import '../../features/wallet/top_up_wallet_screen.dart';
import '../../features/wallet/wallet_screen.dart';
import '../../features/settings/default_warehouse_screen.dart';
import '../../features/settings/privacy_policy_screen.dart';
import '../../features/paste_link/paste_product_link_screen.dart';
import '../../features/product_import/confirm_product_screen.dart';
import '../../features/store_webview/models/detected_product.dart';
import '../../features/store_landing/store_landing_screen.dart';
import '../../features/store_webview/store_webview_screen.dart';

/// App route paths.
class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String markets = '/markets';
  static const String favorites = '/favorites';
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String orderDetail = '/order-detail';
  static const String orderTracking = '/order-tracking';
  static const String orderInvoice = '/order-invoice';
  static const String account = '/account';
  static const String storeLanding = '/store-landing';
  static const String store = '/store';
  static const String pasteLink = '/paste-link';
  static const String confirmProduct = '/confirm-product';
  static const String profile = '/profile';
  static const String editProfileName = '/profile/edit-name';
  static const String editDateOfBirth = '/profile/edit-dob';
  static const String myAddresses = '/my-addresses';
  static const String addEditAddress = '/add-edit-address';
  static const String settings = '/settings';
  static const String security = '/security';
  static const String changePassword = '/security/change-password';
  static const String activeSessions = '/security/active-sessions';
  static const String twoFactorAuth = '/security/two-factor';
  static const String recentActivity = '/security/recent-activity';
  static const String notifications = '/notifications';
  static const String notificationSettings = '/notification-settings';
  static const String reviewPay = '/review-pay';
  static const String paymentMethods = '/payment-methods';
  static const String supportInbox = '/support-inbox';
  static const String contactSupport = '/contact-support';
  static const String supportSuccess = '/support/success';
  static const String supportTicket = '/support/ticket';
  static const String wallet = '/wallet';
  static const String topUpWallet = '/wallet/top-up';
  static const String defaultWarehouse = '/settings/default-warehouse';
  static const String privacyPolicy = '/privacy-policy';
}

final GoRouter appRouter = _createAppRouter();

GoRouter _createAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'] ?? 'signup';
          return OtpScreen(mode: mode);
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(
          navigationShell: navigationShell,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.markets,
                pageBuilder: (context, state) {
                  final country = state.uri.queryParameters['country'];
                  return NoTransitionPage(
                    child: MarketsScreen(initialCountry: country),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.cart,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: CartScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: OrdersListScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.account,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.storeLanding,
        builder: (context, state) {
          final storeId = state.uri.queryParameters['storeId'];
          final storeName = state.uri.queryParameters['storeName'] ?? 'Store';
          final storeUrl = state.uri.queryParameters['storeUrl'] ?? 'https://www.amazon.com';
          return StoreLandingScreen(
            storeId: storeId,
            storeName: storeName,
            storeUrl: storeUrl,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.store,
        builder: (context, state) {
          final url = state.uri.queryParameters['url'] ?? '';
          return StoreWebViewScreen(initialUrl: url);
        },
      ),
      GoRoute(
        path: AppRoutes.pasteLink,
        builder: (context, state) => const PasteProductLinkScreen(),
      ),
      GoRoute(
        path: AppRoutes.confirmProduct,
        builder: (context, state) {
          final url = state.uri.queryParameters['url'];
          final productJson = state.uri.queryParameters['product'];
          
          DetectedProduct? product;
          if (productJson != null && productJson.isNotEmpty) {
            try {
              final productData = jsonDecode(Uri.decodeComponent(productJson)) as Map<String, dynamic>;
              product = DetectedProduct(
                storeKey: productData['storeKey'] as String,
                storeName: productData['storeName'] as String,
                productUrl: productData['productUrl'] as String,
                title: productData['title'] as String?,
                price: (productData['price'] as num?)?.toDouble(),
                currency: productData['currency'] as String? ?? 'USD',
                imageUrl: productData['imageUrl'] as String?,
                productId: productData['productId'] as String?,
              );
            } catch (e) {
              // If parsing fails, product will be null and screen will use mock data
              debugPrint('Failed to parse product data: $e');
            }
          }
          
          return ConfirmProductScreen(
            productUrl: url,
            product: product,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfileName,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return EditProfileNameScreen(
            initialFullLegalName: extra?['fullLegalName'] as String?,
            initialDisplayName: extra?['displayName'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.editDateOfBirth,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return EditDateOfBirthScreen(
            initialDateOfBirth: extra?['dateOfBirth'] as String?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.myAddresses,
        builder: (context, state) => const MyAddressesScreen(),
      ),
      GoRoute(
        path: AppRoutes.addEditAddress,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final isEdit = extra?['isEdit'] as bool? ?? false;
          return AddEditAddressScreen(
            isEdit: isEdit,
            addressId: extra?['addressId'] as String?,
            initialAddressLine: extra?['address'] as String?,
            initialCountryId: extra?['countryId'] as String?,
            initialCountryName: extra?['countryName'] as String?,
            initialCityId: extra?['cityId'] as String?,
            initialCityName: extra?['cityName'] as String?,
            initialPhone: extra?['phone'] as String?,
            initialIsDefault: extra?['isDefault'] as bool? ?? false,
            initialNickname: extra?['nickname'] as String?,
            initialAddressTypeIndex: extra?['addressType'] as int?,
            initialAreaDistrict: extra?['areaDistrict'] as String?,
            initialStreetAddress: extra?['streetAddress'] as String?,
            initialBuildingVillaSuite: extra?['buildingVillaSuite'] as String?,
            initialLat: (extra?['lat'] as num?)?.toDouble(),
            initialLng: (extra?['lng'] as num?)?.toDouble(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.security,
        builder: (context, state) => const SecurityAccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.activeSessions,
        builder: (context, state) => const ActiveSessionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.twoFactorAuth,
        builder: (context, state) => const TwoFactorScreen(),
      ),
      GoRoute(
        path: AppRoutes.recentActivity,
        builder: (context, state) => const RecentActivityScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.reviewPay,
        builder: (context, state) => const ReviewPayScreen(),
      ),
      GoRoute(
        path: AppRoutes.paymentMethods,
        builder: (context, state) => ComingSoonScreen(
          title: 'Payment Methods',
        ),
      ),
      GoRoute(
        path: AppRoutes.supportInbox,
        builder: (context, state) => const SupportInboxScreen(),
      ),
      GoRoute(
        path: AppRoutes.contactSupport,
        builder: (context, state) {
          final orderId = state.uri.queryParameters['orderId'];
          final extra = state.extra as Map<String, dynamic>?;
          return ContactSupportScreen(initialOrderId: orderId ?? extra?['orderId']?.toString());
        },
      ),
      GoRoute(
        path: '${AppRoutes.orderDetail}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return OrderDetailScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '${AppRoutes.orderTracking}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return OrderTrackingScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '${AppRoutes.orderInvoice}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return OrderInvoiceScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '${AppRoutes.supportTicket}/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return SupportTicketChatScreen(ticketId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.supportSuccess,
        builder: (context, state) {
          final ticketId = state.uri.queryParameters['ticketId'] ?? 'SUP-882910';
          return SupportRequestSubmittedScreen(ticketId: ticketId);
        },
      ),
      GoRoute(
        path: AppRoutes.wallet,
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: AppRoutes.topUpWallet,
        builder: (context, state) => const TopUpWalletScreen(),
      ),
      GoRoute(
        path: AppRoutes.defaultWarehouse,
        builder: (context, state) => const DefaultWarehouseScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
    ],
  );
}
