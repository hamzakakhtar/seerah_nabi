import 'package:flutter/foundation.dart';
import 'package:seerat_un_nabi/shared/models/reliability_status.dart';

/// Individual historical claim whose [reliabilityStatus] remains invariant
/// across all language translations.
@immutable
class HistoricalClaimModel {
  const HistoricalClaimModel({
    required this.stableId,
    required this.paragraphStableId,
    required this.chapterStableId,
    required this.orderInParagraph,
    required this.reliabilityStatus,
    required this.claimText,
    required this.classificationReason,
    required this.scholarlyAssessment,
    required this.isChronologicallyVerified,
    this.explanationNote = '',
    this.researchVersionId,
  });

  final String stableId;
  final String paragraphStableId;
  final String chapterStableId;
  final int orderInParagraph;
  final ReliabilityStatus reliabilityStatus;
  final String claimText;
  final String classificationReason;
  final String scholarlyAssessment;
  final bool isChronologicallyVerified;
  final String explanationNote;
  final int? researchVersionId;
}

/// Ordered paragraph containing one or more split [claims] by reliability status.
@immutable
class ParagraphModel {
  const ParagraphModel({
    required this.stableId,
    required this.sectionStableId,
    required this.chapterStableId,
    required this.orderIndex,
    required this.plainText,
    required this.isDailyEligible,
    required this.claims,
  });

  final String stableId;
  final String sectionStableId;
  final String chapterStableId;
  final int orderIndex;
  final String plainText;
  final bool isDailyEligible;
  final List<HistoricalClaimModel> claims;
}

/// Logical section within a Seerah chapter.
@immutable
class SectionModel {
  const SectionModel({
    required this.stableId,
    required this.chapterStableId,
    required this.orderIndex,
    required this.title,
    required this.paragraphs,
  });

  final String stableId;
  final String chapterStableId;
  final int orderIndex;
  final String title;
  final List<ParagraphModel> paragraphs;
}

/// Full hydrated Seerah chapter with localized metadata and ordered sections.
@immutable
class ChapterModel {
  const ChapterModel({
    required this.stableId,
    required this.orderIndex,
    required this.eraCode,
    required this.routeKey,
    required this.title,
    required this.subtitle,
    required this.eraLabel,
    required this.summary,
    required this.isPublished,
    required this.sections,
  });

  final String stableId;
  final int orderIndex;
  final String eraCode;
  final String routeKey;
  final String title;
  final String subtitle;
  final String eraLabel;
  final String summary;
  final bool isPublished;
  final List<SectionModel> sections;
}
