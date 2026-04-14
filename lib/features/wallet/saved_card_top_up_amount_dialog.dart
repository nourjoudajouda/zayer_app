import 'package:flutter/material.dart';

/// Dialog for entering saved-card top-up amount; owns [TextEditingController] lifecycle.
class SavedCardTopUpAmountDialog extends StatefulWidget {
  const SavedCardTopUpAmountDialog({super.key, this.initialAmount});

  final double? initialAmount;

  @override
  State<SavedCardTopUpAmountDialog> createState() =>
      _SavedCardTopUpAmountDialogState();
}

class _SavedCardTopUpAmountDialogState extends State<SavedCardTopUpAmountDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialAmount?.toStringAsFixed(2) ?? '50.00',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Top up wallet'),
      content: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() => _error = null),
        decoration: InputDecoration(
          labelText: 'Amount USD',
          errorText: _error,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop<double?>(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final raw = _controller.text.trim();
            final amt = double.tryParse(raw);
            if (amt == null || amt < 1) {
              setState(
                () => _error = 'Enter a valid amount of at least \$1.00.',
              );
              return;
            }
            Navigator.of(context).pop<double>(amt);
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
