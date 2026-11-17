import 'package:seerat_un_nabi/core/database/app_database.dart';
import 'package:seerat_un_nabi/features/personal_notes/domain/personal_note_model.dart';

abstract interface class PersonalNoteRepository {
  Future<List<PersonalNoteModel>> getNotesForChapter(String chapterStableId);

  Future<List<PersonalNoteModel>> getAllNotes();

  Future<int> createNote({
    required String chapterStableId,
    String? paragraphStableId,
    String? claimStableId,
    required String noteText,
  });

  Future<void> updateNote({
    required int id,
    required String noteText,
  });

  Future<void> deleteNote(int id);
}

final class SqlitePersonalNoteRepository implements PersonalNoteRepository {
  SqlitePersonalNoteRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<PersonalNoteModel>> getNotesForChapter(
    String chapterStableId,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      'personal_notes',
      where: 'chapter_stable_id = ?',
      whereArgs: [chapterStableId],
      orderBy: 'updated_at DESC',
    );
    return rows.map(_map).toList(growable: false);
  }

  @override
  Future<List<PersonalNoteModel>> getAllNotes() async {
    final db = await _db.database;
    final rows = await db.query(
      'personal_notes',
      orderBy: 'updated_at DESC',
    );
    return rows.map(_map).toList(growable: false);
  }

  @override
  Future<int> createNote({
    required String chapterStableId,
    String? paragraphStableId,
    String? claimStableId,
    required String noteText,
  }) async {
    final db = await _db.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return db.insert('personal_notes', {
      'chapter_stable_id': chapterStableId,
      'paragraph_stable_id': paragraphStableId,
      'claim_stable_id': claimStableId,
      'note_text': noteText,
      'created_at': nowMs,
      'updated_at': nowMs,
    });
  }

  @override
  Future<void> updateNote({
    required int id,
    required String noteText,
  }) async {
    final db = await _db.database;
    await db.update(
      'personal_notes',
      {
        'note_text': noteText,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteNote(int id) async {
    final db = await _db.database;
    await db.delete(
      'personal_notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  PersonalNoteModel _map(Map<String, Object?> r) {
    return PersonalNoteModel(
      id: AppDatabase.readInt(r['id']),
      chapterStableId: AppDatabase.readString(r['chapter_stable_id']),
      paragraphStableId:
          AppDatabase.readNullableString(r['paragraph_stable_id']),
      claimStableId: AppDatabase.readNullableString(r['claim_stable_id']),
      noteText: AppDatabase.readString(r['note_text']),
      createdAt: AppDatabase.readDateTime(r['created_at']),
      updatedAt: AppDatabase.readDateTime(r['updated_at']),
    );
  }
}
