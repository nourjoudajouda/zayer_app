import 'package:flutter/material.dart';

import '../../core/widgets/success_dialog.dart';

/// Wallet flows use the same feedback pattern as profile photo upload ([showSuccessDialog] / errors).
Future<void> walletShowSuccess(
  BuildContext context, {
  String title = 'Success',
  required String message,
}) {
  return showSuccessDialog(context, title: title, message: message);
}

Future<void> walletShowError(
  BuildContext context, {
  String title = 'Something went wrong',
  required String message,
}) {
  return showErrorDialog(context, title: title, message: message);
}
