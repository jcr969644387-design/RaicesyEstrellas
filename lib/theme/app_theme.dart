import 'package:flutter/material.dart';

/// Paleta inspirada en el cielo nocturno, la luz de las estrellas y el bosque.
class AppColors {
  const AppColors._();

  // Noche
  static const Color night = Color(0xFF0A0F24);
  static const Color nightDeep = Color(0xFF060918);
  static const Color nightSurface = Color(0xFF141B3A);
  static const Color nightCard = Color(0xFF1B2450);

  // Luz
  static const Color star = Color(0xFFF6D57A);
  static const Color starSoft = Color(0xFFFFF1C9);
  static const Color lavender = Color(0xFFB7B3F5);
  static const Color leaf = Color(0xFF7CC8A4);
  static const Color root = Color(0xFFD39A64);
  static const Color rootGlow = Color(0xFFFFC98A);

  // Amanecer (modo claro)
  static const Color dawn = Color(0xFFF7F3EC);
  static const Color dawnSurface = Color(0xFFFFFFFF);
  static const Color dawnInk = Color(0xFF1E2447);
  static const Color dawnPrimary = Color(0xFF3F4C94);
  static const Color dawnSky = Color(0xFFE6E4F7);
}

class AppTheme {
  const AppTheme._();

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.lavender,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.star,
      onPrimary: AppColors.nightDeep,
      secondary: AppColors.leaf,
      onSecondary: AppColors.nightDeep,
      tertiary: AppColors.lavender,
      surface: AppColors.night,
      onSurface: const Color(0xFFF1F0FA),
      surfaceContainerHighest: AppColors.nightCard,
      outline: const Color(0xFF6F76A8),
    );
    return _base(scheme);
  }

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.dawnPrimary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.dawnPrimary,
      onPrimary: Colors.white,
      secondary: const Color(0xFF2F7D60),
      tertiary: const Color(0xFF8A5A2B),
      surface: AppColors.dawn,
      onSurface: AppColors.dawnInk,
      surfaceContainerHighest: AppColors.dawnSky,
      outline: const Color(0xFF7A7F9E),
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
    );
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: scheme.brightness == Brightness.dark
            ? AppColors.nightDeep.withValues(alpha: 0.96)
            : AppColors.dawnSurface,
        indicatorColor: scheme.primary.withValues(alpha: 0.22),
        labelTextStyle: WidgetStatePropertyAll<TextStyle>(
          TextStyle(fontSize: 11, color: scheme.onSurface),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
      ),
      snackBarTheme:
          const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
