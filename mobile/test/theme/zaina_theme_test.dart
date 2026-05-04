import 'package:flutter_test/flutter_test.dart';

import 'package:zaina/theme/zaina_theme.dart';

void main() {
  group('buildZainaTheme', () {
    final theme = buildZainaTheme();

    test('uses Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('primary color is brick red token, not an eyeballed hex', () {
      expect(theme.colorScheme.primary, ZainaPalette.brickRed);
    });

    test('scaffold background uses paper cream token', () {
      expect(theme.scaffoldBackgroundColor, ZainaPalette.paperCream);
    });

    test('app bar inherits cream surface (no default Material 3 purple)', () {
      expect(theme.appBarTheme.backgroundColor, ZainaPalette.paperCream);
    });
  });
}
