import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/app_config.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/config/models/app_bootstrap_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_error_message.dart'
    show userFacingApiMessage, validationErrorsFromDio;
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';

/// Submit a wire-transfer funding request (multipart).
class WireFundingScreen extends ConsumerStatefulWidget {
  const WireFundingScreen({super.key});

  @override
  ConsumerState<WireFundingScreen> createState() => _WireFundingScreenState();
}

class _WireFundingScreenState extends ConsumerState<WireFundingScreen> {
  final _amount = TextEditingController(text: '100.00');
  final _reference = TextEditingController();
  final _senderName = TextEditingController();
  final _senderEmail = TextEditingController();
  final _senderPhone = TextEditingController();
  final _bankName = TextEditingController();
  final _notes = TextEditingController();
  XFile? _proof;
  bool _submitting = false;
  Map<String, String> _apiFieldErrors = {};

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _senderName.dispose();
    _senderEmail.dispose();
    _senderPhone.dispose();
    _bankName.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickProof() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (f != null) setState(() => _proof = f);
  }

  bool _looksLikeEmail(String s) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
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
    if (em.isNotEmpty && !_looksLikeEmail(em)) {
      return 'Check the sender email format.';
    }
    return null;
  }

  Future<void> _submit() async {
    final err = _validateBeforeSubmit();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    final amt = double.tryParse(_amount.text.trim().replaceAll(',', ''))!;
    setState(() {
      _submitting = true;
      _apiFieldErrors = {};
    });
    try {
      final map = <String, dynamic>{
        'amount': amt,
        if (_reference.text.trim().isNotEmpty) 'reference': _reference.text.trim(),
        if (_senderName.text.trim().isNotEmpty) 'sender_name': _senderName.text.trim(),
        if (_senderEmail.text.trim().isNotEmpty) 'sender_email': _senderEmail.text.trim(),
        if (_senderPhone.text.trim().isNotEmpty) 'sender_phone': _senderPhone.text.trim(),
        if (_bankName.text.trim().isNotEmpty) 'bank_name': _bankName.text.trim(),
        if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
      };
      if (_proof != null) {
        map['proof'] = await MultipartFile.fromFile(_proof!.path);
      }
      final fd = FormData.fromMap(map);
      await ApiClient.instance.post<void>(
        '/api/wallet/funding-requests/wire',
        data: fd,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Request submitted. Our team will review it before crediting your wallet.',
          ),
        ),
      );
      Navigator.of(context).pop();
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
    final instructions = wf.wireInstructions.trim();

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Wire transfer'),
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => context.push(AppRoutes.walletFundingHistory),
            child: const Text('History'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WireInstructionPanel(instructions: instructions),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Send your bank transfer first using the details above, then submit this form so we can match your deposit.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() => _apiFieldErrors.remove('amount')),
              decoration: InputDecoration(
                labelText: 'Amount (USD)',
                helperText: 'Amount you wired',
                errorText: _err('amount'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reference,
              onChanged: (_) => setState(() => _apiFieldErrors.remove('reference')),
              decoration: InputDecoration(
                labelText: 'Transfer reference / confirmation (optional)',
                errorText: _err('reference'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _senderName,
              onChanged: (_) => setState(() => _apiFieldErrors.remove('sender_name')),
              decoration: InputDecoration(
                labelText: 'Sender name on the wire (optional)',
                errorText: _err('sender_name'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _senderEmail,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => setState(() => _apiFieldErrors.remove('sender_email')),
              decoration: InputDecoration(
                labelText: 'Sender email (optional)',
                errorText: _err('sender_email'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _senderPhone,
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() => _apiFieldErrors.remove('sender_phone')),
              decoration: InputDecoration(
                labelText: 'Sender phone (optional)',
                errorText: _err('sender_phone'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bankName,
              onChanged: (_) => setState(() => _apiFieldErrors.remove('bank_name')),
              decoration: InputDecoration(
                labelText: 'Sending bank name (optional)',
                errorText: _err('bank_name'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 3,
              onChanged: (_) => setState(() => _apiFieldErrors.remove('notes')),
              decoration: InputDecoration(
                labelText: 'Notes for our team (optional)',
                errorText: _err('notes'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickProof,
              icon: const Icon(Icons.upload_file),
              label: Text(_proof == null ? 'Upload proof (optional)' : 'Proof selected'),
            ),
            if (_err('proof') != null) ...[
              const SizedBox(height: 4),
              Text(
                _err('proof')!,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
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
    );
  }
}

class _WireInstructionPanel extends StatelessWidget {
  const _WireInstructionPanel({required this.instructions});

  final String instructions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
        border: Border.all(color: AppConfig.primaryColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wire instructions',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          if (instructions.isNotEmpty)
            SelectableText(
              instructions,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
            )
          else
            Text(
              'Bank routing and account details are provided by Zayer (email or support). '
              'Use those details in your bank app, then complete this form.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
            ),
        ],
      ),
    );
  }
}
