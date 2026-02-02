import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/localization/app_locale.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/ui/zayer_primary_button.dart';
import '../../core/ui/zayer_text_field.dart';
import '../../generated/l10n/app_localizations.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendResetCode() {
    if (_formKey.currentState?.validate() ?? false) {
      context.go('${AppRoutes.otp}?mode=reset');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(appLocaleProvider);

    return Directionality(
      textDirection: locale.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.forgotPassword),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(appLocaleProvider.notifier).state =
                    locale == AppLocale.en ? AppLocale.ar : AppLocale.en;
              },
              child: Text(locale == AppLocale.en ? 'EN' : 'AR'),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.forgotPassword,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppConfig.textColor,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.resetCodeSentNote,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppConfig.subtitleColor,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ZayerTextField(
                    controller: _phoneController,
                    labelText: l10n.phoneNumber,
                    hintText: l10n.phoneNumberHint,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v?.trim().isEmpty ?? true ? l10n.pleaseEnterPhone : null,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ZayerPrimaryButton(
                    label: l10n.sendResetCode,
                    onPressed: _sendResetCode,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: Text(l10n.backToLogin),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
