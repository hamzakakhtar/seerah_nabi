import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seerat_un_nabi/core/constants/app_constants.dart';

/// Urdu & Arabic literary typography configuration.
///
/// Uses **Noto Nastaliq Urdu** for Urdu headings and long-form editorial prose
/// with generous line height (`2.15`) so Nastaliq ligatures and diacritics never
/// clip or collide, and **Amiri** for classical Arabic primary source quotes.
abstract final class AppTypography {
  static TextStyle urduBody({
    required Color color,
    double fontSize = AppConstants.defaultReadingFontSize,
    FontWeight fontWeight = FontWeight.w400,
    double height = AppConstants.urduNastaliqLineHeight,
  }) {
    return GoogleFonts.notoNastaliqUrdu(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
    );
  }

  static TextStyle urduHeading({
    required Color color,
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    double height = 1.9,
  }) {
    return GoogleFonts.notoNastaliqUrdu(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
    );
  }

  static TextStyle arabicSource({
    required Color color,
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w400,
    double height = AppConstants.arabicNaskhLineHeight,
  }) {
    return GoogleFonts.amiri(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
    );
  }

  static TextTheme buildTextTheme({
    required Color primaryTextColor,
    required Color secondaryTextColor,
    double readingFontSize = AppConstants.defaultReadingFontSize,
  }) {
    final base = GoogleFonts.notoNastaliqUrduTextTheme();
    return base.copyWith(
      headlineLarge: urduHeading(color: primaryTextColor, fontSize: 28),
      headlineMedium: urduHeading(color: primaryTextColor, fontSize: 24),
      titleLarge: urduHeading(color: primaryTextColor, fontSize: 20),
      titleMedium: urduBody(
        color: primaryTextColor,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.9,
      ),
      bodyLarge: urduBody(
        color: primaryTextColor,
        fontSize: readingFontSize,
      ),
      bodyMedium: urduBody(
        color: primaryTextColor,
        fontSize: readingFontSize - 2,
        height: 2.0,
      ),
      bodySmall: urduBody(
        color: secondaryTextColor,
        fontSize: 14,
        height: 1.85,
      ),
      labelLarge: urduBody(
        color: primaryTextColor,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.75,
      ),
    );
  }
}
