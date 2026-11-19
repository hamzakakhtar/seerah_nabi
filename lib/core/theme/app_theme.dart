import 'package:flutter/material.dart';
import 'package:seerat_un_nabi/core/constants/app_constants.dart';
import 'package:seerat_un_nabi/core/theme/app_colors.dart';
import 'package:seerat_un_nabi/core/theme/app_typography.dart';

/// Builds light and dark [ThemeData] optimized for long-form Urdu reading.
abstract final class AppTheme {
  static ThemeData light({
    double readingFontSize = AppConstants.defaultReadingFontSize,
  }) {
    final colorScheme = const ColorScheme.light(
      primary: AppColors.lightPrimary,
      onPrimary: Colors.white,
      secondary: AppColors.lightSecondary,
      onSecondary: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      outline: AppColors.lightBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTypography.urduFontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      textTheme: AppTypography.buildTextTheme(
        primaryTextColor: AppColors.lightTextPrimary,
        secondaryTextColor: AppColors.lightTextSecondary,
        readingFontSize: readingFontSize,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: AppTypography.urduHeading(
          color: AppColors.lightTextPrimary,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
      ),
    );
  }

  static ThemeData dark({
    double readingFontSize = AppConstants.defaultReadingFontSize,
  }) {
    final colorScheme = const ColorScheme.dark(
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkBackground,
      secondary: AppColors.darkSecondary,
      onSecondary: AppColors.darkBackground,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      outline: AppColors.darkBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTypography.urduFontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: AppTypography.buildTextTheme(
        primaryTextColor: AppColors.darkTextPrimary,
        secondaryTextColor: AppColors.darkTextSecondary,
        readingFontSize: readingFontSize,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: AppTypography.urduHeading(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
      ),
    );
  }
}
