import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../../core/config/app_config.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/config/models/app_bootstrap_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_error_message.dart'
    show userFacingApiMessage, validationErrorsFromDio;
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';
import 'providers/funding_requests_provider.dart';
import 'providers/wallet_providers.dart';
import 'widgets/manual_funding_input_theme.dart';
import 'widgets/zelle_payment_instructions_view.dart';

/// Zelle step 2: proof and details after user paid in their bank app.
class ZelleSubmitScreen extends ConsumerStatefulWidget {
  const ZelleSubmitScreen({super.key});

  @override
  ConsumerState<ZelleSubmitScreen> createState() => _ZelleSubmitScreenState();
}

class _ZelleSubmitScreenState extends ConsumerState<ZelleSubmitScreen> {
  final _amount = TextEditingController(text: '100.00');
  final _reference = TextEditingController();
  final _senderEmail = TextEditingController();
  final _senderPhone = TextEditingController();
  final _notes = TextEditingController();
  XFile? _proof;
  bool _submitting = false;
  Map<String, String> _apiFieldErrors = {};

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _senderEmail.dispose();
    _senderPhone.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _showInstructionsSheet(WalletFundingConfig wf) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConfig.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final pad = MediaQuery.paddingOf(ctx).bottom;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                pad + AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ZellePaymentInstructionsView(config: wf),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickProof() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (f != null) {
      setState(() {
        _proof = f;
        _apiFieldErrors.remove('proof');
      });
    }
  }

  String? _validateBeforeSubmit() {
    final amt = double.tryParse(_amount.text.trim().replaceAll(',', ''));
    if (amt == null) {
      return 'Enter a valid amount in USD.';
    }
    if (amt < 1) {
      return 'Minimum amount is \$1.00.';
    }
    final em = _senderEmail.text.trim();
    final ph = _senderPhone.text.trim();
    if (em.isEmpty && ph.isEmpty) {
      return 'Enter the email or phone number you use with Zelle (sender side).';
    }
    if (em.isNotEmpty && !_looksLikeEmail(em)) {
      return 'Check the sender email format.';
    }
    if (ph.isNotEmpty && ph.length < 10) {
      return 'Enter a full phone number including area code.';
    }
    return null;
  }

  bool _looksLikeEmail(String s) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
  }

  Future<void> _submit() async {
    final msg = _validateBeforeSubmit();
    if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }
    final em = _senderEmail.text.trim();
    final ph = _senderPhone.text.trim();
    final amt = double.tryParse(_amount.text.trim().replaceAll(',', ''))!;
    setState(() {
      _submitting = true;
      _apiFieldErrors = {};
    });
    try {
      if (_proof != null) {
        final len = await _proof!.length();
        const maxBytes = 10 * 1024 * 1024;
        if (len > maxBytes) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Proof file must be 10 MB or smaller.'),
            ),
          );
          return;
        }
      }
      final map = <String, dynamic>{
        'amount': amt,
        if (_reference.text.trim().isNotEmpty) 'reference': _reference.text.trim(),
        if (em.isNotEmpty) 'sender_email': em,
        if (ph.isNotEmpty) 'sender_phone': ph,
        if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
      };
      if (_proof != null) {
        map['proof'] = await MultipartFile.fromFile(
          _proof!.path,
          filename: p.basename(_proof!.path),
        );
      }
      final fd = FormData.fromMap(map);
      await ApiClient.postMultipartFunding<void>(
        '/api/wallet/funding-requests/zelle',
        data: fd,
      );
      if (!mounted) return;
      ref.invalidate(fundingRequestsProvider);
      ref.invalidate(walletBalanceProvider);
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Request submitted. Our team will review it before crediting your wallet.',
          ),
        ),
      );
      context.go(AppRoutes.walletFundingHistory);
    } catch (e) {
      if (!mounted) return;
      final errs = validationErrorsFromDio(e);
      if (errs.isNotEmpty) {
        setState(() => _apiFieldErrors = errs);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingApiMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _err(String key) {
    final v = _apiFieldErrors[key];
    return v != null && v.isNotEmpty ? v : null;
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(bootstrapConfigProvider).valueOrNull;
    final wf = bootstrap?.walletFunding ??
        const WalletFundingConfig(
          zelleReceiverName: '',
          zelleReceiverEmail: '',
          zelleReceiverPhone: '',
          zelleReceiverQrUrl: '',
          zelleInstructionText: '',
          wireInstructions: '',
        );

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Zelle'),
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Recipient & QR',
            onPressed: () => _showInstructionsSheet(wf),
            icon: const Icon(Icons.qr_code_2_outlined),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.walletFundingHistory),
            child: const Text('History'),
          ),
        ],
      ),
      body: Theme(
        data: manualFundingInputTheme(context),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter your payment details so we can match your deposit.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConfig.subtitleColor,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => _showInstructionsSheet(wf),
                icon: const Icon(Icons.qr_code_2),
                label: const Text('View QR and recipient again'),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) =>
                    setState(() => _apiFieldErrors.remove('amount')),
                decoration: InputDecoration(
                  labelText: 'Amount you sent (USD)',
                  helperText: 'Must match the Zelle amount',
                  errorText: _err('amount'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _senderEmail,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) =>
                    setState(() => _apiFieldErrors.remove('sender_email')),
                decoration: InputDecoration(
                  labelText: 'Your Zelle sender email',
                  helperText: 'Use the email tied to your Zelle account',
                  errorText: _err('sender_email'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _senderPhone,
                keyboardType: TextInputType.phone,
                onChanged: (_) =>
                    setState(() => _apiFieldErrors.remove('sender_phone')),
                decoration: InputDecoration(
                  labelText: 'Your Zelle sender phone',
                  helperText: 'Use the phone tied to your Zelle account',
                  errorText: _err('sender_phone'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reference,
                onChanged: (_) =>
                    setState(() => _apiFieldErrors.remove('reference')),
                decoration: InputDecoration(
                  labelText: 'Bank memo / reference (optional)',
                  errorText: _err('reference'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                maxLines: 3,
                onChanged: (_) =>
                    setState(() => _apiFieldErrors.remove('notes')),
                decoration: InputDecoration(
                  labelText: 'Notes for our team (optional)',
                  errorText: _err('notes'),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickProof,
                icon: const Icon(Icons.upload_file),
                label: Text(
                  _proof == null
                      ? 'Upload screenshot or receipt (optional)'
                      : 'Proof file selected',
                ),
              ),
              if (_err('proof') != null) ...[
                const SizedBox(height: 4),
                Text(
                  _err('proof')!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit for review'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
