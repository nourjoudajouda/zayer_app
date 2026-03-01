import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config_provider.dart';
import 'core/localization/locale_provider.dart';
import 'core/network/connectivity_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'generated/l10n/app_localizations.dart';

class ZayerApp extends ConsumerWidget {
  const ZayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final configAsync = ref.watch(bootstrapConfigProvider);
    final connectivity = ref.watch(connectivityProvider);

    final theme = configAsync.whenOrNull(
          data: (config) => AppTheme.fromConfig(config.theme),
        ) ??
        AppTheme.light;

    final textDirection =
        locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;

    return MaterialApp.router(
      title: 'Zayer',
      theme: theme,
      locale: locale,
      builder: (context, child) {
        final content = Directionality(
          textDirection: textDirection,
          child: child ?? const SizedBox.shrink(),
        );
        final isOffline = connectivity.valueOrNull == false;
        if (!isOffline) return content;
        return Stack(
          children: [
            content,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                elevation: 4,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  color: Colors.orange.shade700,
                  child: SafeArea(
                    bottom: false,
                    child: Text(
                      'No internet connection',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
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
