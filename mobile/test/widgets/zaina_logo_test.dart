import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zaina/widgets/zaina_logo.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ZainaLogo', () {
    testWidgets('renders 在 + 哪 circles and ZAINA wordmark by default',
        (tester) async {
      await tester.pumpWidget(_wrap(const ZainaLogo(size: 80)));

      expect(find.text('在'), findsOneWidget);
      expect(find.text('哪'), findsOneWidget);
      expect(find.text('ZAINA'), findsOneWidget);
    });

    testWidgets('hides wordmark when showWordmark = false', (tester) async {
      await tester.pumpWidget(
        _wrap(const ZainaLogo(size: 80, showWordmark: false)),
      );

      expect(find.text('在'), findsOneWidget);
      expect(find.text('哪'), findsOneWidget);
      expect(find.text('ZAINA'), findsNothing);
    });
  });

  group('WelcomeSignboard', () {
    testWidgets('renders 歡迎光臨 in order', (tester) async {
      await tester.pumpWidget(_wrap(const WelcomeSignboard(size: 56)));

      for (final ch in ['歡', '迎', '光', '臨']) {
        expect(find.text(ch), findsOneWidget);
      }
    });
  });
}
