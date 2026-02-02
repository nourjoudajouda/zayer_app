import 'dart:async';

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

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, this.mode = 'signup'});

  /// signup | reset
  final String mode;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _resendSeconds = 55;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
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

  void _verify() {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 6) {
      context.go(AppRoutes.home);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(appLocaleProvider);

    return Directionality(
      textDirection: locale.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppConfig.borderColor.withValues(alpha: 0.3),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConfig.radiusXLarge),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
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
                      phone: '+1 234 ••• ••89',
                      onEdit: () => context.pop(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (i) => _OtpBox(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        onChanged: (v) => _onOtpChanged(i, v),
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
                        onPressed: _verify,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConfig.radiusXLarge),
                          ),
                        ),
                        icon: const Icon(Icons.check, size: 20),
                        label: Text(l10n.verify),
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

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

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
