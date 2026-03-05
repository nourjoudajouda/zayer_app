import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/localization/app_locale.dart';
import 'models/auth_result.dart';
import 'models/country_city.dart';
import 'providers/auth_providers.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../generated/l10n/app_localizations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _countryCode = '966';
  List<CountryItem> _countries = [];
  bool _loadingCountries = true;

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
      _loadingCountries = false;
      if (list.isNotEmpty && _countryCode == '966') {
        final first = list.first;
        _countryCode = first.dialCode.isNotEmpty ? first.dialCode : '966';
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final digits = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    final phone = _countryCode + digits;
    if (phone.isEmpty) return;
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.login(
      phone: phone,
      password: _passwordController.text,
    );
    if (!mounted) return;
    switch (result) {
      case AuthSuccess():
        context.go(AppRoutes.home);
      case AuthRequiresOtp():
        break; // Not used for login
      case AuthFailure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = ref.watch(languageProvider);

    return Directionality(
      textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
      appBar: AppBar(
        title: Text(l10n.login),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(appLocaleProvider.notifier).state =
                  ref.read(appLocaleProvider) == AppLocale.en
                      ? AppLocale.ar
                      : AppLocale.en;
            },
            child: Text(ref.watch(appLocaleProvider) == AppLocale.en ? 'EN' : 'AR'),
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
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.welcomeBack,
                  style: AppTextStyles.headlineMedium(AppConfig.textColor),
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
                        onChanged: (v) => setState(() => _countryCode = v ?? '966'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: l10n.phoneNumber,
                          hintText: l10n.phoneNumberHint,
                        ),
                        validator: (v) =>
                            v?.trim().isEmpty ?? true
                                ? l10n.pleaseEnterPhone
                                : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    hintText: l10n.passwordHint,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? l10n.pleaseEnterPassword : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                    child: Text(l10n.forgotPassword),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _login,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConfig.radiusXLarge),
                      ),
                    ),
                    child: Text(l10n.login),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => context.go(AppRoutes.otp),
                  child: Column(
                    children: [
                      Text(l10n.loginWithOtp),
                      Text(
                        l10n.noPasswordNeeded,
                        style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        l10n.orContinueWith,
                        style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.apple, size: 22),
                        label: Text(l10n.apple),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConfig.radiusSmall,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.g_mobiledata, size: 24),
                        label: Text(l10n.google),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppConfig.radiusSmall,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.alreadyHaveAccount,
                      style: AppTextStyles.bodyMedium(AppConfig.subtitleColor),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.register),
                      child: Text(l10n.createAccount),
                    ),
                  ],
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
