import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'core/auth/token_store.dart';
import 'core/network/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase not configured (missing google-services.json / GoogleService-Info.plist)
  }
  final tokenStore = TokenStoreImpl();
  await ApiClient.init(tokenStore: tokenStore);
  runApp(
    const ProviderScope(
      child: ZayerApp(),
    ),
  );
}
