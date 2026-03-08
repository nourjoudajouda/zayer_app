import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zayer_app/core/fcm/fcm_helper_firebase.dart';

import 'core/config/app_config_provider.dart';
import 'core/localization/locale_provider.dart';
import 'core/network/connectivity_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/no_internet_screen.dart';
import 'generated/l10n/app_localizations.dart';

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
            NotificationHelper().initialNotification();

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
