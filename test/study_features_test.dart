import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seerat_un_nabi/app.dart';
import 'package:seerat_un_nabi/core/database/database_provider.dart';
import 'package:seerat_un_nabi/core/database/seed/seerah_database_seeder.dart';
import 'package:seerat_un_nabi/features/bookmarks/data/bookmark_repository.dart';
import 'package:seerat_un_nabi/features/personal_notes/data/personal_note_repository.dart';
import 'package:seerat_un_nabi/features/reading_progress/data/reading_progress_repository.dart';

import 'helpers/test_database.dart';

void main() {
  test('Smart reading progress, session logs, bookmarks, and notes persist',
      () async {
    final db = createTestDatabase();
    addTearDown(db.close);

    await SeerahDatabaseSeeder(db).seedInitialContentIfEmpty();

    final progressRepo = SqliteReadingProgressRepository(db);
    await progressRepo.saveProgress(
      chapterStableId: 'chapter_002',
      sectionStableId: 'ch2_sec_01',
      paragraphStableId: 'ch2_p_01',
      scrollOffset: 245.0,
      completionFraction: 0.42,
    );

    final sessionId = await progressRepo.startReadingSession('chapter_002');
    await progressRepo.endReadingSession(
      sessionId: sessionId,
      durationSeconds: 180,
      paragraphsRead: 3,
    );

    final allProgress = await progressRepo.getAllChapterProgress();
    expect(allProgress, hasLength(1));
    expect(allProgress.first.sectionStableId, 'ch2_sec_01');

    final sessions = await progressRepo.getRecentSessions();
    expect(sessions, hasLength(1));
    expect(sessions.first.durationSeconds, 180);

    final noteRepo = SqlitePersonalNoteRepository(db);
    final noteId = await noteRepo.createNote(
      chapterStableId: 'chapter_002',
      paragraphStableId: 'ch2_p_01',
      claimStableId: 'ch2_c_01',
      noteText: 'پیر کے دن ولادت صحیح مسلم سے ثابت ہے۔',
    );
    await noteRepo.updateNote(
      id: noteId,
      noteText: 'پیر کے دن ولادت صحیح مسلم کی مرفوع حدیث سے ثابت ہے۔',
    );
    final notes = await noteRepo.getAllNotes();
    expect(notes, hasLength(1));
    expect(notes.first.claimStableId, 'ch2_c_01');

    final bookmarkRepo = SqliteBookmarkRepository(db);
    await bookmarkRepo.addBookmark(
      chapterStableId: 'chapter_002',
      titleUrdu: 'باب دوم',
    );
    expect(await bookmarkRepo.getAllBookmarks(), hasLength(1));
  });

  testWidgets('Bookmarks screen renders saved SQLite bookmark', (tester) async {
    final testDb = createTestDatabase();
    addTearDown(testDb.close);

    await SeerahDatabaseSeeder(testDb).seedInitialContentIfEmpty();
    await SqliteBookmarkRepository(testDb).addBookmark(
      chapterStableId: 'chapter_001',
      titleUrdu: 'باب اول: بعثتِ نبوی ﷺ سے قبل جزیرۂ عرب',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
        ],
        child: const SeeratUnNabiApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('نشانِ مطالعہ'), 200);
    await tester.tap(find.text('نشانِ مطالعہ'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
  });
}
