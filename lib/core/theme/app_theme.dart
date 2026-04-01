import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ─── Color Palette ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFF080812);
  static const Color surface = Color(0xFF0F0F1E);
  static const Color cardBg = Color(0xFF14142A);
  static const Color cardBgLight = Color(0xFF1C1C38);

  static const Color primary = Color(0xFF7C3AED);       // deep purple
  static const Color primaryLight = Color(0xFF9F67FA);
  static const Color secondary = Color(0xFF6366F1);     // indigo
  static const Color tertiary = Color(0xFF06B6D4);      // cyan
  static const Color accent = Color(0xFFA78BFA);        // soft lavender

  static const Color textPrimary = Color(0xFFF1F0FF);
  static const Color textSecondary = Color(0xFF9B99C4);
  static const Color textMuted = Color(0xFF5E5C80);

  static const Color divider = Color(0xFF1F1F3A);
  static const Color error = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF4CAF87);
  static const Color warning = Color(0xFFFFB347);
  static const Color ratingGold = Color(0xFFFFD700);

  // ─── Gradients ───────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF080812), Color(0xFF0D0D22)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF181832), Color(0xFF111128)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Theme ───────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF3D1D8A),
      onPrimaryContainer: accent,
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFF1F1F5E),
      onSecondaryContainer: accent,
      tertiary: tertiary,
      onTertiary: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: cardBg,
      outline: divider,
      error: error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: cardBg,

      // ── Navigation Bar ──
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface.withOpacity(0.95),
        indicatorColor: primary.withOpacity(0.25),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryLight, size: 24);
          }
          return const IconThemeData(color: textMuted, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600);
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(color: primaryLight);
          }
          return base.copyWith(color: textMuted);
        }),
        elevation: 0,
        height: 68,
      ),

      // ── App Bar ──
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),

      // ── Card ──
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: cardBgLight,
        labelStyle: GoogleFonts.inter(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),

      // ── Text ──
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -1.5),
        displayMedium: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -1),
        headlineLarge: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5),
        headlineMedium: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
        headlineSmall: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
        titleMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
        titleSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
        bodyLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: textPrimary, height: 1.6),
        bodyMedium: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: textSecondary, height: 1.5),
        bodySmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400, color: textMuted, height: 1.4),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
        labelSmall: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 0.5),
      ),

      // ── Divider ──
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      // ── Progress ──
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryLight,
      ),

      // ── Snackbar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardBgLight,
        contentTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Scaffold ──
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
