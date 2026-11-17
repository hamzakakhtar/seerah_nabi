import 'package:flutter/material.dart';

/// Utilities for right-to-left (RTL) Urdu/Pashto/Arabic/Persian layout and mixed-script text.
abstract final class RtlHelper {
  static const Locale urduLocale = Locale('ur', 'PK');
  static const Locale pashtoLocale = Locale('ps');
  static const Locale arabicLocale = Locale('ar');
  static const Locale persianLocale = Locale('fa');
  static const Locale englishLocale = Locale('en');

  static const List<Locale> supportedLocales = <Locale>[
    urduLocale,
    pashtoLocale,
    arabicLocale,
    persianLocale,
    englishLocale,
  ];

  static bool isRtlLanguageCode(String languageCode) {
    return languageCode == 'ur' ||
        languageCode == 'ps' ||
        languageCode == 'ar' ||
        languageCode == 'fa';
  }

  static TextDirection directionForLocale(Locale locale) {
    return isRtlLanguageCode(locale.languageCode)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  static String nativeLabelForCode(String languageCode) {
    return switch (languageCode) {
      'ur' => 'اردو',
      'ps' => 'پښتو',
      'ar' => 'العربية',
      'fa' => 'فارسی',
      'en' => 'English',
      _ => languageCode,
    };
  }

  static Locale materialDelegateLocaleFor(Locale? locale) {
    if (locale == null) return urduLocale;
    if (locale.languageCode == 'ps') {
      return urduLocale;
    }
    return locale;
  }

  /// Wraps a widget in an explicit [Directionality] when needed for previews
  /// or mixed-direction cards.
  static Widget ensureRtl({required Widget child}) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: child,
    );
  }
}
