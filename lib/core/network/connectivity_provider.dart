import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connectivity status. Replace with connectivity_plus or similar for real checks.
/// For now assumes online so the app runs without the package.
final connectivityProvider = StreamProvider<bool>((ref) {
  return Stream.value(true);
});
