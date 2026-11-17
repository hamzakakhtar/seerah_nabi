import 'package:flutter/foundation.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/domain/chapter_summary.dart';

/// Immutable state for the Seerah Home Screen.
@immutable
class SeerahHomeState {
  const SeerahHomeState({
    required this.chapters,
    required this.lastChapterTitleUrdu,
    required this.lastChapterRoute,
    required this.progressFraction,
    this.lastScrollOffset = 0.0,
  });

  final List<ChapterSummary> chapters;
  final String lastChapterTitleUrdu;
  final String lastChapterRoute;
  final double progressFraction;
  final double lastScrollOffset;
}
