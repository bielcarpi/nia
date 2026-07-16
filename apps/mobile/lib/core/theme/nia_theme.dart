import 'package:flutter/material.dart';

abstract final class NiaColors {
  static const ink = Color(0xFF152A25);
  static const evergreen = Color(0xFF123D31);
  static const fern = Color(0xFF197A5B);
  static const mint = Color(0xFFBDEDDC);
  static const cream = Color(0xFFF7F4EB);
  static const peach = Color(0xFFFFD8BC);
  static const white = Color(0xFFFFFFFF);
}

ThemeData buildNiaTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: NiaColors.fern,
    brightness: Brightness.light,
    surface: NiaColors.cream,
  );

  return ThemeData(
    colorScheme: scheme.copyWith(
      primary: NiaColors.evergreen,
      secondary: NiaColors.fern,
      surface: NiaColors.cream,
      onSurface: NiaColors.ink,
    ),
    scaffoldBackgroundColor: NiaColors.cream,
    useMaterial3: true,
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 48,
        height: 1.05,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.8,
      ),
      headlineLarge: TextStyle(
        fontSize: 34,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleMedium: TextStyle(fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45),
    ).apply(bodyColor: NiaColors.ink, displayColor: NiaColors.ink),
    cardTheme: const CardThemeData(
      color: NiaColors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: NiaColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Color(0x1F152A25)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      side: BorderSide.none,
      selectedColor: NiaColors.mint,
      backgroundColor: NiaColors.white,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: NiaColors.white,
      indicatorColor: NiaColors.mint,
      elevation: 0,
      height: 72,
    ),
  );
}
