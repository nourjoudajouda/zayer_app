import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
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

  Future<void> _submit() async {
    final amt = double.tryParse(_amount.text.trim());
    if (amt == null || amt < 1) return;
    setState(() => _submitting = true);
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
        const SnackBar(content: Text('Request submitted. We will review it shortly.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.backgroundColor,
      appBar: AppBar(
        title: const Text('Wire transfer'),
        backgroundColor: AppConfig.backgroundColor,
        foregroundColor: AppConfig.textColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount (USD)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reference,
              decoration: const InputDecoration(
                labelText: 'Transfer reference (optional)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(controller: _senderName, decoration: const InputDecoration(labelText: 'Sender name (optional)')),
            const SizedBox(height: 12),
            TextField(controller: _senderEmail, decoration: const InputDecoration(labelText: 'Sender email (optional)')),
            const SizedBox(height: 12),
            TextField(controller: _senderPhone, decoration: const InputDecoration(labelText: 'Sender phone (optional)')),
            const SizedBox(height: 12),
            TextField(controller: _bankName, decoration: const InputDecoration(labelText: 'Bank name (optional)')),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickProof,
              icon: const Icon(Icons.upload_file),
              label: Text(_proof == null ? 'Upload proof (optional)' : 'Proof selected'),
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
                  : const Text('Submit request'),
            ),
          ],
        ),
      ),
    );
  }
}
