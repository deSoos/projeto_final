import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // shared palette
  static const Color primary      = Color(0xFF6B3FA0);
  static const Color primaryLight = Color(0xFF9B6FCF);
  static const Color primaryDark  = Color(0xFF4A2B72);
  static const Color onPrimary    = Color(0xFFFFFFFF);

  // light
  static const Color background   = Color(0xFFF8F7FC);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF1A1A2E);
  static const Color onSurface    = Color(0xFF2D2D44);
  static const Color subtle       = Color(0xFFB0A8C8);

  // dark
  static const Color backgroundDark   = Color(0xFF12101C);
  static const Color surfaceDark      = Color(0xFF1E1A2E);
  static const Color onBackgroundDark = Color(0xFFF0EDF8);
  static const Color onSurfaceDark    = Color(0xFFCDC8E8);
  static const Color subtleDark       = Color(0xFF7A7098);

  static ThemeData get theme      => _build(Brightness.light);
  static ThemeData get darkTheme  => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg     = isDark ? backgroundDark   : background;
    final surf   = isDark ? surfaceDark      : surface;
    final onBg   = isDark ? onBackgroundDark : onBackground;
    final onSurf = isDark ? onSurfaceDark    : onSurface;
    final sub    = isDark ? subtleDark       : subtle;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: onPrimary,
        secondary: primaryLight,
        onSecondary: onPrimary,
        error: const Color(0xFFE53E3E),
        onError: onPrimary,
        surface: surf,
        onSurface: onSurf,
      ),
      scaffoldBackgroundColor: bg,
      fontFamily: 'Georgia',
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: onBg, letterSpacing: -0.5),
        titleLarge:   TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: onBg),
        titleMedium:  TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: onBg),
        bodyLarge:    TextStyle(fontSize: 16, color: onSurf, height: 1.5),
        bodyMedium:   TextStyle(fontSize: 14, color: sub,    height: 1.4),
        labelLarge:   const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: onPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : sub,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? primary.withValues(alpha: 0.4)
              : sub.withValues(alpha: 0.3),
        ),
      ),
      dividerColor: sub.withValues(alpha: 0.25),
      cardColor: surf,
    );
  }
}
