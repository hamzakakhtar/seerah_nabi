import 'package:seerat_un_nabi/core/database/app_database.dart';
import 'package:seerat_un_nabi/features/research_history/domain/research_version_model.dart';
import 'package:seerat_un_nabi/features/scholar_review/domain/scholar_review_model.dart';

abstract interface class ResearchGovernanceRepository {
  Future<List<ResearchVersionModel>> getResearchHistory({
    String? chapterStableId,
  });

  Future<List<ScholarReviewModel>> getScholarReviewsForChapter(
    String chapterStableId,
  );
}

final class SqliteResearchGovernanceRepository
    implements ResearchGovernanceRepository {
  SqliteResearchGovernanceRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<ResearchVersionModel>> getResearchHistory({
    String? chapterStableId,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      'research_versions',
      where: chapterStableId != null ? 'chapter_stable_id = ?' : null,
      whereArgs: chapterStableId != null ? [chapterStableId] : null,
      orderBy: 'created_at DESC, id DESC',
    );
    return rows
        .map(
          (r) => ResearchVersionModel(
            id: AppDatabase.readInt(r['id']),
            versionTag: AppDatabase.readString(r['version_tag']),
            chapterStableId:
                AppDatabase.readNullableString(r['chapter_stable_id']),
            changeSummaryUrdu:
                AppDatabase.readString(r['change_summary_urdu']),
            revisedBy: AppDatabase.readString(r['revised_by']),
            createdAt: AppDatabase.readDateTime(r['created_at']),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<ScholarReviewModel>> getScholarReviewsForChapter(
    String chapterStableId,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      'scholar_reviews',
      where: 'chapter_stable_id = ?',
      whereArgs: [chapterStableId],
      orderBy: 'reviewed_at DESC',
    );
    return rows
        .map(
          (r) => ScholarReviewModel(
            id: AppDatabase.readInt(r['id']),
            chapterStableId: AppDatabase.readString(r['chapter_stable_id']),
            reviewerName: AppDatabase.readString(r['reviewer_name']),
            credentials: AppDatabase.readString(r['credentials']),
            reviewStatus: ScholarReviewStatus.fromStorage(
              AppDatabase.readString(r['review_status']),
            ),
            notesUrdu: AppDatabase.readString(r['notes_urdu']),
            reviewedAt: AppDatabase.readDateTime(r['reviewed_at']),
          ),
        )
        .toList(growable: false);
  }
}
