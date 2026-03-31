
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool _isOnline(List<ConnectivityResult> result) {
  return result.isNotEmpty &&
      result.any((r) => r != ConnectivityResult.none);
}

/// Real connectivity status using connectivity_plus.
/// When there is no network, the app shows "No internet" (see app.dart).
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  final initial = await connectivity.checkConnectivity();
  yield _isOnline(initial);
  await for (final result in connectivity.onConnectivityChanged) {
    yield _isOnline(result);
  }
});
