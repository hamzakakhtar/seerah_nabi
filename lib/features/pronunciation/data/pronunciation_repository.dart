import 'package:seerat_un_nabi/core/database/app_database.dart';
import 'package:seerat_un_nabi/features/pronunciation/domain/pronunciation_entry_model.dart';

abstract interface class PronunciationRepository {
  Future<List<PronunciationEntryModel>> getPronunciationEntries({
    String? searchQuery,
  });
}

final class SqlitePronunciationRepository implements PronunciationRepository {
  SqlitePronunciationRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<PronunciationEntryModel>> getPronunciationEntries({
    String? searchQuery,
  }) async {
    final db = await _db.database;
    String? where;
    List<Object?>? whereArgs;

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = '%${searchQuery.trim()}%';
      where =
          'term_urdu LIKE ? OR term_arabic LIKE ? OR transliteration LIKE ?';
      whereArgs = [term, term, term];
    }

    final rows = await db.query(
      'pronunciation_entries',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'term_urdu ASC',
    );
    return rows
        .map(
          (r) => PronunciationEntryModel(
            stableId: AppDatabase.readString(r['stable_id']),
            termArabic: AppDatabase.readString(r['term_arabic']),
            termUrdu: AppDatabase.readString(r['term_urdu']),
            transliteration: AppDatabase.readString(r['transliteration']),
            phoneticGuide: AppDatabase.readString(r['phonetic_guide']),
            urduExplanation: AppDatabase.readString(r['urdu_explanation']),
          ),
        )
        .toList(growable: false);
  }
}
