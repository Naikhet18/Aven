import 'package:flutter/material.dart';

/// Premium, minimalistic, high-contrast dark theme.
/// "Less UI. More clarity."
class AppTheme {
  static const String fontFamily = 'Outfit';

  // Aven Brand Green
  static const Color primaryColor = Color(0xFF1EA95B);
  static const Color secondaryColor = Color(0xFF28C76F);
  static const Color tertiaryColor = Color(0xFF009688);

  // Pure OLED black backgrounds for infinite depth
  static const Color background = Color(0xFF040404); 

  // Surface colors (deep dark grey cards)
  static const Color surfaceLowest = Color(0xFF000000);
  static const Color surfaceLow = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF121212);
  static const Color surfaceHigh = Color(0xFF1C1C1E);
  static const Color surfaceHighest = Color(0xFF2C2C2E);

  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color error = Color(0xFFFF3B30);

  static const Curve emphasizedCurve = Cubic(0.2, 0.0, 0.0, 1.0);

  // Softened premium corner radius
  static const double radius = 20.0;

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        brightness: Brightness.dark,
        surface: surface,
        surfaceContainerLowest: surfaceLowest,
        surfaceContainerLow: surfaceLow,
        surfaceContainer: surface,
        surfaceContainerHigh: surfaceHigh,
        surfaceContainerHighest: surfaceHighest,
      ),
    );
    return _applySharedStyles(base);
  }

  static ThemeData get lightTheme => theme;
  static ThemeData get darkTheme => theme;

  static ThemeData _applySharedStyles(ThemeData base) {
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: fontFamily).copyWith(
        displayLarge: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1.0),
        displayMedium: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
        headlineLarge: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
        headlineMedium: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
        titleLarge: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: -0.2),
        titleMedium: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: -0.1),
        bodyLarge: const TextStyle(fontFamily: fontFamily, fontSize: 16, color: Colors.white70),
        bodyMedium: const TextStyle(fontFamily: fontFamily, fontSize: 14, color: Colors.white70),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: background, // Pure black top
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceHigh,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide.none, 
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius - 4)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius - 4)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius - 4)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: surfaceHighest),
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius - 4)),
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius - 4)),
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius - 4),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius - 4),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius - 4),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: const TextStyle(color: Colors.white38),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius - 4)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        tileColor: surfaceHigh,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        titleTextStyle: const TextStyle(fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceHigh,
        dragHandleColor: Colors.white24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius - 8)),
        backgroundColor: surfaceHighest,
        contentTextStyle: const TextStyle(fontFamily: fontFamily, color: Colors.white),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius - 8)),
        side: BorderSide.none,
        labelStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600, color: Colors.white),
        backgroundColor: surfaceHighest,
      ),
      dividerTheme: const DividerThemeData(
        color: surfaceHighest,
        thickness: 0.5,
        space: 0,
      ),
      splashFactory: NoSplash.splashFactory, // Removing ripple effect for a more instantaneous "pro" feel
      highlightColor: Colors.white.withValues(alpha: 0.05), // Very subtle tap highlights
      visualDensity: VisualDensity.adaptivePlatformDensity,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
