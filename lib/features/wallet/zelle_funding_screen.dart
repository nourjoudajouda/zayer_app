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
import '../../core/network/api_error_message.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_spacing.dart';

/// Submit a Zelle funding request after sending payment to the configured recipient.
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
    if (f != null) setState(() => _proof = f);
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
    setState(() => _submitting = true);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingApiMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
            _InstructionPanel(hasDestination: hasDestination),
            const SizedBox(height: AppSpacing.md),
            if (hasDestination) _DestinationCard(config: wf) else _MissingDestinationBanner(),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'After you have sent the payment, tell us the details below so we can match your deposit.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.subtitleColor,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount you sent (USD)',
                helperText: 'Must match the Zelle amount',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _senderEmail,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Your Zelle sender email',
                helperText: 'Required if you sent from email',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _senderPhone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Your Zelle sender phone',
                helperText: 'Required if you sent from phone',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reference,
              decoration: const InputDecoration(
                labelText: 'Bank reference / memo (optional)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes for our team (optional)',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickProof,
              icon: const Icon(Icons.upload_file),
              label: Text(_proof == null ? 'Upload proof screenshot (optional)' : 'Proof file selected'),
            ),
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

class _InstructionPanel extends StatelessWidget {
  const _InstructionPanel({required this.hasDestination});

  final bool hasDestination;

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
            'How Zelle funding works',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          _StepLine(n: '1', text: hasDestination
              ? 'Send your payment with Zelle to the recipient shown below (name, email or phone, and QR if provided).'
              : 'Send your payment with Zelle to the account our team has given you (check email or support if you do not see details here).'),
          const SizedBox(height: 6),
          const _StepLine(
            n: '2',
            text: 'Send the payment first, then return here and submit the form.',
          ),
          const SizedBox(height: 6),
          const _StepLine(
            n: '3',
            text: 'We review each request. Your wallet is credited only after approval.',
          ),
        ],
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.n, required this.text});

  final String n;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppConfig.primaryColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            n,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppConfig.primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.35,
                ),
          ),
        ),
      ],
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.config});

  final WalletFundingConfig config;

  @override
  Widget build(BuildContext context) {
    final qr = config.zelleReceiverQrUrl.trim();
    return Container(
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
            'Send Zelle to',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          if (config.zelleReceiverName.trim().isNotEmpty)
            _DestRow(icon: Icons.badge_outlined, label: 'Name', value: config.zelleReceiverName.trim()),
          if (config.zelleReceiverEmail.trim().isNotEmpty)
            _DestRow(icon: Icons.email_outlined, label: 'Email', value: config.zelleReceiverEmail.trim()),
          if (config.zelleReceiverPhone.trim().isNotEmpty)
            _DestRow(icon: Icons.phone_outlined, label: 'Phone', value: config.zelleReceiverPhone.trim()),
          if (qr.isNotEmpty) ...[
            const SizedBox(height: 12),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: qr,
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(
                    width: 180,
                    height: 180,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.qr_code_2, size: 48),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Scan with your banking app if supported',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConfig.subtitleColor,
                    ),
              ),
            ),
          ],
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppConfig.subtitleColor),
          const SizedBox(width: 8),
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConfig.warningOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConfig.radiusMedium),
        border: Border.all(color: AppConfig.warningOrange.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppConfig.warningOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Zelle recipient details are not configured in the app yet. '
              'Use the account information provided by Zayer (email or support), '
              'then submit this form so we can match your payment.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
