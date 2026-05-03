import 'package:flutter/material.dart';

/// 在哪 ZAINA brand palette. Hex values pulled directly from the team's
/// Figma design system (file JGUawgfQV6xjWlirhpk73y → 顏色（Color）frame).
/// See docs/design/visual-spec.md for the full token catalogue.
class ZainaPalette {
  // Surface — `base` scale from deck (cream paper background)
  static const paperCream = Color(0xFFFAF5EC); // base-50/100
  static const paperCreamSoft = Color(0xFFE8CCA0); // base-200 (rare; soft cards prefer neutral)
  static const cardSurface = Color(0xFFF6F4F0); // neutral-50, slightly warmer card bg

  // Primary (brick red) — `primary` scale
  static const brickRed = Color(0xFFAF3737); // primary-700, the headline brick red
  static const brickRedDeep = Color(0xFF872D2D); // primary-800
  static const brickRedSoft = Color(0xFFFAE6E6); // primary-100, badge bg

  // Secondary (postbox green) — `secondary` scale
  static const postboxGreen = Color(0xFF2A522A); // secondary-700, the headline green
  static const postboxGreenDeep = Color(0xFF1E361E); // secondary-900
  static const postboxGreenSoft = Color(0xFFE3ECDF); // secondary-100, chip bg

  // Boba brown — `base` scale; the 在/哪 logo circles use base-800
  static const bobaBrown = Color(0xFF846549); // neutral-600, body emphasis
  static const bobaBrownDeep = Color(0xFF5B4236); // neutral-800, headings on cream
  static const logoBrown = Color(0xFF6E3825); // base-800, logo circle fill

  // Accent (gold) — `accent` scale
  static const goldSparkle = Color(0xFFE9A936); // accent-400, sparkle / highlight
  static const goldDeep = Color(0xFFC86817); // accent-600

  // Ink — `neutral` scale
  static const inkBlack = Color(0xFF2C1F1A); // neutral-950
  static const inkMuted = Color(0xFF6B4F3C); // neutral-700

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

  // Typography tokens distilled from the deck's text style frame
  // (size/h2..h6 + size/text-md / text-lg + Footnote).
  const textTheme = TextTheme(
    // Display / hero copy (在哪 logo, splash hero text)
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w900,
      color: ZainaPalette.inkBlack,
      height: 1.15,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w900,
      color: ZainaPalette.inkBlack,
      height: 1.2,
    ),
    // h2 — onboarding step titles, profile name
    headlineLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      color: ZainaPalette.inkBlack,
      height: 1.3,
    ),
    // h4 — section headers
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: ZainaPalette.inkBlack,
      height: 1.35,
    ),
    // h5 — card titles
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: ZainaPalette.inkBlack,
      height: 1.35,
    ),
    // h6 — group / list titles
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: ZainaPalette.inkBlack,
      height: 1.4,
    ),
    titleMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: ZainaPalette.inkBlack,
      height: 1.4,
    ),
    // text-lg — primary body
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: ZainaPalette.inkBlack,
      height: 1.5,
    ),
    // text-md — secondary body
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: ZainaPalette.inkBlack,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: ZainaPalette.inkMuted,
      height: 1.5,
    ),
    // labels — buttons, chips
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: ZainaPalette.bobaBrownDeep,
    ),
    // Footnote — fine print
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: ZainaPalette.bobaBrownDeep,
      letterSpacing: 0.2,
    ),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: ZainaPalette.paperCream,
    textTheme: textTheme,
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
      height: 76,
      backgroundColor: ZainaPalette.paperCreamSoft,
      indicatorColor: ZainaPalette.brickRed.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          fontSize: 17,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
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
