import 'package:flutter/material.dart';

/// Editorial Islamic book palette & mandatory historical claim reliability colors.
abstract final class AppColors {
  // Mandatory Historical Claim Reliability Colors
  static const Color claimConfirmed = Color(0xFF064E3B); // Dark Green
  static const Color claimWeak = Color(0xFF854D0E); // Dark Yellow / Amber
  static const Color claimDisputed = Color(0xFF7F1D1D); // Dark Red

  // Light Mode: Warm Parchment Editorial Palette
  static const Color lightBackground = Color(0xFFFAF6EE);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceMuted = Color(0xFFF2EBD9);
  static const Color lightPrimary = Color(0xFF14453D);
  static const Color lightSecondary = Color(0xFF9A6B2F);
  static const Color lightTextPrimary = Color(0xFF1E1B18);
  static const Color lightTextSecondary = Color(0xFF5C5349);
  static const Color lightBorder = Color(0xFFE3D8C3);

  // Dark Mode: Comfortable Low-Glare Night Reading Palette
  static const Color darkBackground = Color(0xFF121413);
  static const Color darkSurface = Color(0xFF1B1F1D);
  static const Color darkSurfaceMuted = Color(0xFF242926);
  static const Color darkPrimary = Color(0xFF4CA892);
  static const Color darkSecondary = Color(0xFFD4A762);
  static const Color darkTextPrimary = Color(0xFFEDE8DE);
  static const Color darkTextSecondary = Color(0xFFAFA79A);
  static const Color darkBorder = Color(0xFF2E3531);

  // High-contrast adapted claim text colors for dark surfaces
  static const Color claimConfirmedDarkMode = Color(0xFF6EE7B7);
  static const Color claimWeakDarkMode = Color(0xFFFCD34D);
  static const Color claimDisputedDarkMode = Color(0xFFFCA5A5);
}
