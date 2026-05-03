import 'package:flutter/material.dart';

/// 在哪 ZAINA brand palette + Material 3 theme. See docs/design/visual-spec.md.
class ZainaPalette {
  static const paperCream = Color(0xFFF4ECD8);
  static const paperCreamSoft = Color(0xFFFAF3E2);
  static const brickRed = Color(0xFFA23A2D);
  static const brickRedDeep = Color(0xFF7E2B22);
  static const postboxGreen = Color(0xFF3A6B43);
  static const postboxGreenDeep = Color(0xFF2A4F32);
  static const bobaBrown = Color(0xFF8E6849);
  static const bobaBrownDeep = Color(0xFF5C4530);
  static const goldSparkle = Color(0xFFD6B05A);
  static const inkBlack = Color(0xFF2D2118);

  /// Subtle line color for borders / dividers on cream surfaces.
  static const hairline = Color(0x14000000);
}

ThemeData buildZainaTheme() {
  final colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: ZainaPalette.brickRed,
    onPrimary: Colors.white,
    primaryContainer: ZainaPalette.brickRedDeep,
    onPrimaryContainer: Colors.white,
    secondary: ZainaPalette.postboxGreen,
    onSecondary: Colors.white,
    secondaryContainer: ZainaPalette.postboxGreenDeep,
    onSecondaryContainer: Colors.white,
    tertiary: ZainaPalette.bobaBrown,
    onTertiary: Colors.white,
    tertiaryContainer: ZainaPalette.bobaBrownDeep,
    onTertiaryContainer: Colors.white,
    error: const Color(0xFFB42318),
    onError: Colors.white,
    surface: ZainaPalette.paperCream,
    onSurface: ZainaPalette.inkBlack,
    surfaceContainerHighest: ZainaPalette.paperCreamSoft,
    onSurfaceVariant: ZainaPalette.bobaBrownDeep,
    outline: ZainaPalette.bobaBrown,
    outlineVariant: ZainaPalette.hairline,
    shadow: Colors.black,
    scrim: Colors.black54,
    inverseSurface: ZainaPalette.inkBlack,
    onInverseSurface: ZainaPalette.paperCream,
    inversePrimary: ZainaPalette.goldSparkle,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: ZainaPalette.paperCream,
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: ZainaPalette.paperCream,
      foregroundColor: ZainaPalette.inkBlack,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        color: ZainaPalette.inkBlack,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: const CardThemeData(
      color: ZainaPalette.paperCreamSoft,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        side: BorderSide(color: ZainaPalette.hairline),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ZainaPalette.brickRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ZainaPalette.brickRedDeep,
        side: const BorderSide(color: ZainaPalette.brickRedDeep, width: 1.4),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ZainaPalette.brickRedDeep,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: ZainaPalette.brickRed,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ZainaPalette.paperCreamSoft,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: ZainaPalette.bobaBrown),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: ZainaPalette.bobaBrown),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: ZainaPalette.brickRed, width: 2),
      ),
      labelStyle: const TextStyle(color: ZainaPalette.bobaBrownDeep),
    ),
    dividerTheme: const DividerThemeData(
      color: ZainaPalette.hairline,
      thickness: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: ZainaPalette.paperCreamSoft,
      selectedColor: ZainaPalette.brickRed,
      side: const BorderSide(color: ZainaPalette.bobaBrown),
      labelStyle: const TextStyle(color: ZainaPalette.inkBlack),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: ZainaPalette.paperCreamSoft,
      indicatorColor: ZainaPalette.brickRed.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? ZainaPalette.brickRedDeep
              : ZainaPalette.bobaBrownDeep,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected)
              ? ZainaPalette.brickRedDeep
              : ZainaPalette.bobaBrownDeep,
        );
      }),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: ZainaPalette.inkBlack,
      contentTextStyle: TextStyle(color: ZainaPalette.paperCream),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: ZainaPalette.brickRed,
    ),
  );
}
