import 'package:flutter/foundation.dart';

@immutable
class PronunciationEntryModel {
  const PronunciationEntryModel({
    required this.stableId,
    required this.termArabic,
    required this.termUrdu,
    required this.transliteration,
    required this.phoneticGuide,
    required this.urduExplanation,
  });

  final String stableId;
  final String termArabic;
  final String termUrdu;
  final String transliteration;
  final String phoneticGuide;
  final String urduExplanation;
}
