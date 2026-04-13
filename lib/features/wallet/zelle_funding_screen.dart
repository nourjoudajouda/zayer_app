import 'package:cached_network_image/cached_network_image.dart';
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

/// Zelle: show destination first, user pays in bank app, then submits details here.
class ZelleFundingScreen extends ConsumerStatefulWidget {
  const ZelleFundingScreen({super.key});

  @override
  ConsumerState<ZelleFundingScreen> createState() => _ZelleFundingScreenState();
}

class _ZelleFundingScreenState extends ConsumerState<ZelleFundingScreen> {
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
      final map = <String, dynamic>{
        'amount': amt,
        if (_reference.text.trim().isNotEmpty) 'reference': _reference.text.trim(),
        if (em.isNotEmpty) 'sender_email': em,
        if (ph.isNotEmpty) 'sender_phone': ph,
        if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
      };
      if (_proof != null) {
        map['proof'] = await MultipartFile.fromFile(_proof!.path);
      }
      final fd = FormData.fromMap(map);
      await ApiClient.instance.post<void>(
        '/api/wallet/funding-requests/zelle',
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
          wireInstructions: '',
        );
    final hasDestination = wf.hasZelleDestination;
    final qr = wf.zelleReceiverQrUrl.trim();

    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Zelle'),
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
            Text(
              'Where to send your payment',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (hasDestination)
              _ZelleDestinationHero(config: wf, qrUrl: qr)
            else
              const _MissingDestinationBanner(),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppConfig.cardColor,
                borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
                border: Border.all(color: AppConfig.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'In your banking app',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '1. Send the payment with Zelle to the recipient above (scan QR or enter email/phone).\n'
                    '2. Come back here and complete the form so we can match your deposit.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.4,
                          color: AppConfig.subtitleColor,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Divider(color: AppConfig.borderColor),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Confirm your payment',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Expanded(
                  child: Divider(color: AppConfig.borderColor),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() => _apiFieldErrors.remove('amount')),
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
    );
  }
}

/// QR first (if configured), then recipient details — matches real banking-app flow.
class _ZelleDestinationHero extends StatelessWidget {
  const _ZelleDestinationHero({
    required this.config,
    required this.qrUrl,
  });

  final WalletFundingConfig config;
  final String qrUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.cardColor,
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
        border: Border.all(color: AppConfig.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (qrUrl.isNotEmpty) ...[
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: qrUrl,
                  width: 260,
                  height: 260,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(
                    width: 260,
                    height: 260,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Icon(Icons.qr_code_2, size: 64),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan with your bank app Zelle screen',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            qrUrl.isNotEmpty
                ? 'Or send manually to:'
                : 'Send Zelle to:',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppConfig.subtitleColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          if (config.zelleReceiverName.trim().isNotEmpty)
            _DestRow(
              icon: Icons.badge_outlined,
              label: 'Recipient name',
              value: config.zelleReceiverName.trim(),
            ),
          if (config.zelleReceiverEmail.trim().isNotEmpty)
            _DestRow(
              icon: Icons.email_outlined,
              label: 'Recipient email',
              value: config.zelleReceiverEmail.trim(),
            ),
          if (config.zelleReceiverPhone.trim().isNotEmpty)
            _DestRow(
              icon: Icons.phone_outlined,
              label: 'Recipient phone',
              value: config.zelleReceiverPhone.trim(),
            ),
        ],
      ),
    );
  }
}

class _DestRow extends StatelessWidget {
  const _DestRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppConfig.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppConfig.subtitleColor,
                      ),
                ),
                SelectableText(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
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

class _MissingDestinationBanner extends StatelessWidget {
  const _MissingDestinationBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.warningOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
        border: Border.all(
          color: AppConfig.warningOrange.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppConfig.warningOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Recipient details are not loaded in the app yet. '
              'Use the Zelle email or phone Zayer gave you, send the payment from your bank, '
              'then complete the form below.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
