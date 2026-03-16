import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/auth_providers.dart';
import 'core/config/app_config_provider.dart';
import 'core/fcm/fcm_service.dart';
import 'core/fcm/notification_payload.dart';
import 'core/fcm/pending_notification_provider.dart';
import 'core/localization/locale_provider.dart';
import 'core/network/connectivity_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/no_internet_screen.dart';
import 'features/auth/providers/auth_providers.dart';
import 'features/notifications/providers/notifications_list_provider.dart';
import 'features/notifications/providers/notifications_state_provider.dart';
import 'features/notifications/repositories/notifications_repository.dart';
import 'generated/l10n/app_localizations.dart';

void _setupFcmOnce(WidgetRef ref) {
  FcmService.setup(
    onNotificationTap: (target) {
      ref.read(pendingNotificationTargetProvider.notifier).setTarget(target);
    },
    onTokenReady: (_) {
      ref.read(authRepositoryProvider).updateFcmToken();
    },
    onForegroundMessage: (_) {
      // Best-effort: refresh the in-app notification center to reflect new events.
      ref.invalidate(notificationsListProvider);
    },
  );
}

void _listenPendingNotification(BuildContext context, WidgetRef ref) {
  ref.listen<NotificationNavigationTarget?>(
    pendingNotificationTargetProvider,
    (prev, next) {
      if (next == null) return;
      final notificationId = next.notificationId;
      if (notificationId != null && notificationId.isNotEmpty) {
        ref
            .read(locallyReadNotificationIdsProvider.notifier)
            .markRead(notificationId);
        // Best-effort backend sync.
        NotificationsRepositoryImpl().markRead(notificationId);
        ref.invalidate(notificationsListProvider);
      }
      ref.read(tokenStoreProvider).hasToken().then((hasToken) {
        if (!hasToken) {
          ref.read(pendingNotificationTargetProvider.notifier).clear();
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          final route = next.route.trim();
          if (route.isEmpty) {
            ref.read(pendingNotificationTargetProvider.notifier).clear();
            return;
          }
          try {
            final current = GoRouter.of(context).location;
            if (current != route) {
              context.go(route);
            }
          } catch (_) {
            try {
              context.go(route);
            } catch (_) {
              context.go(AppRoutes.notifications);
            }
          }
          ref.read(pendingNotificationTargetProvider.notifier).clear();
        });
      });
    },
  );
}

class ZayerApp extends ConsumerWidget {
  const ZayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final configAsync = ref.watch(bootstrapConfigProvider);
    final connectivity = ref.watch(connectivityProvider);
    final devMode = ref.watch(developmentModeProvider);

    final theme = configAsync.whenOrNull(
          data: (config) => AppTheme.fromConfig(config.theme),
        ) ??
        AppTheme.light;

    final textDirection =
        locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    final appTitle = configAsync.whenOrNull(
          data: (config) => config.appName?.trim().isNotEmpty == true
              ? config.appName!
              : null,
        ) ??
        'Eshterely';
 
    return MaterialApp.router(
      title: appTitle,
      theme: theme,
      debugShowCheckedModeBanner: false,
      locale: locale,
      builder: (context, child) {
        _setupFcmOnce(ref);
        _listenPendingNotification(context, ref);

        final content = Directionality(
          textDirection: textDirection,
          child: child ?? const SizedBox.shrink(),
        );
        final isOffline = connectivity.valueOrNull == false;
        return Stack(
          children: [
            content,
            if (isOffline)
              Positioned.fill(
                child: NoInternetScreen(
                  onRetry: () => ref.invalidate(connectivityProvider),
                ),
              ),
            if (devMode)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 4,
                  child: InkWell(
                    onTap: () => context.push(AppRoutes.devMode),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      color: Colors.deepPurple.shade700,
                      child: SafeArea(
                        bottom: false,
                        child: Row(
                          children: [
                            Icon(Icons.developer_mode, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'وضع التطوير',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: appRouter,
    );
  }
}
