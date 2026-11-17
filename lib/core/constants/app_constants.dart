/// Core application-wide constants for the Seerat-un-Nabi ﷺ platform.
abstract final class AppConstants {
  static const String appNameUrdu = 'سیرت النبی ﷺ';
  static const String appNameEnglish = 'Seerat-un-Nabi ﷺ';

  /// Supported language codes matching the SQLite `languages` table.
  static const String defaultLanguageCode = 'ur';
  static const List<String> supportedLanguageCodes = <String>[
    'ur',
    'ps',
    'ar',
    'fa',
    'en',
  ];

  /// Reading typography defaults (tuned for Urdu Nastaliq legibility).
  static const double minReadingFontSize = 16.0;
  static const double defaultReadingFontSize = 20.0;
  static const double maxReadingFontSize = 30.0;
  static const double urduNastaliqLineHeight = 2.15;
  static const double arabicNaskhLineHeight = 1.95;

  /// Database identifier for offline-first SQLite setup.
  static const String databaseFileName = 'seerat_un_nabi.sqlite';
  static const int databaseSchemaVersion = 1;
}
