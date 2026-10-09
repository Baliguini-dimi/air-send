import 'package:flutter/material.dart';

/// Palette Corporate Sobre — voir docs/DESIGN_SYSTEM.md
class AppColors {
  // Mode clair
  static const lightBackground = Color(0xFFF7F7F5);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightTextPrimary = Color(0xFF0F1B2D);
  static const lightTextSecondary = Color(0xFF5C6B7A);
  static const lightBorder = Color(0xFFE3E6EA);
  static const defaultAccent = Color(0xFF3B6E91);

  // Mode sombre
  static const darkBackground = Color(0xFF0F1B2D);
  static const darkSurface = Color(0xFF182636);
  static const darkTextPrimary = Color(0xFFF7F7F5);
  static const darkTextSecondary = Color(0xFF8A97A6);
  static const darkBorder = Color(0xFF28394D);
  static const defaultAccentDark = Color(0xFF5B8DAE);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: ColorScheme.light(
        primary: AppColors.defaultAccent,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
      ),
      cardColor: AppColors.lightSurface,
      dividerColor: AppColors.lightBorder,
      textTheme: _textTheme(
        AppColors.lightTextPrimary,
        AppColors.lightTextSecondary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightTextPrimary,
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        indicatorColor: AppColors.defaultAccent.withValues(alpha: 0.16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: AppColors.defaultAccentDark,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
      ),
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkBorder,
      textTheme: _textTheme(
        AppColors.darkTextPrimary,
        AppColors.darkTextSecondary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.defaultAccentDark.withValues(alpha: 0.24),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      useMaterial3: true,
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: primary),
      bodyMedium: TextStyle(fontSize: 14, color: secondary),
      labelSmall: TextStyle(fontSize: 12, color: secondary),
    );
  }
}
