import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Full-screen "App under development". Shown when [development_mode] is true
/// from admin. User can only refresh; when admin turns off dev mode, app
/// navigates to register.
class UnderDevelopmentScreen extends ConsumerStatefulWidget {
  const UnderDevelopmentScreen({super.key});

  @override
  ConsumerState<UnderDevelopmentScreen> createState() =>
      _UnderDevelopmentScreenState();
}

class _UnderDevelopmentScreenState extends ConsumerState<UnderDevelopmentScreen> {
  bool _isRefreshing = false;

  Future<void> _refreshAndMaybeExit() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    bootstrapConfigRefresh(ref);
    try {
      await ref.read(bootstrapConfigProvider.future);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _isRefreshing = false);
    final devMode = ref.read(developmentModeProvider);
    if (!devMode) {
      if (mounted) context.go(AppRoutes.register);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction_outlined,
                size: 80,
                color: AppConfig.primaryColor.withValues(alpha: 0.8),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'التطبيق تحت التطوير',
                style: AppTextStyles.headlineMedium(AppConfig.textColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'نعمل على تحسين تجربتك. اسحب للتحديث أو اضغط الزر أدناه للتحقق من التحديثات.',
                style: AppTextStyles.bodyLarge(AppConfig.subtitleColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              FilledButton.icon(
                onPressed: _isRefreshing ? null : _refreshAndMaybeExit,
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_isRefreshing ? 'جاري التحقق...' : 'تحقق من التحديث'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
