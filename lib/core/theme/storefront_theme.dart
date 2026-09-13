import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart';

abstract final class StorefrontColors {
  static const canvas = canvasColor;
  static const ink = inkColor;
  static const surface = Color(0xFFFCFBF8);
  static const surfaceMuted = surfaceColor;
  static const line = lineColor;
  static const accent = accentColor;
  static const mutedInk = Color(0xFF5E5A53);
  static const subtleInk = Color(0xFF716C64);
  static const error = Color(0xFF9F2F26);
  static const errorSurface = Color(0xFFF9EDEB);
  static const success = Color(0xFF276749);
  static const successSurface = Color(0xFFEAF4EE);
  static const focus = Color(0xFF87502F);
  static const onDark = Color(0xFFFFFFFF);
}

abstract final class StorefrontSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const section = 64.0;
}

abstract final class StorefrontRadius {
  static const subtle = 4.0;
  static const control = 8.0;
  static const surface = 12.0;

  static const controlBorder = BorderRadius.all(Radius.circular(control));
  static const surfaceBorder = BorderRadius.all(Radius.circular(surface));
}

abstract final class StorefrontMotion {
  static const fast = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 180);
  static const deliberate = Duration(milliseconds: 240);
  static const curve = Curves.easeOutCubic;

  static Duration resolve(BuildContext context, Duration duration) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false
        ? Duration.zero
        : duration;
  }
}

abstract final class StorefrontLayout {
  static const narrow = 360.0;
  static const tablet = 768.0;
  static const desktop = 1024.0;
  static const wideDesktop = 1440.0;
  static const contentMaxWidth = 1440.0;
  static const readingMaxWidth = 680.0;

  static double gutterFor(double width) {
    if (width >= wideDesktop) return 56;
    if (width >= desktop) return 40;
    if (width >= tablet) return 28;
    return width < narrow ? 12 : 16;
  }
}

abstract final class StorefrontShadows {
  static const subtle = <BoxShadow>[
    BoxShadow(color: Color(0x0D171714), blurRadius: 18, offset: Offset(0, 6)),
  ];

  static const raised = <BoxShadow>[
    BoxShadow(color: Color(0x14171714), blurRadius: 28, offset: Offset(0, 10)),
  ];
}

ThemeData buildStorefrontTheme() {
  final base = buildAppTheme();
  final textTheme = GoogleFonts.cairoTextTheme(base.textTheme).copyWith(
    displayLarge: GoogleFonts.cairo(
      fontSize: 56,
      height: 1.08,
      fontWeight: FontWeight.w800,
      color: StorefrontColors.ink,
    ),
    headlineLarge: GoogleFonts.cairo(
      fontSize: 36,
      height: 1.2,
      fontWeight: FontWeight.w800,
      color: StorefrontColors.ink,
    ),
    headlineMedium: GoogleFonts.cairo(
      fontSize: 28,
      height: 1.25,
      fontWeight: FontWeight.w800,
      color: StorefrontColors.ink,
    ),
    titleLarge: GoogleFonts.cairo(
      fontSize: 20,
      height: 1.35,
      fontWeight: FontWeight.w800,
      color: StorefrontColors.ink,
    ),
    titleMedium: GoogleFonts.cairo(
      fontSize: 16,
      height: 1.4,
      fontWeight: FontWeight.w700,
      color: StorefrontColors.ink,
    ),
    bodyLarge: GoogleFonts.cairo(
      fontSize: 16,
      height: 1.65,
      color: StorefrontColors.ink,
    ),
    bodyMedium: GoogleFonts.cairo(
      fontSize: 14,
      height: 1.6,
      color: StorefrontColors.mutedInk,
    ),
    bodySmall: GoogleFonts.cairo(
      fontSize: 12,
      height: 1.55,
      color: StorefrontColors.mutedInk,
    ),
    labelLarge: GoogleFonts.cairo(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: StorefrontColors.ink,
    ),
  );

  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: StorefrontColors.ink,
      onPrimary: StorefrontColors.onDark,
      secondary: StorefrontColors.accent,
      onSecondary: StorefrontColors.onDark,
      surface: StorefrontColors.surface,
      onSurface: StorefrontColors.ink,
      error: StorefrontColors.error,
      outline: StorefrontColors.line,
    ),
    scaffoldBackgroundColor: StorefrontColors.canvas,
    textTheme: textTheme,
    visualDensity: VisualDensity.standard,
    appBarTheme: AppBarTheme(
      backgroundColor: StorefrontColors.canvas,
      foregroundColor: StorefrontColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 72,
      titleTextStyle: textTheme.titleLarge,
      shape: const Border(bottom: BorderSide(color: StorefrontColors.line)),
    ),
    dividerTheme: const DividerThemeData(
      color: StorefrontColors.line,
      thickness: 1,
      space: 1,
    ),
    cardTheme: const CardThemeData(
      color: StorefrontColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: StorefrontRadius.surfaceBorder,
        side: BorderSide(color: StorefrontColors.line),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: StorefrontColors.surface,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: StorefrontColors.line),
        borderRadius: StorefrontRadius.controlBorder,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: StorefrontColors.line),
        borderRadius: StorefrontRadius.controlBorder,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: StorefrontColors.focus, width: 2),
        borderRadius: StorefrontRadius.controlBorder,
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: StorefrontColors.error, width: 1.4),
        borderRadius: StorefrontRadius.controlBorder,
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: StorefrontColors.error, width: 2),
        borderRadius: StorefrontRadius.controlBorder,
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: StorefrontColors.line),
        borderRadius: StorefrontRadius.controlBorder,
      ),
      labelStyle: TextStyle(color: StorefrontColors.mutedInk),
      hintStyle: TextStyle(color: StorefrontColors.subtleInk),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 52)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: StorefrontRadius.controlBorder),
        ),
        textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        animationDuration: StorefrontMotion.standard,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: const ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(48, 52)),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        ),
        side: WidgetStatePropertyAll(BorderSide(color: StorefrontColors.line)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: StorefrontRadius.controlBorder),
        ),
        animationDuration: StorefrontMotion.standard,
      ),
    ),
    textButtonTheme: const TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(48, 48)),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        animationDuration: StorefrontMotion.fast,
      ),
    ),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(48, 48)),
        iconSize: WidgetStatePropertyAll(22),
        animationDuration: StorefrontMotion.fast,
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: StorefrontColors.surface,
      selectedColor: StorefrontColors.ink,
      disabledColor: StorefrontColors.surfaceMuted,
      side: const BorderSide(color: StorefrontColors.line),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      labelStyle: textTheme.labelLarge,
      secondaryLabelStyle: textTheme.labelLarge?.copyWith(
        color: StorefrontColors.onDark,
      ),
      showCheckmark: false,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: StorefrontColors.ink,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: StorefrontColors.onDark,
      ),
      actionTextColor: const Color(0xFFFFB28F),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(
        borderRadius: StorefrontRadius.controlBorder,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: StorefrontColors.accent,
      linearTrackColor: StorefrontColors.surfaceMuted,
    ),
    focusColor: StorefrontColors.focus.withValues(alpha: .14),
    hoverColor: StorefrontColors.ink.withValues(alpha: .05),
    highlightColor: StorefrontColors.ink.withValues(alpha: .08),
    splashColor: StorefrontColors.ink.withValues(alpha: .08),
  );
}

class StorefrontTheme extends StatelessWidget {
  const StorefrontTheme({required this.child, super.key});

  static final ThemeData _theme = buildStorefrontTheme();

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(data: _theme, child: child);
  }
}
