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

/// Collects phone number and requests login OTP, then navigates to [OtpScreen] with `mode=login`.
class LoginOtpPhoneScreen extends ConsumerStatefulWidget {
  const LoginOtpPhoneScreen({super.key});

  @override
  ConsumerState<LoginOtpPhoneScreen> createState() =>
      _LoginOtpPhoneScreenState();
}

class _LoginOtpPhoneScreenState extends ConsumerState<LoginOtpPhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _countryCode = '966';
  String? _selectedCountryId;
  List<CountryItem> _countries = [];
  bool _loadingCountries = true;
  bool _countriesLoadError = false;
  bool _sending = false;

  CountryItem? _countryById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final c in _countries) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  static const Map<String, String> _localeToDialCode = {
    'SA': '966',
    'IQ': '964',
    'JO': '962',
    'KW': '965',
    'BH': '973',
    'QA': '974',
    'AE': '971',
    'OM': '968',
    'YE': '967',
    'SY': '963',
    'LB': '961',
    'PS': '970',
    'EG': '20',
    'LY': '218',
    'TN': '216',
    'DZ': '213',
    'MA': '212',
    'SD': '249',
  };

  Future<void> _loadCountries() async {
    setState(() => _countriesLoadError = false);
    final repo = ref.read(authRepositoryProvider);
    List<CountryItem> list;
    try {
      list = await repo.getCountries();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingCountries = false;
          _countriesLoadError = true;
        });
      }
      return;
    }
    if (!mounted) return;
    final deviceCountryCode = _deviceCountryCode();
    CountryItem? toSelect;
    if (list.isNotEmpty) {
      if (deviceCountryCode != null) {
        final dial = _localeToDialCode[deviceCountryCode];
        for (final c in list) {
          if (c.id == deviceCountryCode ||
              (dial != null &&
                  (c.dialCode == dial || c.dialCode == '+$dial'))) {
            toSelect = c;
            break;
          }
        }
      }
      if (toSelect == null) {
        final iq = list.where((c) => c.dialCode == '964' || c.id == 'IQ');
        final jo = list.where((c) => c.dialCode == '962' || c.id == 'JO');
        toSelect = iq.isNotEmpty
            ? iq.first
            : (jo.isNotEmpty ? jo.first : list.first);
      }
    }
    setState(() {
      _countries = list;
      _loadingCountries = false;
      if (_selectedCountryId == null && toSelect != null) {
        _selectedCountryId = toSelect.id;
        _countryCode =
            toSelect.dialCode.isNotEmpty ? toSelect.dialCode : '966';
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
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final digits = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    final phone = _countryCode + digits;
    if (phone.isEmpty) return;
    setState(() => _sending = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.requestLoginOtp(phone: phone);
      if (!mounted) return;
      switch (result) {
        case AuthRequiresOtp(:final phone, :final devOtp):
          final q = <String, String>{
            'mode': 'login',
            'phone': phone,
          };
          final label = formatAppCountryLabel(_countryById(_selectedCountryId));
          if (label != null && label.isNotEmpty) {
            q['app_country'] = label;
          }
          if (devOtp != null && devOtp.isNotEmpty) {
            q['dev_otp'] = devOtp;
          }
          context.push(
            Uri(path: AppRoutes.otp, queryParameters: q).toString(),
          );
        case AuthFailure(:final message):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        case AuthSuccess():
          break;
      }
    } finally {
      if (mounted) setState(() => _sending = false);
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
          title: Text(l10n.loginWithOtp),
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
                    l10n.loginOtpSubtitle,
                    style: AppTextStyles.bodyMedium(AppConfig.subtitleColor),
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
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppConfig.radiusSmall,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.wifi_off,
                                      size: 20,
                                      color: Colors.orange.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        l10n.checkConnectionAndRetry,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _loadCountries,
                                      child: Text(l10n.retry),
                                    ),
                                  ],
                                ),
                              )
                            : _loadingCountries
                                ? InputDecorator(
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppConfig.radiusSmall,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 14,
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text('…'),
                                      ],
                                    ),
                                  )
                                : DropdownSearch<CountryItem>(
                                    selectedItem:
                                        _countryById(_selectedCountryId),
                                    items: (filter, loadProps) {
                                      if (_countries.isEmpty) {
                                        return <CountryItem>[];
                                      }
                                      if (filter.isEmpty) return _countries;
                                      final f = filter.toLowerCase();
                                      return _countries.where((c) {
                                        final code = c.dialCode.isNotEmpty
                                            ? c.dialCode
                                            : c.id;
                                        return code.contains(f) ||
                                            '${c.flagEmoji}+$code'
                                                .toLowerCase()
                                                .contains(f);
                                      }).toList();
                                    },
                                    itemAsString: (c) =>
                                        '${c.flagEmoji} +${c.dialCode.isNotEmpty ? c.dialCode : c.id}',
                                    compareFn: (a, b) => a.id == b.id,
                                    onBeforePopupOpening: (_) async =>
                                        _countries.isNotEmpty,
                                    dropdownBuilder:
                                        (context, selectedItem) => Text(
                                      selectedItem != null
                                          ? '${selectedItem.flagEmoji} +${selectedItem.dialCode.isNotEmpty ? selectedItem.dialCode : selectedItem.id}'
                                          : '+966',
                                    ),
                                    popupProps: PopupProps.modalBottomSheet(
                                      showSearchBox: true,
                                      itemBuilder: (context, item, isSelected,
                                              isHighlighted) =>
                                          ListTile(
                                        title: Text(
                                          '${item.flagEmoji} +${item.dialCode.isNotEmpty ? item.dialCode : item.id}',
                                        ),
                                      ),
                                    ),
                                    onChanged: (c) {
                                      setState(() {
                                        _selectedCountryId = c?.id;
                                        _countryCode = (c != null &&
                                                c.dialCode.isNotEmpty)
                                            ? c.dialCode
                                            : '966';
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
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _sending ? null : _sendOtp,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConfig.radiusXLarge,
                          ),
                        ),
                      ),
                      child: _sending
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(l10n.sendOtp),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: Text(l10n.login),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
