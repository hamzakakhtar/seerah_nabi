import 'package:flutter/foundation.dart';

enum SourceTradition {
  sunni,
  shia,
  classicalHistory,
  biographical;

  static SourceTradition fromStorage(String value) => switch (value) {
        'sunni' => SourceTradition.sunni,
        'shia' => SourceTradition.shia,
        'classical_history' => SourceTradition.classicalHistory,
        _ => SourceTradition.biographical,
      };

  String get storageValue => switch (this) {
        SourceTradition.sunni => 'sunni',
        SourceTradition.shia => 'shia',
        SourceTradition.classicalHistory => 'classical_history',
        SourceTradition.biographical => 'biographical',
      };
}

enum EvidenceRole {
  primarySupport,
  corroborating,
  conflicting,
  weaknessReason;

  static EvidenceRole fromStorage(String value) => switch (value) {
        'primary_support' => EvidenceRole.primarySupport,
        'corroborating' => EvidenceRole.corroborating,
        'conflicting' => EvidenceRole.conflicting,
        _ => EvidenceRole.weaknessReason,
      };

  String get storageValue => switch (this) {
        EvidenceRole.primarySupport => 'primary_support',
        EvidenceRole.corroborating => 'corroborating',
        EvidenceRole.conflicting => 'conflicting',
        EvidenceRole.weaknessReason => 'weakness_reason',
      };
}

@immutable
class SourceModel {
  const SourceModel({
    required this.stableId,
    required this.titleArabic,
    required this.titleUrdu,
    required this.authorArabic,
    required this.authorUrdu,
    required this.tradition,
    required this.sourceType,
    this.authorDeathHijri,
  });

  final String stableId;
  final String titleArabic;
  final String titleUrdu;
  final String authorArabic;
  final String authorUrdu;
  final SourceTradition tradition;
  final String sourceType;
  final int? authorDeathHijri;
}

@immutable
class SourceReferenceModel {
  const SourceReferenceModel({
    required this.stableId,
    required this.source,
    required this.volume,
    required this.pageNumber,
    required this.sectionOrHadithNumber,
    required this.originalArabicExcerpt,
    required this.urduTranslation,
  });

  final String stableId;
  final SourceModel source;
  final String volume;
  final String pageNumber;
  final String sectionOrHadithNumber;
  final String originalArabicExcerpt;
  final String urduTranslation;
}

@immutable
class NarratorModel {
  const NarratorModel({
    required this.stableId,
    required this.nameArabic,
    required this.nameUrdu,
    required this.scholarlyGrading,
    required this.biographicalNote,
    this.deathHijri,
  });

  final String stableId;
  final String nameArabic;
  final String nameUrdu;
  final String scholarlyGrading;
  final String biographicalNote;
  final int? deathHijri;
}

@immutable
class NarrationModel {
  const NarrationModel({
    required this.stableId,
    required this.reference,
    required this.matnArabic,
    required this.urduSummary,
    required this.isnadChainSummary,
    required this.hadithGrade,
    required this.historicalWeightNote,
    required this.tradition,
    required this.narrators,
  });

  final String stableId;
  final SourceReferenceModel reference;
  final String matnArabic;
  final String urduSummary;
  final String isnadChainSummary;
  final String hadithGrade;
  final String historicalWeightNote;
  final SourceTradition tradition;
  final List<NarratorModel> narrators;
}

@immutable
class ClaimEvidenceModel {
  const ClaimEvidenceModel({
    required this.id,
    required this.claimStableId,
    required this.reference,
    required this.evidenceRole,
    required this.notesUrdu,
    this.narration,
  });

  final int id;
  final String claimStableId;
  final SourceReferenceModel reference;
  final EvidenceRole evidenceRole;
  final String notesUrdu;
  final NarrationModel? narration;
}
