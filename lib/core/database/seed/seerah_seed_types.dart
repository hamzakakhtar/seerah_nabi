import 'package:seerat_un_nabi/shared/models/reliability_status.dart';
import 'package:sqflite/sqflite.dart';

/// Shared immutable seed data contracts for Seerah chapters, sections,
/// paragraphs, claims, and primary evidence backed by plain `sqflite`.
class SeedClaim {
  const SeedClaim({
    required this.stableId,
    required this.order,
    required this.status,
    required this.text,
    required this.reason,
    required this.assessment,
    required this.sourceRefId,
    required this.evidenceRole,
    required this.evidenceNotes,
  });

  final String stableId;
  final int order;
  final ReliabilityStatus status;
  final String text;
  final String reason;
  final String assessment;
  final String sourceRefId;
  final String evidenceRole;
  final String evidenceNotes;
}

class SeedParagraph {
  const SeedParagraph({
    required this.stableId,
    required this.orderIndex,
    required this.isDailyEligible,
    required this.plainText,
    required this.claims,
  });

  final String stableId;
  final int orderIndex;
  final bool isDailyEligible;
  final String plainText;
  final List<SeedClaim> claims;
}

class SeedSection {
  const SeedSection({
    required this.stableId,
    required this.orderIndex,
    required this.titleUrdu,
    required this.paragraphs,
  });

  final String stableId;
  final int orderIndex;
  final String titleUrdu;
  final List<SeedParagraph> paragraphs;
}

class SeedChapterContent {
  const SeedChapterContent({
    required this.stableId,
    required this.orderIndex,
    required this.eraCode,
    required this.routeKey,
    required this.titleUrdu,
    required this.subtitleUrdu,
    required this.eraLabelUrdu,
    required this.summaryUrdu,
    required this.titlePashto,
    required this.subtitlePashto,
    required this.eraLabelPashto,
    required this.summaryPashto,
    required this.sections,
  });

  final String stableId;
  final int orderIndex;
  final String eraCode;
  final String routeKey;
  final String titleUrdu;
  final String subtitleUrdu;
  final String eraLabelUrdu;
  final String summaryUrdu;
  final String titlePashto;
  final String subtitlePashto;
  final String eraLabelPashto;
  final String summaryPashto;
  final List<SeedSection> sections;
}

/// Inserts a complete chapter (metadata, Urdu & Pashto translations, sections,
/// paragraphs, claims, and evidence links) within an active `sqflite`
/// transaction.
Future<void> insertChapterContent(
  DatabaseExecutor txn,
  SeedChapterContent chapter,
) async {
  await txn.insert(
    'chapters',
    {
      'stable_id': chapter.stableId,
      'order_index': chapter.orderIndex,
      'era_code': chapter.eraCode,
      'route_key': chapter.routeKey,
      'is_published': 1,
    },
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );

  final batch = txn.batch();

  batch.insert(
    'chapter_translations',
    {
      'chapter_stable_id': chapter.stableId,
      'language_code': 'ur',
      'title': chapter.titleUrdu,
      'subtitle': chapter.subtitleUrdu,
      'era_label': chapter.eraLabelUrdu,
      'summary': chapter.summaryUrdu,
    },
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );

  batch.insert(
    'chapter_translations',
    {
      'chapter_stable_id': chapter.stableId,
      'language_code': 'ps',
      'title': chapter.titlePashto,
      'subtitle': chapter.subtitlePashto,
      'era_label': chapter.eraLabelPashto,
      'summary': chapter.summaryPashto,
    },
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );

  for (final section in chapter.sections) {
    batch.insert(
      'sections',
      {
        'stable_id': section.stableId,
        'chapter_stable_id': chapter.stableId,
        'order_index': section.orderIndex,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    batch.insert(
      'section_translations',
      {
        'section_stable_id': section.stableId,
        'language_code': 'ur',
        'title': section.titleUrdu,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    for (final paragraph in section.paragraphs) {
      batch.insert(
        'paragraphs',
        {
          'stable_id': paragraph.stableId,
          'section_stable_id': section.stableId,
          'chapter_stable_id': chapter.stableId,
          'order_index': paragraph.orderIndex,
          'is_daily_eligible': paragraph.isDailyEligible ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      batch.insert(
        'paragraph_translations',
        {
          'paragraph_stable_id': paragraph.stableId,
          'language_code': 'ur',
          'plain_text': paragraph.plainText,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      for (final claim in paragraph.claims) {
        batch.insert(
          'historical_claims',
          {
            'stable_id': claim.stableId,
            'paragraph_stable_id': paragraph.stableId,
            'chapter_stable_id': chapter.stableId,
            'order_in_paragraph': claim.order,
            'reliability_status': claim.status.storageValue,
            'classification_reason': claim.reason,
            'scholarly_assessment': claim.assessment,
            'is_chronologically_verified': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        batch.insert(
          'historical_claim_translations',
          {
            'claim_stable_id': claim.stableId,
            'language_code': 'ur',
            'claim_text': claim.text,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        batch.insert(
          'claim_evidence',
          {
            'claim_stable_id': claim.stableId,
            'source_reference_stable_id': claim.sourceRefId,
            'evidence_role': claim.evidenceRole,
            'notes_urdu': claim.evidenceNotes,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  await batch.commit(noResult: true);
}
