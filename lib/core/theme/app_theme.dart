import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Emerald / Teal Primary
  static const Color primaryColor = Color(0xFF0F766E);
  static const Color secondaryColor = Color(0xFFF59E0B); // Amber
  
  // Neutral Backgrounds
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  
  // Custom semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

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
      textTheme: GoogleFonts.outfitTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: base.colorScheme.onSurface),
        displayMedium: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: base.colorScheme.onSurface),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: base.colorScheme.onSurface),
        titleMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: base.colorScheme.onSurface),
        bodyLarge: GoogleFonts.outfit(fontSize: 16, color: base.colorScheme.onSurface),
        bodyMedium: GoogleFonts.outfit(fontSize: 14, color: base.colorScheme.onSurface),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.outfit(
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
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
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
          GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
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
        selectedLabelTextStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: primaryColor),
        unselectedLabelTextStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: base.colorScheme.onSurfaceVariant),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: base.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: base.colorScheme.onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: base.colorScheme.inverseSurface,
        contentTextStyle: GoogleFonts.outfit(color: base.colorScheme.onInverseSurface),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: base.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: base.colorScheme.onSurface),
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
