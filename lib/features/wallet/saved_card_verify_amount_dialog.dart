import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_error_message.dart'
    show userFacingApiMessage, validationErrorsFromDio;
import 'stripe_wallet_helpers.dart';

/// Standalone dialog: owns its [TextEditingController] and disposes it in [State.dispose]
/// (avoids racing [whenComplete] disposal against dialog teardown / `_dependents` asserts).
class SavedCardVerifyAmountDialog extends StatefulWidget {
  const SavedCardVerifyAmountDialog({
    super.key,
    required this.cardId,
    this.attemptsRemaining,
    this.maxAttempts = 3,
  });

  final String cardId;
  final int? attemptsRemaining;
  final int maxAttempts;

  @override
  State<SavedCardVerifyAmountDialog> createState() =>
      _SavedCardVerifyAmountDialogState();
}

class _SavedCardVerifyAmountDialogState extends State<SavedCardVerifyAmountDialog> {
  late final TextEditingController _controller;
  String? _fieldError;
  bool _submitting = false;
  int? _attemptsRemaining;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _attemptsRemaining = widget.attemptsRemaining;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = _controller.text.trim();
    final amt = double.tryParse(raw);
    if (amt == null) {
      setState(() => _fieldError = 'Enter the exact amount from your bank.');
      return;
    }
    if (amt < 1 || amt > 5) {
      setState(
        () => _fieldError = r'Enter an amount between $1.00 and $5.00.',
      );
      return;
    }
    setState(() {
      _submitting = true;
      _fieldError = null;
    });
    try {
      savedCardFlowLog(
        'verify_card_charge',
        'POST amount=$amt id=${widget.cardId}',
      );
      await ApiClient.instance.post<Map<String, dynamic>>(
        '/api/wallet/saved-cards/${widget.cardId}/verify',
        data: {'amount': amt},
      );
      savedCardFlowLog('verify_card_charge', 'ok');
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      savedCardFlowLog('verify_card_charge', 'error: $e');
      if (!mounted) return;
      final errs = validationErrorsFromDio(e);
      int? ar;
      String? apiMsg;
      if (e is DioException) {
        final d = e.response?.data;
        if (d is Map<String, dynamic>) {
          final raw = d['attempts_remaining'];
          if (raw is num) {
            ar = raw.toInt();
          }
          final m = d['message'];
          if (m is String && m.trim().isNotEmpty) {
            apiMsg = m.trim();
          }
        }
      }
      setState(() {
        _submitting = false;
        if (ar != null) {
          _attemptsRemaining = ar;
        }
        _fieldError = errs['amount'] ?? apiMsg ?? userFacingApiMessage(e);
      });
    }
  }

  String _attemptsHint() {
    final max = widget.maxAttempts;
    final rem = _attemptsRemaining;
    if (rem == null) {
      return r'You have up to $max incorrect tries before the card is blocked.';
    }
    if (rem <= 0) {
      return 'No attempts remaining.';
    }
    return '$rem incorrect ${rem == 1 ? 'try' : 'tries'} left (max $max before block).';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verification amount'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() => _fieldError = null),
        decoration: InputDecoration(
          labelText: 'Exact USD amount charged',
          hintText: 'e.g. 3.47',
          helperText:
              '${r'Must be between $1.00 and $5.00. '}${_attemptsHint()}',
          errorText: _fieldError,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verify'),
        ),
      ],
    );
  }
}
