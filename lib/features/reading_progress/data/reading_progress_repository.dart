import 'package:seerat_un_nabi/core/database/app_database.dart';
import 'package:seerat_un_nabi/features/reading_progress/domain/reading_progress_models.dart';

/// Repository contract for Smart Reading Progress and reading session history.
abstract interface class ReadingProgressRepository {
  Future<ReadingProgressModel?> getLastActiveProgress();

  Future<List<ReadingProgressModel>> getAllChapterProgress();

  Future<ReadingProgressModel?> getChapterProgress(String chapterStableId);

  Future<void> saveProgress({
    required String chapterStableId,
    String? sectionStableId,
    String? paragraphStableId,
    required double scrollOffset,
    required double completionFraction,
  });

  Future<int> startReadingSession(String chapterStableId);

  Future<void> endReadingSession({
    required int sessionId,
    required int durationSeconds,
    required int paragraphsRead,
  });

  Future<List<ReadingSessionModel>> getRecentSessions({int limit = 20});
}

/// Offline-first SQLite (`sqflite`) implementation of [ReadingProgressRepository].
final class SqliteReadingProgressRepository
    implements ReadingProgressRepository {
  SqliteReadingProgressRepository(this._db);

  final AppDatabase _db;

  @override
  Future<ReadingProgressModel?> getLastActiveProgress() async {
    final db = await _db.database;
    final rows = await db.query(
      'reading_progress',
      where: 'is_last_active = 1',
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : _mapProgress(rows.first);
  }

  @override
  Future<List<ReadingProgressModel>> getAllChapterProgress() async {
    final db = await _db.database;
    final rows = await db.query(
      'reading_progress',
      orderBy: 'updated_at DESC',
    );
    return rows.map(_mapProgress).toList(growable: false);
  }

  @override
  Future<ReadingProgressModel?> getChapterProgress(
    String chapterStableId,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      'reading_progress',
      where: 'chapter_stable_id = ?',
      whereArgs: [chapterStableId],
      limit: 1,
    );
    return rows.isEmpty ? null : _mapProgress(rows.first);
  }

  @override
  Future<void> saveProgress({
    required String chapterStableId,
    String? sectionStableId,
    String? paragraphStableId,
    required double scrollOffset,
    required double completionFraction,
  }) async {
    final db = await _db.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final clampedFraction = completionFraction.clamp(0.0, 1.0);

    await db.transaction((txn) async {
      await txn.update('reading_progress', {'is_last_active': 0});

      final existing = await txn.query(
        'reading_progress',
        columns: ['id'],
        where: 'chapter_stable_id = ?',
        whereArgs: [chapterStableId],
        limit: 1,
      );

      final values = <String, Object?>{
        'section_stable_id': sectionStableId,
        'paragraph_stable_id': paragraphStableId,
        'scroll_offset': scrollOffset,
        'completion_fraction': clampedFraction,
        'is_last_active': 1,
        'updated_at': nowMs,
      };

      if (existing.isEmpty) {
        await txn.insert('reading_progress', {
          'chapter_stable_id': chapterStableId,
          ...values,
        });
      } else {
        await txn.update(
          'reading_progress',
          values,
          where: 'chapter_stable_id = ?',
          whereArgs: [chapterStableId],
        );
      }
    });
  }

  @override
  Future<int> startReadingSession(String chapterStableId) async {
    final db = await _db.database;
    return db.insert('reading_sessions', {
      'chapter_stable_id': chapterStableId,
      'started_at': DateTime.now().millisecondsSinceEpoch,
      'duration_seconds': 0,
      'paragraphs_read': 0,
    });
  }

  @override
  Future<void> endReadingSession({
    required int sessionId,
    required int durationSeconds,
    required int paragraphsRead,
  }) async {
    final db = await _db.database;
    await db.update(
      'reading_sessions',
      {
        'ended_at': DateTime.now().millisecondsSinceEpoch,
        'duration_seconds': durationSeconds,
        'paragraphs_read': paragraphsRead,
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  @override
  Future<List<ReadingSessionModel>> getRecentSessions({int limit = 20}) async {
    final db = await _db.database;
    final rows = await db.query(
      'reading_sessions',
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return rows
        .map(
          (r) => ReadingSessionModel(
            id: AppDatabase.readInt(r['id']),
            chapterStableId: AppDatabase.readString(r['chapter_stable_id']),
            startedAt: AppDatabase.readDateTime(r['started_at']),
            endedAt: AppDatabase.readNullableDateTime(r['ended_at']),
            durationSeconds: AppDatabase.readInt(r['duration_seconds']),
            paragraphsRead: AppDatabase.readInt(r['paragraphs_read']),
          ),
        )
        .toList(growable: false);
  }

  ReadingProgressModel _mapProgress(Map<String, Object?> row) {
    return ReadingProgressModel(
      chapterStableId: AppDatabase.readString(row['chapter_stable_id']),
      sectionStableId: AppDatabase.readNullableString(row['section_stable_id']),
      paragraphStableId:
          AppDatabase.readNullableString(row['paragraph_stable_id']),
      scrollOffset: AppDatabase.readDouble(row['scroll_offset']),
      completionFraction: AppDatabase.readDouble(row['completion_fraction']),
      isLastActive: AppDatabase.readBool(row['is_last_active']),
      updatedAt: AppDatabase.readDateTime(row['updated_at']),
    );
  }
}
