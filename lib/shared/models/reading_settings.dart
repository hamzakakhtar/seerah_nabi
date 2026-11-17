import 'package:flutter/material.dart';
import 'package:seerat_un_nabi/core/constants/app_constants.dart';
import 'package:seerat_un_nabi/core/utils/rtl_helper.dart';

/// Immutable reader preferences shared across all chapters and screens.
@immutable
class ReadingSettings {
  const ReadingSettings({
    this.fontSize = AppConstants.defaultReadingFontSize,
    this.locale = RtlHelper.urduLocale,
    this.hasSeenReliabilityLegend = false,
  });

  final double fontSize;
  final Locale locale;
  final bool hasSeenReliabilityLegend;

  ReadingSettings copyWith({
    double? fontSize,
    Locale? locale,
    bool? hasSeenReliabilityLegend,
  }) {
    return ReadingSettings(
      fontSize: fontSize ?? this.fontSize,
      locale: locale ?? this.locale,
      hasSeenReliabilityLegend:
          hasSeenReliabilityLegend ?? this.hasSeenReliabilityLegend,
    );
  }
}
