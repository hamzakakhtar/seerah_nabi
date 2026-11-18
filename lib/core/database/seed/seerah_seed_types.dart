import 'package:seerat_un_nabi/shared/models/reliability_status.dart';
import 'package:sqflite/sqflite.dart';

/// Additional primary reference link attached to a single [SeedClaim].
class SeedEvidenceLink {
  const SeedEvidenceLink({
    required this.sourceRefId,
    required this.evidenceRole,
    required this.evidenceNotes,
    this.narrationId,
  });

  final String sourceRefId;
  final String evidenceRole;
  final String evidenceNotes;
  final String? narrationId;
}

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
    this.extraEvidence = const <SeedEvidenceLink>[],
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
  final List<SeedEvidenceLink> extraEvidence;
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

/// Inserts or safely updates a complete chapter (metadata, Urdu & Pashto
/// translations, sections, paragraphs, claims, and evidence links) within an
/// active `sqflite` transaction without deleting parent rows or breaking FKs.
Future<void> insertChapterContent(
  DatabaseExecutor txn,
  SeedChapterContent chapter, {
  bool upsertContent = false,
  bool replaceSections = false,
}) async {
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

  if (upsertContent) {
    await txn.update(
      'chapters',
      {
        'order_index': chapter.orderIndex,
        'era_code': chapter.eraCode,
        'route_key': chapter.routeKey,
        'is_published': 1,
      },
      where: 'stable_id = ?',
      whereArgs: [chapter.stableId],
    );
  }

  if (upsertContent && replaceSections) {
    await txn.delete(
      'sections',
      where: 'chapter_stable_id = ?',
      whereArgs: [chapter.stableId],
    );
  }

  final existingEvidencePairs = <String>{};
  if (upsertContent && !replaceSections) {
    final evRows = await txn.rawQuery(
      '''
      SELECT ce.claim_stable_id, ce.source_reference_stable_id
      FROM claim_evidence ce
      INNER JOIN historical_claims hc ON hc.stable_id = ce.claim_stable_id
      WHERE hc.chapter_stable_id = ?
      ''',
      [chapter.stableId],
    );
    for (final r in evRows) {
      final cid = r['claim_stable_id'];
      final srid = r['source_reference_stable_id'];
      if (cid is String && srid is String) {
        existingEvidencePairs.add('$cid:$srid');
      }
    }
  }

  final batch = txn.batch();

  void upsertTranslation(
    String table,
    Map<String, Object?> insertValues,
    Map<String, Object?> updateValues,
    String whereClause,
    List<Object?> whereArgs,
  ) {
    if (upsertContent) {
      batch.insert(
        table,
        insertValues,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      batch.update(
        table,
        updateValues,
        where: whereClause,
        whereArgs: whereArgs,
      );
    } else {
      batch.insert(
        table,
        insertValues,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  upsertTranslation(
    'chapter_translations',
    {
      'chapter_stable_id': chapter.stableId,
      'language_code': 'ur',
      'title': chapter.titleUrdu,
      'subtitle': chapter.subtitleUrdu,
      'era_label': chapter.eraLabelUrdu,
      'summary': chapter.summaryUrdu,
    },
    {
      'title': chapter.titleUrdu,
      'subtitle': chapter.subtitleUrdu,
      'era_label': chapter.eraLabelUrdu,
      'summary': chapter.summaryUrdu,
    },
    'chapter_stable_id = ? AND language_code = ?',
    [chapter.stableId, 'ur'],
  );

  upsertTranslation(
    'chapter_translations',
    {
      'chapter_stable_id': chapter.stableId,
      'language_code': 'ps',
      'title': chapter.titlePashto,
      'subtitle': chapter.subtitlePashto,
      'era_label': chapter.eraLabelPashto,
      'summary': chapter.summaryPashto,
    },
    {
      'title': chapter.titlePashto,
      'subtitle': chapter.subtitlePashto,
      'era_label': chapter.eraLabelPashto,
      'summary': chapter.summaryPashto,
    },
    'chapter_stable_id = ? AND language_code = ?',
    [chapter.stableId, 'ps'],
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
    if (upsertContent) {
      batch.update(
        'sections',
        {'order_index': section.orderIndex},
        where: 'stable_id = ?',
        whereArgs: [section.stableId],
      );
    }

    upsertTranslation(
      'section_translations',
      {
        'section_stable_id': section.stableId,
        'language_code': 'ur',
        'title': section.titleUrdu,
      },
      {'title': section.titleUrdu},
      'section_stable_id = ? AND language_code = ?',
      [section.stableId, 'ur'],
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
      if (upsertContent) {
        batch.update(
          'paragraphs',
          {
            'section_stable_id': section.stableId,
            'order_index': paragraph.orderIndex,
            'is_daily_eligible': paragraph.isDailyEligible ? 1 : 0,
          },
          where: 'stable_id = ?',
          whereArgs: [paragraph.stableId],
        );
      }

      upsertTranslation(
        'paragraph_translations',
        {
          'paragraph_stable_id': paragraph.stableId,
          'language_code': 'ur',
          'plain_text': paragraph.plainText,
        },
        {'plain_text': paragraph.plainText},
        'paragraph_stable_id = ? AND language_code = ?',
        [paragraph.stableId, 'ur'],
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
        if (upsertContent) {
          batch.update(
            'historical_claims',
            {
              'paragraph_stable_id': paragraph.stableId,
              'order_in_paragraph': claim.order,
              'reliability_status': claim.status.storageValue,
              'classification_reason': claim.reason,
              'scholarly_assessment': claim.assessment,
              'is_chronologically_verified': 1,
            },
            where: 'stable_id = ?',
            whereArgs: [claim.stableId],
          );
        }

        upsertTranslation(
          'historical_claim_translations',
          {
            'claim_stable_id': claim.stableId,
            'language_code': 'ur',
            'claim_text': claim.text,
          },
          {'claim_text': claim.text},
          'claim_stable_id = ? AND language_code = ?',
          [claim.stableId, 'ur'],
        );

        final evKey = '${claim.stableId}:${claim.sourceRefId}';
        if (!upsertContent || replaceSections || !existingEvidencePairs.contains(evKey)) {
          existingEvidencePairs.add(evKey);
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

        for (final extra in claim.extraEvidence) {
          final extraKey = '${claim.stableId}:${extra.sourceRefId}';
          if (!upsertContent || replaceSections || !existingEvidencePairs.contains(extraKey)) {
            existingEvidencePairs.add(extraKey);
            batch.insert(
              'claim_evidence',
              {
                'claim_stable_id': claim.stableId,
                'source_reference_stable_id': extra.sourceRefId,
                if (extra.narrationId != null) 'narration_stable_id': extra.narrationId,
                'evidence_role': extra.evidenceRole,
                'notes_urdu': extra.evidenceNotes,
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
        }
      }
    }
  }

  await batch.commit(noResult: true);
}

