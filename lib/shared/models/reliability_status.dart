import 'package:flutter/material.dart';
import 'package:seerat_un_nabi/core/theme/app_colors.dart';

/// Historical claim reliability classification used across all chapters,
/// evidence views, and multilingual translations.
enum ReliabilityStatus {
  confirmed,
  weak,
  disputed;

  static ReliabilityStatus fromStorage(String value) => switch (value) {
        'confirmed' => ReliabilityStatus.confirmed,
        'weak' => ReliabilityStatus.weak,
        'disputed' => ReliabilityStatus.disputed,
        _ => ReliabilityStatus.disputed,
      };

  String get storageValue => name;

  String get urduLabel => switch (this) {
        ReliabilityStatus.confirmed => 'ثابت و مستند',
        ReliabilityStatus.weak => 'ضعیف روایت',
        ReliabilityStatus.disputed => 'مختلف فیہ',
      };

  String get urduDescription => switch (this) {
        ReliabilityStatus.confirmed =>
          'متعدد معتبر اور مستند تاریخی و روایتی شواہد سے ثابت شدہ بات',
        ReliabilityStatus.weak =>
          'ایسی روایت جس کی سند یا تاریخی ثبوت میں کمزوری پائی جاتی ہے',
        ReliabilityStatus.disputed =>
          'ایسا واقعہ یا تفصیل جس میں مؤرخین و محققین کے درمیان اختلاف ہے',
      };

  Color colorForBrightness(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return switch (this) {
        ReliabilityStatus.confirmed => AppColors.claimConfirmedDarkMode,
        ReliabilityStatus.weak => AppColors.claimWeakDarkMode,
        ReliabilityStatus.disputed => AppColors.claimDisputedDarkMode,
      };
    }
    return switch (this) {
      ReliabilityStatus.confirmed => AppColors.claimConfirmed,
      ReliabilityStatus.weak => AppColors.claimWeak,
      ReliabilityStatus.disputed => AppColors.claimDisputed,
    };
  }

  /// Canonical brand/badge color specified by the project standards.
  Color get canonicalColor => switch (this) {
        ReliabilityStatus.confirmed => AppColors.claimConfirmed,
        ReliabilityStatus.weak => AppColors.claimWeak,
        ReliabilityStatus.disputed => AppColors.claimDisputed,
      };
}
