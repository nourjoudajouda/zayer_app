import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zayer_app/app.dart';

void main() {
  testWidgets('App boots without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ZayerApp(),
      ),
    );

    // The initial route depends on auth/bootstrap state; this test only ensures the app builds.
    expect(find.byType(ZayerApp), findsOneWidget);
  }, skip: true);
}
