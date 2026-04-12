import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_config.dart';

/// Formats API ISO8601 strings for display.
String? formatWalletDateLine(String? iso) {
  if (iso == null || iso.trim().isEmpty) return null;
  final d = DateTime.tryParse(iso.trim());
  if (d == null) return iso;
  return DateFormat('MMM d, y · h:mm a').format(d.toLocal());
}

/// Masks IBAN for summary rows; full value can be shown in expanded details.
String maskIbanForDisplay(String iban) {
  final compact = iban.replaceAll(RegExp(r'\s'), '');
  if (compact.length <= 4) return '••••';
  final last = compact.substring(compact.length - 4);
  return '•••• •••• •••• $last';
}

// --- Refund to wallet (pending / approved / rejected) ---

class WalletRefundStatusPresentation {
  const WalletRefundStatusPresentation({
    required this.label,
    required this.color,
    required this.icon,
    this.subtitle,
  });

  final String label;
  final Color color;
  final IconData icon;
  final String? subtitle;

  static WalletRefundStatusPresentation forStatus(String status) {
    switch (status) {
      case 'approved':
        return WalletRefundStatusPresentation(
          label: 'Approved',
          color: AppConfig.successGreen,
          icon: Icons.check_circle_outline,
          subtitle: 'Credited to your wallet',
        );
      case 'rejected':
        return WalletRefundStatusPresentation(
          label: 'Rejected',
          color: AppConfig.subtitleColor,
          icon: Icons.cancel_outlined,
          subtitle: 'Not credited',
        );
      case 'pending':
      default:
        return WalletRefundStatusPresentation(
          label: 'Pending',
          color: AppConfig.warningOrange,
          icon: Icons.schedule,
          subtitle: 'Awaiting review',
        );
    }
  }
}

class WalletRefundStatusChip extends StatelessWidget {
  const WalletRefundStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final p = WalletRefundStatusPresentation.forStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: p.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(p.icon, size: 16, color: p.color),
          const SizedBox(width: 6),
          Text(
            p.label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: p.color,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.35,
                ),
          ),
        ],
      ),
    );
  }
}

// --- Withdrawals ---

class WalletWithdrawalStatusPresentation {
  const WalletWithdrawalStatusPresentation({
    required this.label,
    required this.color,
    required this.icon,
    this.subtitle,
  });

  final String label;
  final Color color;
  final IconData icon;
  final String? subtitle;

  static WalletWithdrawalStatusPresentation forStatus(String status) {
    switch (status) {
      case 'transferred':
        return WalletWithdrawalStatusPresentation(
          label: 'Transferred',
          color: AppConfig.successGreen,
          icon: Icons.verified_outlined,
          subtitle: 'Bank transfer sent — funds may take up to 30 days',
        );
      case 'approved':
        return WalletWithdrawalStatusPresentation(
          label: 'Approved',
          color: AppConfig.primaryColor,
          icon: Icons.fact_check_outlined,
          subtitle: 'Processing your payout',
        );
      case 'under_review':
        return WalletWithdrawalStatusPresentation(
          label: 'Under review',
          color: AppConfig.warningOrange,
          icon: Icons.visibility_outlined,
          subtitle: 'Team is reviewing your request',
        );
      case 'rejected':
        return WalletWithdrawalStatusPresentation(
          label: 'Rejected',
          color: AppConfig.subtitleColor,
          icon: Icons.do_not_disturb_on_outlined,
          subtitle: 'Not processed',
        );
      case 'pending':
      default:
        return WalletWithdrawalStatusPresentation(
          label: 'Pending',
          color: AppConfig.warningOrange,
          icon: Icons.hourglass_empty_outlined,
          subtitle: 'Submitted — awaiting review',
        );
    }
  }
}

class WalletWithdrawalStatusChip extends StatelessWidget {
  const WalletWithdrawalStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final p = WalletWithdrawalStatusPresentation.forStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: p.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(p.icon, size: 16, color: p.color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              p.label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: p.color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.35,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
