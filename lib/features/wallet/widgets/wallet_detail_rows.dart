import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';

/// Label + value row for wallet detail sections.
class WalletKvRow extends StatelessWidget {
  const WalletKvRow({
    super.key,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppConfig.subtitleColor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: valueStyle ??
                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppConfig.textColor,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
