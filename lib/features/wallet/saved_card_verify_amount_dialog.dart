import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_error_message.dart'
    show userFacingApiMessage, validationErrorsFromDio;
import 'stripe_wallet_helpers.dart';

/// Standalone dialog: owns its [TextEditingController] and disposes it in [State.dispose]
/// (avoids racing [whenComplete] disposal against dialog teardown / `_dependents` asserts).
class SavedCardVerifyAmountDialog extends StatefulWidget {
  const SavedCardVerifyAmountDialog({super.key, required this.cardId});

  final String cardId;

  @override
  State<SavedCardVerifyAmountDialog> createState() =>
      _SavedCardVerifyAmountDialogState();
}

class _SavedCardVerifyAmountDialogState extends State<SavedCardVerifyAmountDialog> {
  late final TextEditingController _controller;
  String? _fieldError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
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
      setState(() {
        _submitting = false;
        _fieldError = errs['amount'] ?? userFacingApiMessage(e);
      });
    }
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
          helperText: r'Must be between $1.00 and $5.00',
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
