import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import 'models/purchase_assistant_request_model.dart';

/// Display label for store (domain), for list/detail rows.
String paStoreLabel(PurchaseAssistantRequestModel r) {
  final label = r.storeDisplayName?.trim();
  if (label != null && label.isNotEmpty) {
    return label;
  }
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

String? paFormatMoney(double? amount, String? currency) {
  if (amount == null) return null;
  final c = (currency != null && currency.isNotEmpty) ? currency : 'USD';
  return '${amount.toStringAsFixed(2)} $c';
}

/// Milestones for history (derived; only shows meaningful steps for current status).
List<PaTimelineStep> paBuildTimeline(
  String status, {
  required String? createdIso,
  required String? updatedIso,
}) {
  final order = [
    'submitted',
    'under_review',
    'awaiting_customer_payment',
    'payment_under_review',
    'paid',
    'purchasing',
    'purchased',
    'in_transit_to_warehouse',
    'received_at_warehouse',
    'completed',
  ];
  final idx = order.indexOf(status);
  final rejected = status == 'rejected' || status == 'cancelled';

  String labelFor(String key) {
    switch (key) {
      case 'submitted':
        return 'Request submitted';
      case 'under_review':
        return 'Under review';
      case 'awaiting_customer_payment':
        return 'Awaiting your payment';
      case 'payment_under_review':
        return 'Payment processing';
      case 'paid':
        return 'Paid';
      case 'purchasing':
        return 'Purchasing';
      case 'purchased':
        return 'Purchased';
      case 'in_transit_to_warehouse':
        return 'In transit to warehouse';
      case 'received_at_warehouse':
        return 'Received at warehouse';
      case 'completed':
        return 'Completed';
      default:
        return key;
    }
  }

  final steps = <PaTimelineStep>[];
  void add(String key, bool done, bool current) {
    steps.add(PaTimelineStep(
      key: key,
      title: labelFor(key),
      done: done,
      current: current,
    ));
  }

  if (rejected) {
    steps.add(PaTimelineStep(
      key: status,
      title: status == 'rejected' ? 'Rejected' : 'Cancelled',
      done: true,
      current: true,
    ));
    return steps;
  }

  if (idx < 0) {
    steps.add(PaTimelineStep(
      key: status,
      title: labelFor(status),
      done: true,
      current: true,
    ));
    return steps;
  }

  for (var i = 0; i <= idx && i < order.length; i++) {
    add(order[i], i < idx, i == idx);
  }

  return steps;
}

class PaTimelineStep {
  const PaTimelineStep({
    required this.key,
    required this.title,
    required this.done,
    required this.current,
  });
  final String key;
  final String title;
  final bool done;
  final bool current;
}

