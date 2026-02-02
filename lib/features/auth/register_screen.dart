import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/localization/app_locale.dart';
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
  String? _selectedCountry;
  String? _selectedCity;

  static const List<String> _countries = ['United States', 'Saudi Arabia', 'Egypt', 'UAE'];
  static const List<String> _cities = ['New York', 'Riyadh', 'Cairo', 'Dubai'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _createAccount() {
    if (_formKey.currentState?.validate() ?? false) {
      context.go(AppRoutes.otp);
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
                      width: 100,
                      child: DropdownButtonFormField<String>(
                        value: null,
                        decoration: InputDecoration(
                          labelText: '',
                          hintText: '+1',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: '+1', child: Text('+1')),
                          DropdownMenuItem(value: '+966', child: Text('+966')),
                          DropdownMenuItem(value: '+20', child: Text('+20')),
                        ],
                        onChanged: (_) {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: l10n.phoneNumber,
                          hintText: l10n.phoneNumberHint,
                        ),
                        validator: (v) =>
                            v?.trim().isEmpty ?? true ? l10n.pleaseEnterPhone : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String?>(
                  value: _selectedCountry,
                  decoration: InputDecoration(
                    labelText: l10n.country,
                    hintText: l10n.country,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.country),
                    ),
                    ..._countries.map(
                      (c) => DropdownMenuItem<String?>(value: c, child: Text(c)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedCountry = v),
                  validator: (v) =>
                      v == null ? l10n.pleaseSelectCountry : null,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String?>(
                  value: _selectedCity,
                  decoration: InputDecoration(
                    labelText: l10n.city,
                    hintText: l10n.city,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.city),
                    ),
                    ..._cities.map(
                      (c) => DropdownMenuItem<String?>(value: c, child: Text(c)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedCity = v),
                  validator: (v) => v == null ? l10n.pleaseSelectCity : null,
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
