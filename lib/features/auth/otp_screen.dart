import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import 'models/auth_result.dart';
import 'providers/auth_providers.dart';
import '../../core/localization/app_locale.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../generated/l10n/app_localizations.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({
    super.key,
    this.mode = 'signup',
    this.initialPhone = '',
    this.devOtp,
    this.appCountry,
  });

  /// signup | reset
  final String mode;
  /// Phone number from previous screen (register/forgot)
  final String initialPhone;
  /// When in debug mode, OTP returned by API (e.g. from register/forgot) to show on screen.
  final String? devOtp;
  /// Country label for session location (from login/register country picker).
  final String? appCountry;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _obscurePassword = true;
  int _resendSeconds = 55;
  Timer? _timer;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    for (var i = 0; i < _controllers.length; i++) {
      _controllers[i].addListener(_checkAutoVerify);
    }
    if (kDebugMode && widget.devOtp != null && widget.devOtp!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final digits = widget.devOtp!.replaceAll(RegExp(r'\D'), '');
        final code = digits.length >= 6
            ? digits.substring(0, 6)
            : digits.padRight(6, '0');
        for (var i = 0; i < 6 && i < _controllers.length; i++) {
          _controllers[i].text = code[i];
        }
      });
    }
  }

  void _checkAutoVerify() {
    if (_verifying) return;
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 6) {
      _verifying = true;
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _verify();
      });
    }
  }

  @override
  void dispose() {
    for (var i = 0; i < _controllers.length; i++) {
      _controllers[i].removeListener(_checkAutoVerify);
    }
    _timer?.cancel();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _maskPhone(String phone) {
    if (phone.isEmpty) return '••• ••• ••••';
    final len = phone.length;
    if (len <= 4) return '••• $phone';
    return '••• ••• ••${phone.substring(len - 4)}';
  }

  void _startResendTimer() {
    _resendSeconds = 55;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_resendSeconds <= 0) {
        _timer?.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _verify() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6) {
      if (mounted) setState(() => _verifying = false);
      return;
    }
    if (widget.mode == 'reset' && !(_formKey.currentState?.validate() ?? false)) {
      if (mounted) setState(() => _verifying = false);
      return;
    }
    if (mounted) setState(() => _verifying = true);
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.verifyOtp(
      phone: widget.initialPhone,
      code: otp,
      mode: widget.mode,
      password: widget.mode == 'reset' ? _passwordController.text : null,
      passwordConfirmation:
          widget.mode == 'reset' ? _passwordConfirmController.text : null,
      appCountry: widget.appCountry,
    );
    if (!mounted) return;
    setState(() => _verifying = false);
    switch (result) {
      case AuthSuccess():
        context.go(AppRoutes.home);
      case AuthRequiresOtp():
        break;
      case AuthFailure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
    }
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1) {
      _controllers[index].text = value;
      if (index < 5) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      }
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

  void _fillFromPaste(String digits) {
    final only = digits.replaceAll(RegExp(r'\D'), '');
    final code = only.length >= 6
        ? only.substring(0, 6)
        : only.padRight(6, '0');
    for (var i = 0; i < 6 && i < _controllers.length; i++) {
      _controllers[i].text = code[i];
    }
    FocusScope.of(context).requestFocus(_focusNodes[5]);
    setState(() {});
    _checkAutoVerify();
  }

  void _fillDebug123456() {
    const code = '123456';
    for (var i = 0; i < 6; i++) {
      _controllers[i].text = code[i];
    }
    FocusScope.of(context).requestFocus(_focusNodes[5]);
    setState(() => _verifying = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _verify();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(appLocaleProvider);

    return Directionality(
      textDirection: locale.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => context.pop(),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            ref.read(appLocaleProvider.notifier).state =
                                locale == AppLocale.en ? AppLocale.ar : AppLocale.en;
                          },
                          child: Text(locale == AppLocale.en ? 'EN' : 'AR'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.verifyPhoneNumber,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.weSentCodeTo,
                      style: AppTextStyles.bodyMedium(AppConfig.subtitleColor),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _PhonePreviewRow(
                      phone: _maskPhone(widget.initialPhone),
                      onEdit: () {
                        if (widget.mode == 'signup') {
                          context.go(AppRoutes.register);
                        } else if (widget.mode == 'login') {
                          context.go(AppRoutes.loginOtp);
                        } else {
                          context.go(AppRoutes.forgotPassword);
                        }
                      },
                    ),
                    if (kDebugMode && widget.devOtp != null && widget.devOtp!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _DevOtpBanner(otp: widget.devOtp!),
                    ],
                    if (kDebugMode && (widget.devOtp == null || widget.devOtp!.isEmpty)) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppConfig.warningOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Debug: OTP is shown when the API returns it (otp/code). Or use fixed code below.',
                              style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _fillDebug123456,
                              icon: const Icon(Icons.pin_outlined, size: 18),
                              label: const Text('Use 123456'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppConfig.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (widget.mode == 'reset') ...[
                      const SizedBox(height: AppSpacing.lg),
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
                      TextFormField(
                        controller: _passwordConfirmController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: l10n.confirmPassword,
                          hintText: l10n.passwordHint,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return l10n.pleaseEnterPassword;
                          if (v != _passwordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (i) => _OtpBox(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        onChanged: (v) => _onOtpChanged(i, v),
                        onPaste: _fillFromPaste,
                      )),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.resendIn,
                          style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                        ),
                        const SizedBox(width: 8),
                        _TimerBox(value: _resendSeconds ~/ 60),
                        Text(
                          ' : ',
                          style: AppTextStyles.bodyMedium(AppConfig.textColor),
                        ),
                        _TimerBox(value: _resendSeconds % 60),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _verifying ? null : _verify,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConfig.radiusXLarge),
                          ),
                        ),
                        icon: _verifying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check, size: 20),
                        label: Text(_verifying ? 'Verifying...' : l10n.verify),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.termsText,
                      style: AppTextStyles.bodySmall(AppConfig.subtitleColor),
                      textAlign: TextAlign.center,
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

class _PhonePreviewRow extends StatelessWidget {
  const _PhonePreviewRow({
    required this.phone,
    required this.onEdit,
  });

  final String phone;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppConfig.borderColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(Icons.phone_outlined, size: 20, color: AppConfig.subtitleColor),
          const SizedBox(width: 12),
          Expanded(child: Text(phone, style: AppTextStyles.bodyMedium(AppConfig.textColor))),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 20, color: AppConfig.primaryColor),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

class _OtpPasteFormatter extends TextInputFormatter {
  const _OtpPasteFormatter(this.onPaste);

  final void Function(String) onPaste;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      onPaste(digits);
      return oldValue;
    }
    if (digits.isEmpty) return newValue;
    return TextEditingValue(
      text: digits.substring(0, 1),
      selection: const TextSelection.collapsed(offset: 1),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onPaste,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final void Function(String) onPaste;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [
          _OtpPasteFormatter(onPaste),
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
            borderSide: BorderSide(color: AppConfig.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
            borderSide: BorderSide(color: AppConfig.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
            borderSide: BorderSide(color: AppConfig.primaryColor, width: 2),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _TimerBox extends StatelessWidget {
  const _TimerBox({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppConfig.borderColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value.toString().padLeft(2, '0'),
        style: AppTextStyles.titleMedium(AppConfig.textColor),
      ),
    );
  }
}

/// Shows OTP on screen in debug mode when API returns it (no SMS needed).
class _DevOtpBanner extends StatelessWidget {
  const _DevOtpBanner({required this.otp});

  final String otp;

  @override
  Widget build(BuildContext context) {
    final digits = otp.replaceAll(RegExp(r'\D'), '');
    final code = digits.length >= 6
        ? digits.substring(0, 6)
        : digits.padRight(6, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppConfig.successGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppConfig.radiusSmall),
        border: Border.all(color: AppConfig.successGreen.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.bug_report_outlined, color: AppConfig.successGreen, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Dev: OTP',
                  style: AppTextStyles.label(AppConfig.subtitleColor),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  code,
                  style: AppTextStyles.titleLarge(AppConfig.textColor).copyWith(
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
