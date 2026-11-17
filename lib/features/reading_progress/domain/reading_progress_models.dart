import 'package:flutter/foundation.dart';

@immutable
class ReadingProgressModel {
  const ReadingProgressModel({
    required this.chapterStableId,
    required this.scrollOffset,
    required this.completionFraction,
    required this.isLastActive,
    required this.updatedAt,
    this.sectionStableId,
    this.paragraphStableId,
  });

  final String chapterStableId;
  final String? sectionStableId;
  final String? paragraphStableId;
  final double scrollOffset;
  final double completionFraction;
  final bool isLastActive;
  final DateTime updatedAt;
}

@immutable
class ReadingSessionModel {
  const ReadingSessionModel({
    required this.id,
    required this.chapterStableId,
    required this.startedAt,
    required this.durationSeconds,
    required this.paragraphsRead,
    this.endedAt,
  });

  final int id;
  final String chapterStableId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final int paragraphsRead;
}
