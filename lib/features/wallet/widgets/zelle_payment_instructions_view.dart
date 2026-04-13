import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/models/app_bootstrap_config.dart';

/// Shared Zelle destination UI: QR, recipient lines, optional admin instruction text.
/// Used on the instruction step and inside a sheet from the submission form.
class ZellePaymentInstructionsView extends StatelessWidget {
  const ZellePaymentInstructionsView({
    super.key,
    required this.config,
    this.helperHeadline = 'Scan in your banking app to pay',
  });

  final WalletFundingConfig config;
  final String helperHeadline;

  @override
  Widget build(BuildContext context) {
    final qr = config.zelleReceiverQrUrl.trim();
    final extra = config.zelleInstructionText.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          helperHeadline,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppConfig.subtitleColor,
              ),
        ),
        const SizedBox(height: 16),
        if (qr.isNotEmpty) ...[
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: qr,
                width: 280,
                height: 280,
                fit: BoxFit.contain,
                placeholder: (context, url) => const SizedBox(
                  width: 280,
                  height: 280,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (context, url, error) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Icon(Icons.qr_code_2, size: 64),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (config.zelleReceiverName.trim().isNotEmpty)
          _Line(
            label: 'Recipient name',
            value: config.zelleReceiverName.trim(),
          ),
        if (config.zelleReceiverEmail.trim().isNotEmpty)
          _Line(
            label: 'Recipient email',
            value: config.zelleReceiverEmail.trim(),
          ),
        if (config.zelleReceiverPhone.trim().isNotEmpty)
          _Line(
            label: 'Recipient phone',
            value: config.zelleReceiverPhone.trim(),
          ),
        if (extra.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            extra,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
          ),
        ],
        if (!config.hasZelleDestination)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Zelle destination details are not configured in the admin panel yet. '
              'Use the instructions Zayer sent you by email or support.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.warningOrange,
                    height: 1.35,
                  ),
            ),
          ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
    );
  }
}
