import 'package:flutter/foundation.dart';

/// Verified citation returned alongside any future AI Seerah research answer.
@immutable
class SeerahAiCitation {
  const SeerahAiCitation({
    required this.claimStableId,
    required this.sourceTitleUrdu,
    required this.referenceLabel,
  });

  final String claimStableId;
  final String sourceTitleUrdu;
  final String referenceLabel;
}

/// Structured AI response strictly grounded in verified SQLite research records.
@immutable
class SeerahAiAnswer {
  const SeerahAiAnswer({
    required this.answerUrdu,
    required this.citations,
    required this.isGroundedInLocalResearch,
  });

  final String answerUrdu;
  final List<SeerahAiCitation> citations;
  final bool isGroundedInLocalResearch;
}

/// Architectural interface for the Phase 8 "Ask AI About This Event" feature.
///
/// Private API keys must NEVER be embedded in Flutter client code; remote
/// inference must go through a secure server-side proxy.
abstract interface class SeerahAiService {
  Future<SeerahAiAnswer> askAboutEvent({
    required String questionUrdu,
    required String chapterStableId,
    String? claimStableId,
  });
}
