import 'package:flutter/material.dart';

class SafeColors {
  static const navy = Color(0xFF0B1620);
  static const surface = Color(0xFF13222F);
  static const surfaceHi = Color(0xFF1B3042);
  static const teal = Color(0xFF2DD4BF);
  static const warn = Color(0xFFF5B942);
  static const danger = Color(0xFFEF6A5B);
  static const text = Color(0xFFE8F0F5);
  static const muted = Color(0xFF9DB1BF);
}

class SafeTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: SafeColors.navy,
        colorScheme: const ColorScheme.dark(
          primary: SafeColors.teal,
          onPrimary: SafeColors.navy,
          surface: SafeColors.surface,
          error: SafeColors.danger,
        ),
        appBarTheme: const AppBarTheme(
            backgroundColor: SafeColors.navy, elevation: 0, centerTitle: false),
        cardTheme: CardThemeData(
          color: SafeColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: SafeColors.surfaceHi),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      );
}
