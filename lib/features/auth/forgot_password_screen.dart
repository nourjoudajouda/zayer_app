import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import 'models/auth_result.dart';
import 'models/country_city.dart';
import 'providers/auth_providers.dart';
import '../../core/localization/app_locale.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
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
  String _countryCode = '966';
  List<CountryItem> _countries = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    final repo = ref.read(authRepositoryProvider);
    final list = await repo.getCountries();
    if (mounted) setState(() {
      _countries = list;
      if (list.isNotEmpty && _countryCode == '966') {
        final first = list.first;
        _countryCode = first.dialCode.isNotEmpty ? first.dialCode : '966';
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final digits = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    final phone = _countryCode + digits;
    if (phone.isEmpty) return;
    setState(() => _isSending = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.forgotPassword(phone: phone);
      if (!mounted) return;
      switch (result) {
        case AuthSuccess():
          context.go(AppRoutes.home);
        case AuthRequiresOtp(:final phone, :final devOtp):
          var path = '${AppRoutes.otp}?phone=${Uri.encodeComponent(phone)}&mode=reset';
          if (devOtp != null && devOtp.isNotEmpty) {
            path += '&dev_otp=${Uri.encodeComponent(devOtp)}';
          }
          context.go(path);
        case AuthFailure(:final message):
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: DropdownButtonFormField<String>(
                          value: _countries.any((c) => (c.dialCode.isNotEmpty ? c.dialCode : c.id) == _countryCode)
                              ? _countryCode
                              : (_countries.isNotEmpty ? (_countries.first.dialCode.isNotEmpty ? _countries.first.dialCode : _countries.first.id) : '966'),
                          decoration: InputDecoration(
                            labelText: '',
                            hintText: '+966',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                          ),
                          items: _countries.isEmpty
                              ? [
                                  const DropdownMenuItem(value: '966', child: Text('+966')),
                                  const DropdownMenuItem(value: '20', child: Text('+20')),
                                  const DropdownMenuItem(value: '1', child: Text('+1')),
                                ]
                              : _countries
                                  .map((c) => DropdownMenuItem<String>(
                                        value: c.dialCode.isNotEmpty ? c.dialCode : c.id,
                                        child: Text('${c.flagEmoji} +${c.dialCode.isNotEmpty ? c.dialCode : c.id}'),
                                      ))
                                  .toList(),
                          onChanged: (v) =>
                              setState(() => _countryCode = v ?? '966'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ZayerTextField(
                          controller: _phoneController,
                          labelText: l10n.phoneNumber,
                          hintText: l10n.phoneNumberHint,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return l10n.pleaseEnterPhone;
                            if (RegExp(r'\D').hasMatch(v)) return l10n.pleaseEnterPhone;
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSending ? null : _sendResetCode,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppConfig.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConfig.radiusXLarge),
                        ),
                      ),
                      child: _isSending
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(l10n.sendResetCode),
                    ),
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
