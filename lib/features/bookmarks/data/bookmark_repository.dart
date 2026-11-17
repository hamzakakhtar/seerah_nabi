import 'package:seerat_un_nabi/core/database/app_database.dart';
import 'package:seerat_un_nabi/features/bookmarks/domain/bookmark_model.dart';

abstract interface class BookmarkRepository {
  Future<List<BookmarkModel>> getAllBookmarks();

  Future<bool> isChapterBookmarked(String chapterStableId);

  Future<int> addBookmark({
    required String chapterStableId,
    String? sectionStableId,
    String? paragraphStableId,
    required String titleUrdu,
  });

  Future<void> removeBookmarkById(int id);

  Future<void> removeBookmarksForChapter(String chapterStableId);
}

final class SqliteBookmarkRepository implements BookmarkRepository {
  SqliteBookmarkRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<BookmarkModel>> getAllBookmarks() async {
    final db = await _db.database;
    final rows = await db.query(
      'bookmarks',
      orderBy: 'created_at DESC',
    );
    return rows
        .map(
          (r) => BookmarkModel(
            id: AppDatabase.readInt(r['id']),
            chapterStableId: AppDatabase.readString(r['chapter_stable_id']),
            sectionStableId:
                AppDatabase.readNullableString(r['section_stable_id']),
            paragraphStableId:
                AppDatabase.readNullableString(r['paragraph_stable_id']),
            titleUrdu: AppDatabase.readString(r['title_urdu']),
            createdAt: AppDatabase.readDateTime(r['created_at']),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<bool> isChapterBookmarked(String chapterStableId) async {
    final db = await _db.database;
    final rows = await db.query(
      'bookmarks',
      columns: ['id'],
      where: 'chapter_stable_id = ?',
      whereArgs: [chapterStableId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  @override
  Future<int> addBookmark({
    required String chapterStableId,
    String? sectionStableId,
    String? paragraphStableId,
    required String titleUrdu,
  }) async {
    final db = await _db.database;
    return db.insert('bookmarks', {
      'chapter_stable_id': chapterStableId,
      'section_stable_id': sectionStableId,
      'paragraph_stable_id': paragraphStableId,
      'title_urdu': titleUrdu,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> removeBookmarkById(int id) async {
    final db = await _db.database;
    await db.delete(
      'bookmarks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> removeBookmarksForChapter(String chapterStableId) async {
    final db = await _db.database;
    await db.delete(
      'bookmarks',
      where: 'chapter_stable_id = ?',
      whereArgs: [chapterStableId],
    );
  }
}
