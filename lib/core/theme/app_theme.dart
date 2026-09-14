import 'package:flutter/material.dart';

const canvasColor = Color(0xFFF5F2EC);
const inkColor = Color(0xFF171714);
const surfaceColor = Color(0xFFEAE7E0);
const lineColor = Color(0xFFD6D1C8);
const accentColor = Color(0xFFB6502E);
const cairoFontFamily = 'Cairo';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: canvasColor,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.light,
        ).copyWith(
          primary: inkColor,
          onPrimary: Colors.white,
          surface: canvasColor,
        ),
    fontFamily: cairoFontFamily,
    textTheme: ThemeData.light().textTheme.apply(fontFamily: cairoFontFamily),
    appBarTheme: const AppBarTheme(
      backgroundColor: canvasColor,
      foregroundColor: inkColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: lineColor),
        borderRadius: BorderRadius.zero,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: lineColor),
        borderRadius: BorderRadius.zero,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: inkColor, width: 1.4),
        borderRadius: BorderRadius.zero,
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: accentColor),
        borderRadius: BorderRadius.zero,
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: accentColor, width: 1.4),
        borderRadius: BorderRadius.zero,
      ),
    ),
  );
}
