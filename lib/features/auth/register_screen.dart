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

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    final repo = ref.read(authRepositoryProvider);
    final list = await repo.getCountries();
    if (mounted) setState(() {
      _countries = list;
      _loadingCountries = false;
      if (_selectedCountryId == null && list.isNotEmpty) {
        _selectedCountryId = list.first.id;
        _countryCode = list.first.dialCode.isNotEmpty ? list.first.dialCode : '966';
      }
    });
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
        var path = '${AppRoutes.otp}?phone=${Uri.encodeComponent(phone)}&mode=signup';
        if (devOtp != null && devOtp.isNotEmpty) {
          path += '&dev_otp=${Uri.encodeComponent(devOtp)}';
        }
        context.go(path);
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
                      width: 120,
                      child: DropdownButtonFormField<String?>(
                        value: _selectedCountryId,
                        decoration: InputDecoration(
                          labelText: '',
                          hintText: '+966',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('—'),
                          ),
                          ..._countries.map(
                            (c) => DropdownMenuItem<String?>(
                              value: c.id,
                              child: Text('${c.flagEmoji} +${c.dialCode.isNotEmpty ? c.dialCode : c.id}'),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _selectedCountryId = v;
                            _selectedCityId = null;
                            final idx = v != null ? _countries.indexWhere((c) => c.id == v) : -1;
                            final country = idx >= 0 ? _countries[idx] : null;
                            _countryCode = (country != null && country.dialCode.isNotEmpty)
                                ? country.dialCode
                                : '966';
                            if (v != null && v.isNotEmpty) _loadCities(v);
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
                DropdownButtonFormField<String?>(
                  value: _selectedCountryId,
                  decoration: InputDecoration(
                    labelText: l10n.country,
                    hintText: l10n.country,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('— ${l10n.country} —'),
                    ),
                    ..._countries.map(
                      (c) => DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text('${c.flagEmoji} ${c.name}'.trim()),
                      ),
                    ).toList(),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _selectedCountryId = v;
                      _selectedCityId = null;
                      final idx = v != null ? _countries.indexWhere((c) => c.id == v) : -1;
                      final country = idx >= 0 ? _countries[idx] : null;
                      _countryCode = (country != null && country.dialCode.isNotEmpty)
                          ? country.dialCode
                          : '966';
                      if (v != null && v.isNotEmpty) _loadCities(v);
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String?>(
                  value: _loadingCities ? null : _selectedCityId,
                  decoration: InputDecoration(
                    labelText: l10n.city,
                    hintText: _loadingCities ? '' : l10n.city,
                    suffixIcon: _loadingCities
                        ? const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        _loadingCities ? '…' : '— ${l10n.city} —',
                      ),
                    ),
                    ..._cities.map(
                      (c) => DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    ),
                  ],
                  onChanged: _loadingCities
                      ? null
                      : (v) => setState(() => _selectedCityId = v),
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
                _PasswordRequirements(l10n: l10n),
                const SizedBox(height: AppSpacing.lg),
                TextButton(
                  onPressed: () {},
                  child: Text(l10n.haveReferralCode),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _createAccount,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConfig.radiusXLarge),
                      ),
                    ),
                    child: Text(l10n.createAccount),
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
  const _PasswordRequirements({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.borderColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.passwordReq8Chars,
            style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.passwordReqNumber,
            style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.passwordReqSpecial,
            style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
          ),
        ],
      ),
    );
  }
}
