import 'package:flutter/foundation.dart';
import 'package:seerat_un_nabi/core/constants/app_constants.dart';
import 'package:seerat_un_nabi/core/database/app_database.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/domain/chapter_models.dart';
import 'package:seerat_un_nabi/shared/models/reliability_status.dart';

@immutable
class DailySeerahEntry {
  const DailySeerahEntry({
    required this.paragraph,
    required this.chapterTitleUrdu,
    required this.eraLabelUrdu,
  });

  final ParagraphModel paragraph;
  final String chapterTitleUrdu;
  final String eraLabelUrdu;
}

abstract interface class DailySeerahRepository {
  Future<List<DailySeerahEntry>> getDailyEligibleEntries({
    String languageCode = AppConstants.defaultLanguageCode,
  });
}

final class SqliteDailySeerahRepository implements DailySeerahRepository {
  SqliteDailySeerahRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<DailySeerahEntry>> getDailyEligibleEntries({
    String languageCode = AppConstants.defaultLanguageCode,
  }) async {
    final db = await _db.database;
    final pRows = await db.query(
      'paragraphs',
      where: 'is_daily_eligible = 1',
      orderBy: 'chapter_stable_id ASC, order_index ASC',
    );
    if (pRows.isEmpty) return const <DailySeerahEntry>[];

    final chapterIds = pRows
        .map((p) => AppDatabase.readString(p['chapter_stable_id']))
        .toSet()
        .toList(growable: false);
    final chPh = AppDatabase.placeholders(chapterIds.length);
    final chapterTrs = await db.query(
      'chapter_translations',
      where: 'chapter_stable_id IN ($chPh) AND language_code = ?',
      whereArgs: [...chapterIds, languageCode],
    );
    final fallbackChapterTrs =
        languageCode == AppConstants.defaultLanguageCode
            ? chapterTrs
            : await db.query(
                'chapter_translations',
                where: 'chapter_stable_id IN ($chPh) AND language_code = ?',
                whereArgs: [...chapterIds, AppConstants.defaultLanguageCode],
              );
    final chapterMap = <String, Map<String, Object?>>{
      for (final c in fallbackChapterTrs)
        AppDatabase.readString(c['chapter_stable_id']): c,
      for (final c in chapterTrs)
        AppDatabase.readString(c['chapter_stable_id']): c,
    };

    final pIds = pRows
        .map((p) => AppDatabase.readString(p['stable_id']))
        .toList(growable: false);
    final pPh = AppDatabase.placeholders(pIds.length);
    final pTrs = await db.query(
      'paragraph_translations',
      where: 'paragraph_stable_id IN ($pPh) AND language_code = ?',
      whereArgs: [...pIds, languageCode],
    );
    final fallbackPTrs = languageCode == AppConstants.defaultLanguageCode
        ? pTrs
        : await db.query(
            'paragraph_translations',
            where: 'paragraph_stable_id IN ($pPh) AND language_code = ?',
            whereArgs: [...pIds, AppConstants.defaultLanguageCode],
          );
    final pTextMap = <String, String>{
      for (final p in fallbackPTrs)
        AppDatabase.readString(p['paragraph_stable_id']):
            AppDatabase.readString(p['plain_text']),
      for (final p in pTrs)
        AppDatabase.readString(p['paragraph_stable_id']):
            AppDatabase.readString(p['plain_text']),
    };

    final claimRows = await db.query(
      'historical_claims',
      where: 'paragraph_stable_id IN ($pPh)',
      orderBy: 'order_in_paragraph ASC',
      whereArgs: pIds,
    );
    final claimIds = claimRows
        .map((c) => AppDatabase.readString(c['stable_id']))
        .toList(growable: false);
    final claimTrs = claimIds.isEmpty
        ? const <Map<String, Object?>>[]
        : await db.query(
            'historical_claim_translations',
            where:
                'claim_stable_id IN (${AppDatabase.placeholders(claimIds.length)}) AND language_code = ?',
            whereArgs: [...claimIds, languageCode],
          );
    final fallbackClaimTrs = claimIds.isEmpty ||
            languageCode == AppConstants.defaultLanguageCode
        ? claimTrs
        : await db.query(
            'historical_claim_translations',
            where:
                'claim_stable_id IN (${AppDatabase.placeholders(claimIds.length)}) AND language_code = ?',
            whereArgs: [...claimIds, AppConstants.defaultLanguageCode],
          );
    final claimTrMap = <String, Map<String, Object?>>{
      for (final c in fallbackClaimTrs)
        AppDatabase.readString(c['claim_stable_id']): c,
      for (final c in claimTrs) AppDatabase.readString(c['claim_stable_id']): c,
    };

    final claimsByParagraph = <String, List<HistoricalClaimModel>>{};
    for (final c in claimRows) {
      final claimId = AppDatabase.readString(c['stable_id']);
      final paragraphId = AppDatabase.readString(c['paragraph_stable_id']);
      final tr = claimTrMap[claimId];
      claimsByParagraph.putIfAbsent(paragraphId, () => []).add(
            HistoricalClaimModel(
              stableId: claimId,
              paragraphStableId: paragraphId,
              chapterStableId: AppDatabase.readString(c['chapter_stable_id']),
              orderInParagraph: AppDatabase.readInt(c['order_in_paragraph']),
              reliabilityStatus: ReliabilityStatus.fromStorage(
                AppDatabase.readString(c['reliability_status']),
              ),
              claimText:
                  tr != null ? AppDatabase.readString(tr['claim_text']) : '',
              classificationReason:
                  AppDatabase.readString(c['classification_reason']),
              scholarlyAssessment:
                  AppDatabase.readString(c['scholarly_assessment']),
              isChronologicallyVerified: AppDatabase.readBool(
                c['is_chronologically_verified'],
              ),
              explanationNote: tr != null
                  ? AppDatabase.readString(tr['explanation_note'])
                  : '',
            ),
          );
    }

    return pRows.map((p) {
      final pId = AppDatabase.readString(p['stable_id']);
      final chId = AppDatabase.readString(p['chapter_stable_id']);
      final ch = chapterMap[chId];
      return DailySeerahEntry(
        paragraph: ParagraphModel(
          stableId: pId,
          sectionStableId: AppDatabase.readString(p['section_stable_id']),
          chapterStableId: chId,
          orderIndex: AppDatabase.readInt(p['order_index']),
          plainText: pTextMap[pId] ?? '',
          isDailyEligible: AppDatabase.readBool(p['is_daily_eligible']),
          claims: List.unmodifiable(
            claimsByParagraph[pId] ?? const <HistoricalClaimModel>[],
          ),
        ),
        chapterTitleUrdu:
            ch != null ? AppDatabase.readString(ch['title'], chId) : chId,
        eraLabelUrdu: ch != null ? AppDatabase.readString(ch['era_label']) : '',
      );
    }).toList(growable: false);
  }
}
