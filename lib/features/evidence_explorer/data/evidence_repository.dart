import 'package:seerat_un_nabi/core/constants/app_constants.dart';
import 'package:seerat_un_nabi/core/database/app_database.dart';
import 'package:seerat_un_nabi/features/evidence_explorer/domain/evidence_models.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/domain/chapter_models.dart';
import 'package:seerat_un_nabi/shared/models/reliability_status.dart';
import 'package:sqflite/sqflite.dart';

/// Repository contract for querying claim evidence, primary sources, narrations,
/// and narrator chains.
abstract interface class EvidenceRepository {
  Future<List<HistoricalClaimModel>> getClaims({
    ReliabilityStatus? statusFilter,
    String? chapterStableId,
    String languageCode = AppConstants.defaultLanguageCode,
  });

  Future<HistoricalClaimModel?> getClaimById(
    String claimStableId, {
    String languageCode = AppConstants.defaultLanguageCode,
  });

  Future<List<ClaimEvidenceModel>> getEvidenceForClaim(String claimStableId);

  Future<List<NarrationModel>> getAllNarrations({SourceTradition? tradition});

  Future<List<NarrationModel>> getNarrationsForSource(String sourceStableId);

  Future<List<SourceModel>> getAllSources();

  Future<List<SourceReferenceModel>> getReferencesForSource(
    String sourceStableId,
  );
}

/// Offline-first SQLite (`sqflite`) implementation of [EvidenceRepository].
final class SqliteEvidenceRepository implements EvidenceRepository {
  SqliteEvidenceRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<HistoricalClaimModel>> getClaims({
    ReliabilityStatus? statusFilter,
    String? chapterStableId,
    String languageCode = AppConstants.defaultLanguageCode,
  }) async {
    final db = await _db.database;
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    if (statusFilter != null) {
      whereClauses.add('reliability_status = ?');
      whereArgs.add(statusFilter.storageValue);
    }
    if (chapterStableId != null) {
      whereClauses.add('chapter_stable_id = ?');
      whereArgs.add(chapterStableId);
    }

    final rows = await db.query(
      'historical_claims',
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'chapter_stable_id ASC, order_in_paragraph ASC',
    );
    if (rows.isEmpty) return const <HistoricalClaimModel>[];

    final claimIds = rows
        .map((r) => AppDatabase.readString(r['stable_id']))
        .toList(growable: false);
    final ph = AppDatabase.placeholders(claimIds.length);
    final translations = await db.query(
      'historical_claim_translations',
      where: 'claim_stable_id IN ($ph) AND language_code = ?',
      whereArgs: [...claimIds, languageCode],
    );
    final fallbackTranslations =
        languageCode == AppConstants.defaultLanguageCode
            ? translations
            : await db.query(
                'historical_claim_translations',
                where: 'claim_stable_id IN ($ph) AND language_code = ?',
                whereArgs: [...claimIds, AppConstants.defaultLanguageCode],
              );

    final trMap = <String, Map<String, Object?>>{
      for (final tr in fallbackTranslations)
        AppDatabase.readString(tr['claim_stable_id']): tr,
      for (final tr in translations)
        AppDatabase.readString(tr['claim_stable_id']): tr,
    };

    return rows.map((c) {
      final stableId = AppDatabase.readString(c['stable_id']);
      final tr = trMap[stableId];
      return HistoricalClaimModel(
        stableId: stableId,
        paragraphStableId: AppDatabase.readString(c['paragraph_stable_id']),
        chapterStableId: AppDatabase.readString(c['chapter_stable_id']),
        orderInParagraph: AppDatabase.readInt(c['order_in_paragraph']),
        reliabilityStatus: ReliabilityStatus.fromStorage(
          AppDatabase.readString(c['reliability_status']),
        ),
        claimText: tr != null ? AppDatabase.readString(tr['claim_text']) : '',
        classificationReason:
            AppDatabase.readString(c['classification_reason']),
        scholarlyAssessment: AppDatabase.readString(c['scholarly_assessment']),
        isChronologicallyVerified: AppDatabase.readBool(
          c['is_chronologically_verified'],
        ),
        explanationNote:
            tr != null ? AppDatabase.readString(tr['explanation_note']) : '',
        researchVersionId: AppDatabase.readNullableInt(
          c['research_version_id'],
        ),
      );
    }).toList(growable: false);
  }

  @override
  Future<HistoricalClaimModel?> getClaimById(
    String claimStableId, {
    String languageCode = AppConstants.defaultLanguageCode,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      'historical_claims',
      where: 'stable_id = ?',
      whereArgs: [claimStableId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final c = rows.first;

    var trRows = await db.query(
      'historical_claim_translations',
      where: 'claim_stable_id = ? AND language_code = ?',
      whereArgs: [claimStableId, languageCode],
      limit: 1,
    );
    if (trRows.isEmpty && languageCode != AppConstants.defaultLanguageCode) {
      trRows = await db.query(
        'historical_claim_translations',
        where: 'claim_stable_id = ? AND language_code = ?',
        whereArgs: [claimStableId, AppConstants.defaultLanguageCode],
        limit: 1,
      );
    }
    final tr = trRows.isNotEmpty ? trRows.first : null;

    return HistoricalClaimModel(
      stableId: AppDatabase.readString(c['stable_id']),
      paragraphStableId: AppDatabase.readString(c['paragraph_stable_id']),
      chapterStableId: AppDatabase.readString(c['chapter_stable_id']),
      orderInParagraph: AppDatabase.readInt(c['order_in_paragraph']),
      reliabilityStatus: ReliabilityStatus.fromStorage(
        AppDatabase.readString(c['reliability_status']),
      ),
      claimText: tr != null ? AppDatabase.readString(tr['claim_text']) : '',
      classificationReason: AppDatabase.readString(c['classification_reason']),
      scholarlyAssessment: AppDatabase.readString(c['scholarly_assessment']),
      isChronologicallyVerified: AppDatabase.readBool(
        c['is_chronologically_verified'],
      ),
      explanationNote:
          tr != null ? AppDatabase.readString(tr['explanation_note']) : '',
      researchVersionId: AppDatabase.readNullableInt(c['research_version_id']),
    );
  }

  @override
  Future<List<SourceReferenceModel>> getReferencesForSource(
    String sourceStableId,
  ) async {
    final db = await _db.database;
    final sourceRows = await db.query(
      'sources',
      where: 'stable_id = ?',
      whereArgs: [sourceStableId],
      limit: 1,
    );
    if (sourceRows.isEmpty) return const <SourceReferenceModel>[];

    final sourceModel = _mapSource(sourceRows.first);
    final refRows = await db.query(
      'source_references',
      where: 'source_stable_id = ?',
      whereArgs: [sourceStableId],
    );

    return refRows
        .map(
          (r) => SourceReferenceModel(
            stableId: AppDatabase.readString(r['stable_id']),
            source: sourceModel,
            volume: AppDatabase.readString(r['volume']),
            pageNumber: AppDatabase.readString(r['page_number']),
            sectionOrHadithNumber: AppDatabase.readString(
              r['section_or_hadith_number'],
            ),
            originalArabicExcerpt: AppDatabase.readString(
              r['original_arabic_excerpt'],
            ),
            urduTranslation: AppDatabase.readString(r['urdu_translation']),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<ClaimEvidenceModel>> getEvidenceForClaim(
    String claimStableId,
  ) async {
    final db = await _db.database;
    final evidenceRows = await db.query(
      'claim_evidence',
      where: 'claim_stable_id = ?',
      whereArgs: [claimStableId],
    );
    if (evidenceRows.isEmpty) {
      return const <ClaimEvidenceModel>[];
    }

    final results = <ClaimEvidenceModel>[];
    for (final ev in evidenceRows) {
      final refModel = await _loadSourceReference(
        db,
        AppDatabase.readString(ev['source_reference_stable_id']),
      );
      if (refModel == null) continue;

      final narrationStableId =
          AppDatabase.readNullableString(ev['narration_stable_id']);
      NarrationModel? narrationModel;
      if (narrationStableId != null) {
        narrationModel = await _loadNarration(db, narrationStableId);
      }

      results.add(
        ClaimEvidenceModel(
          id: AppDatabase.readInt(ev['id']),
          claimStableId: AppDatabase.readString(ev['claim_stable_id']),
          reference: refModel,
          evidenceRole: EvidenceRole.fromStorage(
            AppDatabase.readString(ev['evidence_role']),
          ),
          notesUrdu: AppDatabase.readString(ev['notes_urdu']),
          narration: narrationModel,
        ),
      );
    }

    return List.unmodifiable(results);
  }

  @override
  Future<List<NarrationModel>> getAllNarrations({
    SourceTradition? tradition,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      'narrations',
      where: tradition != null ? 'tradition = ?' : null,
      whereArgs: tradition != null ? [tradition.storageValue] : null,
    );
    final models = <NarrationModel>[];
    for (final n in rows) {
      final model =
          await _loadNarration(db, AppDatabase.readString(n['stable_id']));
      if (model != null) models.add(model);
    }
    return List.unmodifiable(models);
  }

  @override
  Future<List<NarrationModel>> getNarrationsForSource(
    String sourceStableId,
  ) async {
    final db = await _db.database;
    final refRows = await db.query(
      'source_references',
      where: 'source_stable_id = ?',
      whereArgs: [sourceStableId],
    );
    if (refRows.isEmpty) return const <NarrationModel>[];

    final refIds = refRows
        .map((r) => AppDatabase.readString(r['stable_id']))
        .toList(growable: false);
    final ph = AppDatabase.placeholders(refIds.length);
    final narrationRows = await db.query(
      'narrations',
      where: 'source_reference_stable_id IN ($ph)',
      whereArgs: refIds,
    );

    final models = <NarrationModel>[];
    for (final n in narrationRows) {
      final model =
          await _loadNarration(db, AppDatabase.readString(n['stable_id']));
      if (model != null) models.add(model);
    }
    return List.unmodifiable(models);
  }

  @override
  Future<List<SourceModel>> getAllSources() async {
    final db = await _db.database;
    final rows = await db.query(
      'sources',
      orderBy: 'author_death_hijri ASC',
    );
    return rows.map(_mapSource).toList(growable: false);
  }

  Future<SourceReferenceModel?> _loadSourceReference(
    Database db,
    String refStableId,
  ) async {
    final refRows = await db.query(
      'source_references',
      where: 'stable_id = ?',
      whereArgs: [refStableId],
      limit: 1,
    );
    if (refRows.isEmpty) return null;
    final refRow = refRows.first;

    final sourceRows = await db.query(
      'sources',
      where: 'stable_id = ?',
      whereArgs: [AppDatabase.readString(refRow['source_stable_id'])],
      limit: 1,
    );
    if (sourceRows.isEmpty) return null;

    return SourceReferenceModel(
      stableId: AppDatabase.readString(refRow['stable_id']),
      source: _mapSource(sourceRows.first),
      volume: AppDatabase.readString(refRow['volume']),
      pageNumber: AppDatabase.readString(refRow['page_number']),
      sectionOrHadithNumber: AppDatabase.readString(
        refRow['section_or_hadith_number'],
      ),
      originalArabicExcerpt: AppDatabase.readString(
        refRow['original_arabic_excerpt'],
      ),
      urduTranslation: AppDatabase.readString(refRow['urdu_translation']),
    );
  }

  Future<NarrationModel?> _loadNarration(
    Database db,
    String narrationStableId,
  ) async {
    final nRows = await db.query(
      'narrations',
      where: 'stable_id = ?',
      whereArgs: [narrationStableId],
      limit: 1,
    );
    if (nRows.isEmpty) return null;
    final nRow = nRows.first;

    final refModel = await _loadSourceReference(
      db,
      AppDatabase.readString(nRow['source_reference_stable_id']),
    );
    if (refModel == null) return null;

    final chainLinks = await db.query(
      'narration_narrators',
      where: 'narration_stable_id = ?',
      whereArgs: [narrationStableId],
      orderBy: 'chain_position ASC',
    );

    final narrators = <NarratorModel>[];
    if (chainLinks.isNotEmpty) {
      final narratorIds = chainLinks
          .map((c) => AppDatabase.readString(c['narrator_stable_id']))
          .toList(growable: false);
      final ph = AppDatabase.placeholders(narratorIds.length);
      final narratorRows = await db.query(
        'narrators',
        where: 'stable_id IN ($ph)',
        whereArgs: narratorIds,
      );
      final byId = <String, Map<String, Object?>>{
        for (final r in narratorRows) AppDatabase.readString(r['stable_id']): r,
      };
      for (final link in chainLinks) {
        final r = byId[AppDatabase.readString(link['narrator_stable_id'])];
        if (r != null) {
          narrators.add(
            NarratorModel(
              stableId: AppDatabase.readString(r['stable_id']),
              nameArabic: AppDatabase.readString(r['name_arabic']),
              nameUrdu: AppDatabase.readString(r['name_urdu']),
              deathHijri: AppDatabase.readNullableInt(r['death_hijri']),
              scholarlyGrading: AppDatabase.readString(r['scholarly_grading']),
              biographicalNote: AppDatabase.readString(r['biographical_note']),
            ),
          );
        }
      }
    }

    return NarrationModel(
      stableId: AppDatabase.readString(nRow['stable_id']),
      reference: refModel,
      matnArabic: AppDatabase.readString(nRow['matn_arabic']),
      urduSummary: AppDatabase.readString(nRow['urdu_summary']),
      isnadChainSummary: AppDatabase.readString(nRow['isnad_chain_summary']),
      hadithGrade: AppDatabase.readString(nRow['hadith_grade']),
      historicalWeightNote:
          AppDatabase.readString(nRow['historical_weight_note']),
      tradition: SourceTradition.fromStorage(
        AppDatabase.readString(nRow['tradition']),
      ),
      narrators: List.unmodifiable(narrators),
    );
  }

  SourceModel _mapSource(Map<String, Object?> row) {
    return SourceModel(
      stableId: AppDatabase.readString(row['stable_id']),
      titleArabic: AppDatabase.readString(row['title_arabic']),
      titleUrdu: AppDatabase.readString(row['title_urdu']),
      authorArabic: AppDatabase.readString(row['author_arabic']),
      authorUrdu: AppDatabase.readString(row['author_urdu']),
      tradition: SourceTradition.fromStorage(
        AppDatabase.readString(row['tradition']),
      ),
      authorDeathHijri: AppDatabase.readNullableInt(row['author_death_hijri']),
      sourceType: AppDatabase.readString(row['source_type']),
    );
  }
}
