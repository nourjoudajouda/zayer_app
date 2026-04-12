import 'package:flutter/material.dart';

/// Warehouse receipt fields from the API match admin entry: **lb** and **inches** (see Laravel admin labels).
/// Catalog line fields may still use kg / free-text dimensions — we convert kg→lb for display only.

const double _kgToLb = 2.2046226218;

/// Receipt [weightLb] is stored as entered in admin (lb).
String formatReceiptWeightLb(double weightLb) => '${weightLb.toStringAsFixed(2)} lb';

/// Catalog [weightKg] from order line → display in lb.
String? formatCatalogWeightFromKg(double? weightKg) {
  if (weightKg == null) return null;
  final lb = weightKg * _kgToLb;
  return '${lb.toStringAsFixed(2)} lb (est.)';
}

/// Receipt box dimensions (already inches in DB).
String formatReceiptDimsIn(double l, double w, double h) =>
    '${l.toStringAsFixed(0)}×${w.toStringAsFixed(0)}×${h.toStringAsFixed(0)} in';

/// Single line for weight block: prefers receipt lb, else catalog kg→lb.
String? weightLineForItem({
  required double? receiptWeightLb,
  required double? catalogWeightKg,
}) {
  if (receiptWeightLb != null) {
    return 'Weight: ${formatReceiptWeightLb(receiptWeightLb)}';
  }
  final cat = formatCatalogWeightFromKg(catalogWeightKg);
  if (cat != null) return 'Listed weight: $cat';
  return null;
}

/// Short text for [Tooltip] on info icons.
const String kExtraFeeTooltipShort =
    'Optional warehouse charge (handling, repacking, special packaging, etc.). Tap for details.';

Future<void> showWarehouseExtraFeeDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Extra fees'),
      content: const Text(
        'These are additional warehouse or shipping-related charges added when your '
        'item was checked in. Examples include battery handling, fragile repacking, '
        'special packaging, oversize handling, or other manual services. '
        'They are separate from standard outbound shipping.',
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
