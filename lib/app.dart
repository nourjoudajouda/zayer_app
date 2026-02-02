import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config_provider.dart';
import 'core/localization/locale_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'generated/l10n/app_localizations.dart';

class ZayerApp extends ConsumerWidget {
  const ZayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final configAsync = ref.watch(bootstrapConfigProvider);

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
      builder: (context, child) => Directionality(
        textDirection: textDirection,
        child: child ?? const SizedBox.shrink(),
      ),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: appRouter,
    );
  }
}
