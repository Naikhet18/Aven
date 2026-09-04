import 'package:flutter/material.dart';

/// Material 3 Expressive: real tonal surface layering (not just one card
/// color + a border), pill-shaped CTAs, a genuine tertiary accent, and an
/// emphasized easing curve for motion. All still zero-dependency -- every
/// effect here is ColorScheme/ThemeData, no extra packages.
class AppTheme {
  // Bundled locally as a variable font (assets/fonts/Outfit-Variable.ttf) --
  // Flutter/Skia interpolates the correct visual weight from the font's own
  // wght axis for any FontWeight used below, so one ~110KB file covers every
  // weight with zero network dependency. See the pubspec.yaml fonts: entry.
  static const String fontFamily = 'Outfit';

  // Emerald / Teal Primary
  static const Color primaryColor = Color(0xFF0F766E);
  static const Color secondaryColor = Color(0xFFF59E0B); // Amber
  // A warm gold tertiary -- distinct from the amber "warning" tone, reserved
  // for premium/highlight accents (hero cards, badges) so it reads as
  // intentional brand richness rather than a status color.
  static const Color tertiaryColor = Color(0xFFA16207);

  // Neutral Backgrounds
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color darkBackground = Color(0xFF0B1220);

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

  /// M3's "emphasized" motion curve -- a snappier, more deliberate feel
  /// than the platform default easeInOut, used for the app's signature
  /// interactions (press feedback, sheet/dialog entrances).
  static const Curve emphasizedCurve = Cubic(0.2, 0.0, 0.0, 1.0);

  static const double pillRadius = 999;

  static LinearGradient heroGradient({bool dark = false}) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? [const Color(0xFF115E59), const Color(0xFF0B1220)]
            : [primaryColor, Color.lerp(primaryColor, Colors.black, 0.35)!],
      );

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        brightness: Brightness.light,
        surface: Colors.white,
        // Full M3 tonal surface scale -- five distinct, clearly separated
        // steps instead of one flat card color, so stacked surfaces
        // (screen -> card -> nested tile) read as real depth without
        // needing heavier shadows. lightBackground itself sits between
        // Lowest and Low so a plain white card still lifts off the screen.
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFEFF2F6),
        surfaceContainer: const Color(0xFFE6EAF0),
        surfaceContainerHigh: const Color(0xFFDCE2EA),
        surfaceContainerHighest: const Color(0xFFCFD7E1),
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
        tertiary: tertiaryColor,
        brightness: Brightness.dark,
        surface: const Color(0xFF121A2B),
        surfaceContainerLowest: const Color(0xFF070B14),
        surfaceContainerLow: const Color(0xFF101828),
        surfaceContainer: const Color(0xFF162034),
        surfaceContainerHigh: const Color(0xFF1C2740),
        surfaceContainerHighest: const Color(0xFF25314C),
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
        color: base.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: base.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pillRadius)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pillRadius)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pillRadius)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          side: BorderSide(color: base.colorScheme.outlineVariant),
          textStyle: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pillRadius)),
          textStyle: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 1,
        highlightElevation: 2,
        backgroundColor: tertiaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pillRadius)),
          textStyle: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base.colorScheme.surfaceContainer.withValues(alpha: 0.6),
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
        height: 68,
        backgroundColor: base.colorScheme.surface,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pillRadius)),
        indicatorColor: primaryColor.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryColor, size: 26);
          }
          return IconThemeData(color: base.colorScheme.onSurfaceVariant, size: 24);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: base.colorScheme.surface,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pillRadius)),
        indicatorColor: primaryColor.withValues(alpha: 0.14),
        selectedIconTheme: const IconThemeData(color: primaryColor, size: 30),
        unselectedIconTheme: IconThemeData(color: base.colorScheme.onSurfaceVariant, size: 26),
        selectedLabelTextStyle: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w600, color: primaryColor),
        unselectedLabelTextStyle: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w500, color: base.colorScheme.onSurfaceVariant),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: base.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: TextStyle(fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.bold, color: base.colorScheme.onSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: base.colorScheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: base.colorScheme.inverseSurface,
        contentTextStyle: TextStyle(fontFamily: fontFamily, color: base.colorScheme.onInverseSurface),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pillRadius)),
        side: BorderSide(color: base.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        labelStyle: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600, color: base.colorScheme.onSurface),
        backgroundColor: base.colorScheme.surfaceContainer,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor.withValues(alpha: 0.4);
          return null;
        }),
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
