import 'package:go_router/go_router.dart';

import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/placeholders/cart_screen.dart';
import '../../features/placeholders/coming_soon_screen.dart';
import '../../features/markets/markets_screen.dart';
import '../../features/placeholders/orders_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/paste_link/paste_product_link_screen.dart';
import '../../features/product_import/confirm_product_screen.dart';
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
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String account = '/account';
  static const String storeLanding = '/store-landing';
  static const String store = '/store';
  static const String pasteLink = '/paste-link';
  static const String confirmProduct = '/confirm-product';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String security = '/security';
  static const String notifications = '/notifications';
  static const String paymentMethods = '/payment-methods';
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
                  child: OrdersScreen(),
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
          return ConfirmProductScreen(productUrl: url);
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.security,
        builder: (context, state) => ComingSoonScreen(
          title: 'Security Settings',
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => ComingSoonScreen(
          title: 'Notifications',
        ),
      ),
      GoRoute(
        path: AppRoutes.paymentMethods,
        builder: (context, state) => ComingSoonScreen(
          title: 'Payment Methods',
        ),
      ),
    ],
  );
}
