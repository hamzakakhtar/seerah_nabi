import 'package:seerat_un_nabi/core/constants/app_constants.dart';
import 'package:seerat_un_nabi/core/database/app_database.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/domain/chapter_models.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/domain/chapter_summary.dart';
import 'package:seerat_un_nabi/shared/models/reliability_status.dart';
import 'package:sqflite/sqflite.dart';

/// Repository contract for Seerah chapters, sections, paragraphs, and claims.
abstract interface class ChapterRepository {
  Future<List<ChapterSummary>> getChapterDirectory({
    String languageCode = AppConstants.defaultLanguageCode,
  });

  Future<ChapterSummary?> getChapterByStableId(
    String stableId, {
    String languageCode = AppConstants.defaultLanguageCode,
  });

  Future<ChapterModel?> getFullChapter(
    String stableId, {
    String languageCode = AppConstants.defaultLanguageCode,
  });

  Future<int> getTotalPublishedChapterCount();
}

/// Offline-first SQLite (`sqflite`) implementation of [ChapterRepository].
///
/// Designed to scale cleanly to hundreds of chapters using indexed queries and
/// stable immutable IDs across all translations.
final class SqliteChapterRepository implements ChapterRepository {
  SqliteChapterRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<ChapterSummary>> getChapterDirectory({
    String languageCode = AppConstants.defaultLanguageCode,
  }) async {
    final db = await _db.database;
    final rows = await db.query('chapters', orderBy: 'order_index ASC');
    if (rows.isEmpty) {
      return const <ChapterSummary>[];
    }

    final translations = await db.query(
      'chapter_translations',
      where: 'language_code = ?',
      whereArgs: [languageCode],
    );
    final fallbackTranslations =
        languageCode == AppConstants.defaultLanguageCode
            ? translations
            : await db.query(
                'chapter_translations',
                where: 'language_code = ?',
                whereArgs: [AppConstants.defaultLanguageCode],
              );

    final translationMap = <String, Map<String, Object?>>{
      for (final tr in fallbackTranslations)
        AppDatabase.readString(tr['chapter_stable_id']): tr,
      for (final tr in translations)
        AppDatabase.readString(tr['chapter_stable_id']): tr,
    };

    return rows.map((row) {
      final stableId = AppDatabase.readString(row['stable_id']);
      final tr = translationMap[stableId];
      return ChapterSummary(
        stableId: stableId,
        orderIndex: AppDatabase.readInt(row['order_index']),
        titleUrdu: tr != null
            ? AppDatabase.readString(tr['title'], stableId)
            : stableId,
        subtitleUrdu:
            tr != null ? AppDatabase.readString(tr['subtitle']) : '',
        routePath: AppDatabase.readString(row['route_key']),
        eraLabelUrdu: tr != null
            ? AppDatabase.readString(
                tr['era_label'],
                AppDatabase.readString(row['era_code']),
              )
            : AppDatabase.readString(row['era_code']),
      );
    }).toList(growable: false);
  }

  @override
  Future<ChapterSummary?> getChapterByStableId(
    String stableId, {
    String languageCode = AppConstants.defaultLanguageCode,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      'chapters',
      where: 'stable_id = ?',
      whereArgs: [stableId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;

    final tr = await _resolveChapterTranslation(db, stableId, languageCode);
    return ChapterSummary(
      stableId: stableId,
      orderIndex: AppDatabase.readInt(row['order_index']),
      titleUrdu:
          tr != null ? AppDatabase.readString(tr['title'], stableId) : stableId,
      subtitleUrdu: tr != null ? AppDatabase.readString(tr['subtitle']) : '',
      routePath: AppDatabase.readString(row['route_key']),
      eraLabelUrdu: tr != null
          ? AppDatabase.readString(
              tr['era_label'],
              AppDatabase.readString(row['era_code']),
            )
          : AppDatabase.readString(row['era_code']),
    );
  }

  @override
  Future<ChapterModel?> getFullChapter(
    String stableId, {
    String languageCode = AppConstants.defaultLanguageCode,
  }) async {
    final db = await _db.database;
    final chapterRows = await db.query(
      'chapters',
      where: 'stable_id = ?',
      whereArgs: [stableId],
      limit: 1,
    );
    if (chapterRows.isEmpty) return null;
    final chapterRow = chapterRows.first;

    final chapterTr =
        await _resolveChapterTranslation(db, stableId, languageCode);

    final sectionRows = await db.query(
      'sections',
      where: 'chapter_stable_id = ?',
      whereArgs: [stableId],
      orderBy: 'order_index ASC',
    );

    final paragraphRows = await db.query(
      'paragraphs',
      where: 'chapter_stable_id = ?',
      whereArgs: [stableId],
      orderBy: 'order_index ASC',
    );

    final claimRows = await db.query(
      'historical_claims',
      where: 'chapter_stable_id = ?',
      whereArgs: [stableId],
      orderBy: 'order_in_paragraph ASC',
    );

    final sectionTitleMap = await _loadSectionTitleMap(
      db,
      sectionRows
          .map((e) => AppDatabase.readString(e['stable_id']))
          .toList(growable: false),
      languageCode,
    );
    final paragraphTextMap = await _loadParagraphTextMap(
      db,
      paragraphRows
          .map((e) => AppDatabase.readString(e['stable_id']))
          .toList(growable: false),
      languageCode,
    );
    final claimTextMap = await _loadClaimTranslationMap(
      db,
      claimRows
          .map((e) => AppDatabase.readString(e['stable_id']))
          .toList(growable: false),
      languageCode,
    );

    final claimsByParagraph = <String, List<HistoricalClaimModel>>{};
    for (final claim in claimRows) {
      final claimStableId = AppDatabase.readString(claim['stable_id']);
      final paragraphStableId =
          AppDatabase.readString(claim['paragraph_stable_id']);
      final tr = claimTextMap[claimStableId];
      claimsByParagraph.putIfAbsent(paragraphStableId, () => []).add(
            HistoricalClaimModel(
              stableId: claimStableId,
              paragraphStableId: paragraphStableId,
              chapterStableId:
                  AppDatabase.readString(claim['chapter_stable_id']),
              orderInParagraph:
                  AppDatabase.readInt(claim['order_in_paragraph']),
              reliabilityStatus: ReliabilityStatus.fromStorage(
                AppDatabase.readString(claim['reliability_status']),
              ),
              claimText:
                  tr != null ? AppDatabase.readString(tr['claim_text']) : '',
              classificationReason:
                  AppDatabase.readString(claim['classification_reason']),
              scholarlyAssessment:
                  AppDatabase.readString(claim['scholarly_assessment']),
              isChronologicallyVerified: AppDatabase.readBool(
                claim['is_chronologically_verified'],
              ),
              explanationNote: tr != null
                  ? AppDatabase.readString(tr['explanation_note'])
                  : '',
              researchVersionId: AppDatabase.readNullableInt(
                claim['research_version_id'],
              ),
            ),
          );
    }

    final paragraphsBySection = <String, List<ParagraphModel>>{};
    for (final p in paragraphRows) {
      final pStableId = AppDatabase.readString(p['stable_id']);
      final sStableId = AppDatabase.readString(p['section_stable_id']);
      paragraphsBySection.putIfAbsent(sStableId, () => []).add(
            ParagraphModel(
              stableId: pStableId,
              sectionStableId: sStableId,
              chapterStableId: AppDatabase.readString(p['chapter_stable_id']),
              orderIndex: AppDatabase.readInt(p['order_index']),
              plainText: paragraphTextMap[pStableId] ?? '',
              isDailyEligible: AppDatabase.readBool(p['is_daily_eligible']),
              claims: List.unmodifiable(
                claimsByParagraph[pStableId] ?? const <HistoricalClaimModel>[],
              ),
            ),
          );
    }

    final sections = sectionRows.map((s) {
      final sStableId = AppDatabase.readString(s['stable_id']);
      return SectionModel(
        stableId: sStableId,
        chapterStableId: AppDatabase.readString(s['chapter_stable_id']),
        orderIndex: AppDatabase.readInt(s['order_index']),
        title: sectionTitleMap[sStableId] ?? sStableId,
        paragraphs: List.unmodifiable(
          paragraphsBySection[sStableId] ?? const <ParagraphModel>[],
        ),
      );
    }).toList(growable: false);

    return ChapterModel(
      stableId: AppDatabase.readString(chapterRow['stable_id']),
      orderIndex: AppDatabase.readInt(chapterRow['order_index']),
      eraCode: AppDatabase.readString(chapterRow['era_code']),
      routeKey: AppDatabase.readString(chapterRow['route_key']),
      title: chapterTr != null
          ? AppDatabase.readString(chapterTr['title'], stableId)
          : stableId,
      subtitle: chapterTr != null
          ? AppDatabase.readString(chapterTr['subtitle'])
          : '',
      eraLabel: chapterTr != null
          ? AppDatabase.readString(
              chapterTr['era_label'],
              AppDatabase.readString(chapterRow['era_code']),
            )
          : AppDatabase.readString(chapterRow['era_code']),
      summary:
          chapterTr != null ? AppDatabase.readString(chapterTr['summary']) : '',
      isPublished: AppDatabase.readBool(chapterRow['is_published']),
      sections: List.unmodifiable(sections),
    );
  }

  @override
  Future<int> getTotalPublishedChapterCount() async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(stable_id) AS cnt FROM chapters WHERE is_published = 1',
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<Map<String, Object?>?> _resolveChapterTranslation(
    Database db,
    String chapterStableId,
    String languageCode,
  ) async {
    final exact = await db.query(
      'chapter_translations',
      where: 'chapter_stable_id = ? AND language_code = ?',
      whereArgs: [chapterStableId, languageCode],
      limit: 1,
    );
    if (exact.isNotEmpty) return exact.first;
    if (languageCode == AppConstants.defaultLanguageCode) return null;

    final fallback = await db.query(
      'chapter_translations',
      where: 'chapter_stable_id = ? AND language_code = ?',
      whereArgs: [chapterStableId, AppConstants.defaultLanguageCode],
      limit: 1,
    );
    return fallback.isNotEmpty ? fallback.first : null;
  }

  Future<Map<String, String>> _loadSectionTitleMap(
    Database db,
    List<String> sectionIds,
    String languageCode,
  ) async {
    if (sectionIds.isEmpty) return const {};
    final result = <String, String>{};
    const chunkSize = 400;
    for (var i = 0; i < sectionIds.length; i += chunkSize) {
      final end = (i + chunkSize < sectionIds.length) ? i + chunkSize : sectionIds.length;
      final chunk = sectionIds.sublist(i, end);
      final ph = AppDatabase.placeholders(chunk.length);
      final rows = await db.query(
        'section_translations',
        where: 'section_stable_id IN ($ph) AND language_code = ?',
        whereArgs: [...chunk, languageCode],
      );
      final fallbackRows = languageCode == AppConstants.defaultLanguageCode
          ? rows
          : await db.query(
              'section_translations',
              where: 'section_stable_id IN ($ph) AND language_code = ?',
              whereArgs: [...chunk, AppConstants.defaultLanguageCode],
            );
      for (final r in fallbackRows) {
        result[AppDatabase.readString(r['section_stable_id'])] =
            AppDatabase.readString(r['title']);
      }
      for (final r in rows) {
        result[AppDatabase.readString(r['section_stable_id'])] =
            AppDatabase.readString(r['title']);
      }
    }
    return result;
  }

  Future<Map<String, String>> _loadParagraphTextMap(
    Database db,
    List<String> paragraphIds,
    String languageCode,
  ) async {
    if (paragraphIds.isEmpty) return const {};
    final result = <String, String>{};
    const chunkSize = 400;
    for (var i = 0; i < paragraphIds.length; i += chunkSize) {
      final end = (i + chunkSize < paragraphIds.length) ? i + chunkSize : paragraphIds.length;
      final chunk = paragraphIds.sublist(i, end);
      final ph = AppDatabase.placeholders(chunk.length);
      final rows = await db.query(
        'paragraph_translations',
        where: 'paragraph_stable_id IN ($ph) AND language_code = ?',
        whereArgs: [...chunk, languageCode],
      );
      final fallbackRows = languageCode == AppConstants.defaultLanguageCode
          ? rows
          : await db.query(
              'paragraph_translations',
              where: 'paragraph_stable_id IN ($ph) AND language_code = ?',
              whereArgs: [...chunk, AppConstants.defaultLanguageCode],
            );
      for (final r in fallbackRows) {
        result[AppDatabase.readString(r['paragraph_stable_id'])] =
            AppDatabase.readString(r['plain_text']);
      }
      for (final r in rows) {
        result[AppDatabase.readString(r['paragraph_stable_id'])] =
            AppDatabase.readString(r['plain_text']);
      }
    }
    return result;
  }

  Future<Map<String, Map<String, Object?>>> _loadClaimTranslationMap(
    Database db,
    List<String> claimIds,
    String languageCode,
  ) async {
    if (claimIds.isEmpty) return const {};
    final result = <String, Map<String, Object?>>{};
    const chunkSize = 400;
    for (var i = 0; i < claimIds.length; i += chunkSize) {
      final end = (i + chunkSize < claimIds.length) ? i + chunkSize : claimIds.length;
      final chunk = claimIds.sublist(i, end);
      final ph = AppDatabase.placeholders(chunk.length);
      final rows = await db.query(
        'historical_claim_translations',
        where: 'claim_stable_id IN ($ph) AND language_code = ?',
        whereArgs: [...chunk, languageCode],
      );
      final fallbackRows = languageCode == AppConstants.defaultLanguageCode
          ? rows
          : await db.query(
              'historical_claim_translations',
              where: 'claim_stable_id IN ($ph) AND language_code = ?',
              whereArgs: [...chunk, AppConstants.defaultLanguageCode],
            );
      for (final r in fallbackRows) {
        result[AppDatabase.readString(r['claim_stable_id'])] = r;
      }
      for (final r in rows) {
        result[AppDatabase.readString(r['claim_stable_id'])] = r;
      }
    }
    return result;
  }
}
