import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_error_message.dart'
    show userFacingApiMessage, validationErrorsFromDio;
import 'stripe_wallet_helpers.dart';

/// Result of the verification amount dialog (for parent to refresh list / show feedback).
enum SavedCardVerifyOutcome {
  success,
  cancelled,
  /// Card blocked after failed attempts — parent should reload list and show error dialog.
  blocked,
}

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

  int get _max => widget.maxAttempts;

  /// Failed verification guesses so far (server count).
  int get _failedCount {
    final rem = _attemptsRemaining;
    if (rem == null) return 0;
    return (_max - rem).clamp(0, _max);
  }

  void _popBlocked() {
    if (!mounted) return;
    Navigator.of(context).pop(SavedCardVerifyOutcome.blocked);
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
      Navigator.of(context).pop(SavedCardVerifyOutcome.success);
    } catch (e) {
      savedCardFlowLog('verify_card_charge', 'error: $e');
      if (!mounted) return;
      final errs = validationErrorsFromDio(e);
      int? ar;
      String? apiMsg;
      String? errorKey;
      if (e is DioException) {
        final d = e.response?.data;
        if (d is Map<String, dynamic>) {
          final rawAr = d['attempts_remaining'];
          if (rawAr is num) {
            ar = rawAr.toInt();
          }
          errorKey = d['error_key']?.toString();
          final m = d['message'];
          if (m is String && m.trim().isNotEmpty) {
            apiMsg = m.trim();
          }
        }
      }

      if (errorKey == 'verification_blocked') {
        _popBlocked();
        return;
      }

      if (ar != null) {
        _attemptsRemaining = ar;
      }

      final isNowBlocked = ar != null && ar <= 0;
      if (isNowBlocked) {
        _popBlocked();
        return;
      }

      setState(() {
        _submitting = false;
        _fieldError = errs['amount'] ?? apiMsg ?? userFacingApiMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rem = _attemptsRemaining;
    final failed = _failedCount;
    final chips = List.generate(_max, (i) {
      final used = i < failed;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: used
                ? Colors.red.shade100
                : AppConfig.lightBlueBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: used ? Colors.red.shade400 : AppConfig.borderColor,
            ),
          ),
          child: Text(
            '${i + 1}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: used ? Colors.red.shade900 : AppConfig.subtitleColor,
            ),
          ),
        ),
      );
    });

    final summary = rem == null
        ? 'You have $_max attempts. After $_max wrong guesses, this card will be blocked until support reviews it.'
        : rem <= 0
            ? 'No attempts left.'
            : '$rem wrong ${rem == 1 ? 'guess' : 'guesses'} left before the card is blocked.';

    return AlertDialog(
      title: const Text('Verification amount'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the exact USD amount of the small verification charge on your statement.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.subtitleColor,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Attempt counter',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppConfig.textColor,
                  ),
            ),
            const SizedBox(height: 8),
            Row(children: chips),
            const SizedBox(height: 8),
            Text(
              summary,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade900,
                    height: 1.3,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() => _fieldError = null),
              decoration: InputDecoration(
                labelText: 'Exact USD amount charged',
                hintText: 'e.g. 3.47',
                helperText:
                    r'Must be between $1.00 and $5.00 (verification charge range).',
                errorText: _fieldError,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(SavedCardVerifyOutcome.cancelled),
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
