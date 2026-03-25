import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dropdown_search/dropdown_search.dart';

import '../../core/config/app_config.dart';
import '../../core/network/app_country_label.dart';
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
  String? _selectedCountryId;
  List<CountryItem> _countries = [];
  bool _loadingCountries = true;
  bool _countriesLoadError = false;
  bool _isLoggingIn = false;

  CountryItem? _countryById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final c in _countries) if (c.id == id) return c;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  static const Map<String, String> _localeToDialCode = {
    'SA': '966', 'IQ': '964', 'JO': '962', 'KW': '965', 'BH': '973',
    'QA': '974', 'AE': '971', 'OM': '968', 'YE': '967', 'SY': '963',
    'LB': '961', 'PS': '970', 'EG': '20', 'LY': '218', 'TN': '216',
    'DZ': '213', 'MA': '212', 'SD': '249',
  };

  Future<void> _loadCountries() async {
    setState(() => _countriesLoadError = false);
    final repo = ref.read(authRepositoryProvider);
    List<CountryItem> list;
    try {
      list = await repo.getCountries();
    } catch (_) {
      if (mounted) setState(() {
        _loadingCountries = false;
        _countriesLoadError = true;
      });
      return;
    }
    if (!mounted) return;
    final deviceCountryCode = _deviceCountryCode();
    CountryItem? toSelect;
    if (list.isNotEmpty) {
      if (deviceCountryCode != null) {
        final dial = _localeToDialCode[deviceCountryCode];
        for (final c in list) {
          if (c.id == deviceCountryCode || (dial != null && (c.dialCode == dial || c.dialCode == '+$dial'))) {
            toSelect = c;
            break;
          }
        }
      }
      if (toSelect == null) {
        final iq = list.where((c) => c.dialCode == '964' || c.id == 'IQ');
        final jo = list.where((c) => c.dialCode == '962' || c.id == 'JO');
        toSelect = iq.isNotEmpty ? iq.first : (jo.isNotEmpty ? jo.first : list.first);
      }
    }
    setState(() {
      _countries = list;
      _loadingCountries = false;
      if (_selectedCountryId == null && toSelect != null) {
        _selectedCountryId = toSelect.id;
        _countryCode = toSelect.dialCode.isNotEmpty ? toSelect.dialCode : '966';
      }
    });
  }

  String? _deviceCountryCode() {
    try {
      final locale = Platform.localeName;
      if (locale.contains('_')) return locale.split('_').last.toUpperCase();
      return null;
    } catch (_) {
      return null;
    }
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
    setState(() => _isLoggingIn = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.login(
        phone: phone,
        password: _passwordController.text,
        appCountry: formatAppCountryLabel(_countryById(_selectedCountryId)),
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
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
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
                      width: 150,
                      child: _countriesLoadError
                          ? InputDecorator(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.radiusSmall)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.wifi_off, size: 20, color: Colors.orange.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(l10n.checkConnectionAndRetry, style: TextStyle(fontSize: 12, color: Colors.orange.shade700))),
                                  TextButton(onPressed: _loadCountries, child: Text(l10n.retry)),
                                ],
                              ),
                            )
                          : _loadingCountries
                              ? InputDecorator(
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.radiusSmall)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  ),
                                  child: const Row(children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 8), Text('…')]),
                                )
                              : DropdownSearch<CountryItem>(
                              selectedItem: _countryById(_selectedCountryId),
                              items: (filter, loadProps) {
                                if (_countries.isEmpty) return <CountryItem>[];
                                if (filter.isEmpty) return _countries;
                                final f = filter.toLowerCase();
                                return _countries.where((c) {
                                  final code = c.dialCode.isNotEmpty ? c.dialCode : c.id;
                                  return code.contains(f) || '${c.flagEmoji}+$code'.toLowerCase().contains(f);
                                }).toList();
                              },
                              itemAsString: (c) => '${c.flagEmoji} +${c.dialCode.isNotEmpty ? c.dialCode : c.id}',
                              compareFn: (a, b) => a.id == b.id,
                              onBeforePopupOpening: (_) async => _countries.isNotEmpty,
                              dropdownBuilder: (context, selectedItem) => Text(
                                selectedItem != null
                                    ? '${selectedItem.flagEmoji} +${selectedItem.dialCode.isNotEmpty ? selectedItem.dialCode : selectedItem.id}'
                                    : '+966',
                              ),
                              popupProps: PopupProps.modalBottomSheet(
                                showSearchBox: true,
                                itemBuilder: (context, item, isSelected, isHighlighted) => ListTile(
                                  title: Text('${item.flagEmoji} +${item.dialCode.isNotEmpty ? item.dialCode : item.id}'),
                                ),
                              ),
                              onChanged: (c) {
                                setState(() {
                                  _selectedCountryId = c?.id;
                                  _countryCode = (c != null && c.dialCode.isNotEmpty) ? c.dialCode : '966';
                                });
                              },
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
                    onPressed: _isLoggingIn ? null : _login,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConfig.radiusXLarge),
                      ),
                    ),
                    child: _isLoggingIn
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(l10n.login),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => context.push(AppRoutes.loginOtp),
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
