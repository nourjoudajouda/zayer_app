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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _countryCode = '966';
  String? _selectedCountryId;
  String? _selectedCityId;
  List<CountryItem> _countries = [];
  List<CityItem> _cities = [];
  bool _loadingCountries = true;
  bool _loadingCities = false;
  bool _countriesLoadError = false;
  bool _isCreatingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadCountries();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Map locale country code (e.g. IQ, JO) to dial_code for matching API countries.
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
    if (_selectedCountryId != null && _selectedCountryId!.isNotEmpty) {
      _loadCities(_selectedCountryId);
    }
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

  CountryItem? _countryById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final c in _countries) if (c.id == id) return c;
    return null;
  }

  CityItem? _cityById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final c in _cities) if (c.id == id) return c;
    return null;
  }

  Future<void> _loadCities(String? countryId) async {
    if (countryId == null || countryId.isEmpty) {
      setState(() {
        _cities = [];
        _loadingCities = false;
      });
      return;
    }
    setState(() {
      _loadingCities = true;
      _cities = [];
      _selectedCityId = null;
    });
    final repo = ref.read(authRepositoryProvider);
    final list = await repo.getCities(countryId: countryId);
    if (mounted) setState(() {
      _cities = list;
      _loadingCities = false;
    });
  }

  Future<void> _createAccount() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final digits = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    final phone = _countryCode + digits;
    if (phone.isEmpty) return;
    setState(() => _isCreatingAccount = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.register(
        phone: phone,
        fullName: _fullNameController.text.trim(),
        password: _passwordController.text,
        countryId: _selectedCountryId,
        cityId: _selectedCityId,
      );
      if (!mounted) return;
      switch (result) {
        case AuthSuccess():
          context.go(AppRoutes.home);
        case AuthRequiresOtp(:final phone, :final devOtp):
          final qp = <String, String>{
            'phone': phone,
            'mode': 'signup',
          };
          final label = formatAppCountryLabel(_countryById(_selectedCountryId));
          if (label != null && label.isNotEmpty) {
            qp['app_country'] = label;
          }
          if (devOtp != null && devOtp.isNotEmpty) {
            qp['dev_otp'] = devOtp;
          }
          context.go(Uri(path: AppRoutes.otp, queryParameters: qp).toString());
        case AuthFailure(:final message):
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isCreatingAccount = false);
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
        title: Text(l10n.joinZayer),
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
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.joinZayer,
                  style: AppTextStyles.headlineMedium(AppConfig.textColor),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.createAccountSubtitle,
                  style: AppTextStyles.bodyLarge(AppConfig.subtitleColor),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: l10n.fullName,
                    hintText: l10n.fullName,
                  ),
                  validator: (v) =>
                      v?.trim().isEmpty ?? true ? l10n.pleaseEnterFullName : null,
                ),
                const SizedBox(height: AppSpacing.md),
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
                                  _selectedCityId = null;
                                  _countryCode = (c != null && c.dialCode.isNotEmpty) ? c.dialCode : '966';
                                  if (c != null && c.id.isNotEmpty) _loadCities(c.id);
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
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return l10n.pleaseEnterPhone;
                          if (v.replaceAll(RegExp(r'\d'), '').isNotEmpty) return l10n.pleaseEnterPhone;
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.country, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor)),
                    const SizedBox(height: 4),
                    DropdownSearch<CountryItem>(
                      selectedItem: _countryById(_selectedCountryId),
                      items: (filter, loadProps) {
                        if (_countries.isEmpty) return <CountryItem>[];
                        if (filter.isEmpty) return _countries;
                        final f = filter.toLowerCase();
                        return _countries.where((c) => c.name.toLowerCase().contains(f)).toList();
                      },
                      itemAsString: (c) => '${c.flagEmoji} ${c.name}'.trim(),
                      compareFn: (a, b) => a.id == b.id,
                      onBeforePopupOpening: (_) async => _countries.isNotEmpty,
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.radiusSmall)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                      ),
                      dropdownBuilder: (context, selectedItem) => Text(
                        selectedItem != null ? '${selectedItem.flagEmoji} ${selectedItem.name}'.trim() : l10n.country,
                      ),
                      popupProps: PopupProps.modalBottomSheet(
                        showSearchBox: true,
                        itemBuilder: (context, item, isSelected, isHighlighted) => ListTile(
                          title: Text('${item.flagEmoji} ${item.name}'.trim()),
                        ),
                      ),
                      onChanged: (c) {
                        setState(() {
                          _selectedCountryId = c?.id;
                          _selectedCityId = null;
                          _countryCode = (c != null && c.dialCode.isNotEmpty) ? c.dialCode : '966';
                          if (c != null && c.id.isNotEmpty) _loadCities(c.id);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _loadingCities
                    ? InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.city,
                          suffixIcon: const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                          ),
                        ),
                        child: const Text('…'),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.city, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppConfig.subtitleColor)),
                          const SizedBox(height: 4),
                          DropdownSearch<CityItem>(
                            selectedItem: _cityById(_selectedCityId),
                            items: (filter, loadProps) {
                              if (_cities.isEmpty) return <CityItem>[];
                              if (filter.isEmpty) return _cities;
                              final f = filter.toLowerCase();
                              return _cities.where((c) => c.name.toLowerCase().contains(f)).toList();
                            },
                            itemAsString: (c) => c.name,
                            compareFn: (a, b) => a.id == b.id,
                            onBeforePopupOpening: (_) async => _cities.isNotEmpty,
                            decoratorProps: DropDownDecoratorProps(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConfig.radiusSmall)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                            ),
                            dropdownBuilder: (context, selectedItem) => Text(selectedItem?.name ?? l10n.city),
                            popupProps: PopupProps.modalBottomSheet(
                              showSearchBox: true,
                              itemBuilder: (context, item, isSelected, isHighlighted) => ListTile(title: Text(item.name)),
                            ),
                            onChanged: (c) => setState(() => _selectedCityId = c?.id),
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
                  validator: (v) {
                    if (v == null || v.isEmpty) return l10n.pleaseEnterPassword;
                    if (v.length < 8) return l10n.passwordReq8Chars;
                    if (!RegExp(r'[0-9]').hasMatch(v)) return l10n.passwordReqNumber;
                    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]').hasMatch(v)) return l10n.passwordReqSpecial;
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _PasswordRequirements(
                  l10n: l10n,
                  password: _passwordController.text,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: () {},
                  child: Text(l10n.haveReferralCode),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isCreatingAccount ? null : _createAccount,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConfig.radiusXLarge),
                      ),
                    ),
                    child: _isCreatingAccount
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(l10n.createAccount),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.alreadyHaveAccount,
                      style: AppTextStyles.bodyMedium(AppConfig.subtitleColor),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: Text(l10n.login),
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

class _PasswordRequirements extends StatelessWidget {
  const _PasswordRequirements({required this.l10n, required this.password});

  final AppLocalizations l10n;
  final String password;

  static bool _hasLength(String? s) => (s?.length ?? 0) >= 8;
  static bool _hasNumber(String? s) => s != null && RegExp(r'[0-9]').hasMatch(s);
  static bool _hasSpecial(String? s) =>
      s != null && RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]').hasMatch(s);

  @override
  Widget build(BuildContext context) {
    final ok = AppConfig.primaryColor;
    final pending = AppConfig.subtitleColor;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.borderColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RequirementRow(
            label: l10n.passwordReq8Chars,
            met: _hasLength(password),
            color: _hasLength(password) ? ok : pending,
          ),
          const SizedBox(height: 4),
          _RequirementRow(
            label: l10n.passwordReqNumber,
            met: _hasNumber(password),
            color: _hasNumber(password) ? ok : pending,
          ),
          const SizedBox(height: 4),
          _RequirementRow(
            label: l10n.passwordReqSpecial,
            met: _hasSpecial(password),
            color: _hasSpecial(password) ? ok : pending,
          ),
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({
    required this.label,
    required this.met,
    required this.color,
  });

  final String label;
  final bool met;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          met ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 20,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall(color),
          ),
        ),
      ],
    );
  }
}
