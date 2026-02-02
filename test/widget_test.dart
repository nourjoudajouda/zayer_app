import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zayer_app/app.dart';

void main() {
  testWidgets('App loads register screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ZayerApp(),
      ),
    );

    expect(find.text('Send OTP'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}
