import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import 'models/purchase_assistant_request_model.dart';

/// Display label for store (domain), for list/detail rows.
String paStoreLabel(PurchaseAssistantRequestModel r) {
  final d = r.sourceDomain?.trim();
  if (d != null && d.isNotEmpty) {
    return d;
  }
  try {
    final u = Uri.parse(r.sourceUrl);
    if (u.host.isNotEmpty) {
      return u.host;
    }
  } catch (_) {}
  return 'Store';
}

/// Primary line: product title or short fallback.
String paProductTitleLine(PurchaseAssistantRequestModel r) {
  final t = r.title?.trim();
  if (t != null && t.isNotEmpty) {
    return t;
  }
  return 'Product request';
}

Color paStatusColor(String status) {
  switch (status) {
    case 'awaiting_customer_payment':
      return AppConfig.warningOrange;
    case 'rejected':
    case 'cancelled':
      return AppConfig.errorRed;
    case 'completed':
    case 'paid':
      return AppConfig.successGreen;
    default:
      return AppConfig.primaryColor;
  }
}

String paStatusLabel(String raw) {
  if (raw.isEmpty) {
    return raw;
  }
  return raw
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

String? paFormatCreatedAt(String? iso) {
  if (iso == null || iso.isEmpty) {
    return null;
  }
  try {
    final d = DateTime.parse(iso);
    return DateFormat.yMMMd().add_jm().format(d.toLocal());
  } catch (_) {
    return iso;
  }
}
