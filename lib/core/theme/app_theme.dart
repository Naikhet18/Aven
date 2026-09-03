import 'package:flutter/material.dart';

class AppTheme {
  // Bundled locally as a variable font (assets/fonts/Outfit-Variable.ttf) --
  // Flutter/Skia interpolates the correct visual weight from the font's own
  // wght axis for any FontWeight used below, so one ~110KB file covers every
  // weight with zero network dependency. See the pubspec.yaml fonts: entry.
  static const String fontFamily = 'Outfit';

  // Emerald / Teal Primary
  static const Color primaryColor = Color(0xFF0F766E);
  static const Color secondaryColor = Color(0xFFF59E0B); // Amber
  
  // Neutral Backgrounds
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  
  // Semantic colors: the base tone for icons/text on a light tinted
  // background (e.g. a status chip), and a darker "strong" tone for solid
  // fills that need to host white text at WCAG AA contrast (4.5:1) -- the
  // base amber, for instance, is too light for white text to read on.
  static const Color success = Color(0xFF10B981); // emerald-500
  static const Color successStrong = Color(0xFF047857); // emerald-700
  static const Color warning = Color(0xFFF59E0B); // amber-500
  static const Color warningStrong = Color(0xFFB45309); // amber-700
  static const Color error = Color(0xFFEF4444); // red-500
  static const Color errorStrong = Color(0xFFB91C1C); // red-700

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: secondaryColor,
        brightness: Brightness.light,
        surface: Colors.white,
        surfaceContainerHighest: const Color(0xFFF1F5F9), // Slate 100
      ),
    );
    return _applySharedStyles(base);
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: secondaryColor,
        brightness: Brightness.dark,
        surface: const Color(0xFF1E293B), // Slate 800
        surfaceContainerHighest: const Color(0xFF334155), // Slate 700
      ),
    );
    return _applySharedStyles(base);
  }

  static ThemeData _applySharedStyles(ThemeData base) {
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: fontFamily).copyWith(
        displayLarge: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold, color: base.colorScheme.onSurface),
        displayMedium: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.bold, color: base.colorScheme.onSurface),
        titleLarge: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600, color: base.colorScheme.onSurface),
        titleMedium: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600, color: base.colorScheme.onSurface),
        bodyLarge: TextStyle(fontFamily: fontFamily, fontSize: 16, color: base.colorScheme.onSurface),
        bodyMedium: TextStyle(fontFamily: fontFamily, fontSize: 14, color: base.colorScheme.onSurface),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: base.colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(color: base.colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: base.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: base.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: base.colorScheme.surface,
        indicatorColor: primaryColor.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryColor, size: 28);
          }
          return IconThemeData(color: base.colorScheme.onSurfaceVariant, size: 24);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: base.colorScheme.surface,
        indicatorColor: primaryColor.withValues(alpha: 0.1),
        selectedIconTheme: const IconThemeData(color: primaryColor, size: 32),
        unselectedIconTheme: IconThemeData(color: base.colorScheme.onSurfaceVariant, size: 28),
        selectedLabelTextStyle: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w600, color: primaryColor),
        unselectedLabelTextStyle: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w500, color: base.colorScheme.onSurfaceVariant),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: base.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: TextStyle(fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.bold, color: base.colorScheme.onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: base.colorScheme.inverseSurface,
        contentTextStyle: TextStyle(fontFamily: fontFamily, color: base.colorScheme.onInverseSurface),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: base.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        labelStyle: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600, color: base.colorScheme.onSurface),
      ),
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      // A softer, more modern fade-through motion for every push/pop
      // transition (GoRouter's default MaterialPage, Navigator.push dialogs,
      // etc.) instead of the platform-default zoom/slide.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
