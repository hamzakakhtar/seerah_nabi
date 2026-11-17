import 'package:flutter_test/flutter_test.dart';
import 'package:seerat_un_nabi/core/database/app_database.dart';
import 'package:seerat_un_nabi/core/database/seed/seerah_database_seeder.dart';
import 'package:seerat_un_nabi/features/bookmarks/data/bookmark_repository.dart';
import 'package:seerat_un_nabi/features/evidence_explorer/data/evidence_repository.dart';
import 'package:seerat_un_nabi/features/personal_notes/data/personal_note_repository.dart';
import 'package:seerat_un_nabi/features/reading_progress/data/reading_progress_repository.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/data/chapter_repository.dart';
import 'package:seerat_un_nabi/shared/models/reliability_status.dart';

import 'helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  test('seeds default languages and enforces foreign keys', () async {
    final sqldb = await db.database;
    final languages = await sqldb.query('languages');
    expect(
      languages.map((l) => l['code']),
      containsAll(['ur', 'ps', 'ar', 'en', 'fa']),
    );
  });

  test('SeerahDatabaseSeeder populates Chapters 1 to 16 idempotently',
      () async {
    final seeder = SeerahDatabaseSeeder(db);
    await seeder.seedInitialContentIfEmpty();
    await seeder.seedInitialContentIfEmpty();

    final chapterRepo = SqliteChapterRepository(db);
    final directory = await chapterRepo.getChapterDirectory();
    expect(directory, hasLength(16));

    final pashtoDirectory =
        await chapterRepo.getChapterDirectory(languageCode: 'ps');
    expect(pashtoDirectory, hasLength(16));
    expect(pashtoDirectory.first.titleUrdu, contains('لومړی باب'));

    final ch1PashtoFallback =
        await chapterRepo.getFullChapter('chapter_001', languageCode: 'ps');
    expect(ch1PashtoFallback, isNotNull);
    expect(ch1PashtoFallback!.titleUrdu, contains('لومړی باب'));
    expect(ch1PashtoFallback.sections, hasLength(5));

    final ch1 = await chapterRepo.getFullChapter('chapter_001');
    expect(ch1, isNotNull);
    expect(ch1!.sections, hasLength(5));
    expect(ch1.sections.first.paragraphs.first.claims, isNotEmpty);

    final ch2 = await chapterRepo.getFullChapter('chapter_002');
    expect(ch2, isNotNull);
    expect(ch2!.sections, hasLength(4));

    final ch3 = await chapterRepo.getFullChapter('chapter_003');
    expect(ch3, isNotNull);
    expect(ch3!.sections, hasLength(5));

    final ch4 = await chapterRepo.getFullChapter('chapter_004');
    expect(ch4, isNotNull);
    expect(ch4!.sections, hasLength(5));

    final ch5 = await chapterRepo.getFullChapter('chapter_005');
    expect(ch5, isNotNull);
    expect(ch5!.sections, hasLength(6));

    final ch6 = await chapterRepo.getFullChapter('chapter_006');
    expect(ch6, isNotNull);
    expect(ch6!.sections, hasLength(4));

    final ch7 = await chapterRepo.getFullChapter('chapter_007');
    expect(ch7, isNotNull);
    expect(ch7!.sections, hasLength(5));

    final ch8 = await chapterRepo.getFullChapter('chapter_008');
    expect(ch8, isNotNull);
    expect(ch8!.sections, hasLength(6));

    final ch9 = await chapterRepo.getFullChapter('chapter_009');
    expect(ch9, isNotNull);
    expect(ch9!.sections, hasLength(6));

    final ch10 = await chapterRepo.getFullChapter('chapter_010');
    expect(ch10, isNotNull);
    expect(ch10!.sections, hasLength(5));

    final ch11 = await chapterRepo.getFullChapter('chapter_011');
    expect(ch11, isNotNull);
    expect(ch11!.sections, hasLength(6));

    final ch12 = await chapterRepo.getFullChapter('chapter_012');
    expect(ch12, isNotNull);
    expect(ch12!.sections, hasLength(4));

    final ch13 = await chapterRepo.getFullChapter('chapter_013');
    expect(ch13, isNotNull);
    expect(ch13!.sections, hasLength(5));

    final ch14 = await chapterRepo.getFullChapter('chapter_014');
    expect(ch14, isNotNull);
    expect(ch14!.sections, hasLength(5));

    final ch15 = await chapterRepo.getFullChapter('chapter_015');
    expect(ch15, isNotNull);
    expect(ch15!.sections, hasLength(5));

    final ch16 = await chapterRepo.getFullChapter('chapter_016');
    expect(ch16, isNotNull);
    expect(ch16!.sections, hasLength(6));

    final sqldb = await db.database;
    final versions = await sqldb.query('research_versions');
    expect(
      versions.map((v) => v['version_tag']),
      contains('v2.0.0-encyclopedic-seerah'),
    );

    final disputedClaims = ch2.sections
        .expand((s) => s.paragraphs)
        .expand((p) => p.claims)
        .where((c) => c.reliabilityStatus == ReliabilityStatus.disputed)
        .toList();
    expect(disputedClaims, isNotEmpty);

    final ch7WeakClaims = ch7.sections
        .expand((s) => s.paragraphs)
        .expand((p) => p.claims)
        .where((c) => c.reliabilityStatus == ReliabilityStatus.weak)
        .toList();
    expect(ch7WeakClaims, isNotEmpty);

    final evidenceRepo = SqliteEvidenceRepository(db);
    final evidence = await evidenceRepo.getEvidenceForClaim('ch1_c_08');
    expect(evidence, isNotEmpty);
    expect(evidence.first.reference.source.stableId, 'src_quran');

    final ch4Evidence = await evidenceRepo.getEvidenceForClaim('ch4_c_02');
    expect(ch4Evidence, isNotEmpty);
    expect(ch4Evidence.first.reference.source.stableId, 'src_quran');

    final ch8Evidence = await evidenceRepo.getEvidenceForClaim('ch8_c_04');
    expect(ch8Evidence, isNotEmpty);
    expect(ch8Evidence.first.reference.source.stableId, 'src_quran');

    final ch12Evidence = await evidenceRepo.getEvidenceForClaim('ch12_c_01');
    expect(ch12Evidence, isNotEmpty);
    expect(ch12Evidence.first.reference.source.stableId, 'src_muslim');

    final ch13Evidence = await evidenceRepo.getEvidenceForClaim('ch13_c_03');
    expect(ch13Evidence, isNotEmpty);
    expect(ch13Evidence.first.reference.source.stableId, 'src_quran');
  });

  test('chapter, progress, bookmark, and note repositories roundtrip', () async {
    final sqldb = await db.database;
    await sqldb.insert('chapters', {
      'stable_id': 'chapter_test_001',
      'order_index': 1,
      'era_code': 'pre_prophethood',
      'route_key': '/chapters/chapter-one',
      'is_published': 1,
    });
    await sqldb.insert('chapter_translations', {
      'chapter_stable_id': 'chapter_test_001',
      'language_code': 'ur',
      'title': 'باب اول',
      'era_label': 'قبل از بعثت',
    });

    final chapterRepo = SqliteChapterRepository(db);
    final directory = await chapterRepo.getChapterDirectory();
    expect(directory, hasLength(1));
    expect(directory.first.stableId, 'chapter_test_001');

    final progressRepo = SqliteReadingProgressRepository(db);
    await progressRepo.saveProgress(
      chapterStableId: 'chapter_test_001',
      scrollOffset: 120.5,
      completionFraction: 0.35,
    );
    final active = await progressRepo.getLastActiveProgress();
    expect(active, isNotNull);
    expect(active!.completionFraction, closeTo(0.35, 0.001));

    final bookmarkRepo = SqliteBookmarkRepository(db);
    await bookmarkRepo.addBookmark(
      chapterStableId: 'chapter_test_001',
      titleUrdu: 'باب اول',
    );
    expect(await bookmarkRepo.isChapterBookmarked('chapter_test_001'), isTrue);

    final noteRepo = SqlitePersonalNoteRepository(db);
    await noteRepo.createNote(
      chapterStableId: 'chapter_test_001',
      noteText: 'Test study note',
    );
    final notes = await noteRepo.getNotesForChapter('chapter_test_001');
    expect(notes, hasLength(1));
  });
}
