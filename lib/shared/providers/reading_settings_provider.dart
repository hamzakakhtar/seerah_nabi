import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/core/constants/app_constants.dart';
import 'package:seerat_un_nabi/shared/models/reading_settings.dart';

/// Global Riverpod provider managing reading typography size, locale, and
/// first-open reliability legend visibility.
final readingSettingsProvider =
    NotifierProvider<ReadingSettingsNotifier, ReadingSettings>(
  ReadingSettingsNotifier.new,
);

class ReadingSettingsNotifier extends Notifier<ReadingSettings> {
  @override
  ReadingSettings build() => const ReadingSettings();

  void setFontSize(double size) {
    final clamped = size.clamp(
      AppConstants.minReadingFontSize,
      AppConstants.maxReadingFontSize,
    );
    state = state.copyWith(fontSize: clamped);
  }

  void increaseFontSize() {
    setFontSize(state.fontSize + 2);
  }

  void decreaseFontSize() {
    setFontSize(state.fontSize - 2);
  }

  void setLocale(Locale locale) {
    state = state.copyWith(locale: locale);
  }

  void dismissReliabilityLegend() {
    state = state.copyWith(hasSeenReliabilityLegend: true);
  }
}
