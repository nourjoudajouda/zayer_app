import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../config/app_config.dart';

/// Shows the same shipping reference copy as Confirm Product (info dialog + optional note).
void showShippingEstimateInfoDialog(BuildContext context, {AppLocalizations? l10n}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n?.shippingInformationTitle ?? 'Shipping Information'),
      content: Text(
        l10n?.shippingInformationDialogBody ??
            'This shipping cost is for reference only and is not charged at this stage. '
                'The final shipping amount may change after admin review.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Label + value row with an info icon that opens [showShippingEstimateInfoDialog].
class ShippingEstimateReferenceRow extends StatelessWidget {
  const ShippingEstimateReferenceRow({
    super.key,
    required this.valueText,
    this.dense = false,
  });

  final String valueText;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  l10n?.shippingEstimateReferenceLabel ??
                      'Shipping estimate (reference only)',
                  style: dense
                      ? Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppConfig.subtitleColor,
                          )
                      : Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppConfig.subtitleColor,
                          ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                  size: dense ? 18 : 20,
                  color: AppConfig.primaryColor,
                ),
                onPressed: () => showShippingEstimateInfoDialog(context, l10n: l10n),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            valueText,
            textAlign: TextAlign.right,
            style: (dense
                    ? Theme.of(context).textTheme.bodySmall
                    : Theme.of(context).textTheme.bodyMedium)
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

/// Small note under shipping rows.
class ShippingEstimateFootnote extends StatelessWidget {
  const ShippingEstimateFootnote({super.key, this.dense = true});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        l10n?.shippingReviewNoteShort ??
            'Note: Shipping cost is subject to admin review before final confirmation.',
        style: (dense
                ? Theme.of(context).textTheme.bodySmall
                : Theme.of(context).textTheme.bodyMedium)
            ?.copyWith(
              color: AppConfig.subtitleColor,
              height: 1.35,
            ),
      ),
    );
  }
}
