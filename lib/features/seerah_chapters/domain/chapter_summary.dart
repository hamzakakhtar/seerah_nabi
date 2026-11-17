import 'package:flutter/foundation.dart';

/// Lightweight domain representation of a Seerah chapter used for indexing,
/// navigation, and Phase 1 structural verification.
@immutable
class ChapterSummary {
  const ChapterSummary({
    required this.stableId,
    required this.orderIndex,
    required this.titleUrdu,
    required this.subtitleUrdu,
    required this.routePath,
    required this.eraLabelUrdu,
  });

  /// Stable immutable identifier preserved across translations and DB updates.
  final String stableId;
  final int orderIndex;
  final String titleUrdu;
  final String subtitleUrdu;
  final String routePath;
  final String eraLabelUrdu;
}
