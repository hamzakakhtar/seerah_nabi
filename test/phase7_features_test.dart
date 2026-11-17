import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seerat_un_nabi/app.dart';
import 'package:seerat_un_nabi/core/database/database_provider.dart';
import 'package:seerat_un_nabi/core/database/seed/seerah_database_seeder.dart';
import 'package:seerat_un_nabi/features/daily_seerah/data/daily_seerah_repository.dart';
import 'package:seerat_un_nabi/features/evidence_explorer/data/evidence_repository.dart';
import 'package:seerat_un_nabi/features/evidence_explorer/domain/evidence_models.dart';
import 'package:seerat_un_nabi/features/pronunciation/data/pronunciation_repository.dart';

import 'helpers/test_database.dart';

void main() {
  test('Narration comparison, pronunciation & daily Seerah SQLite tests',
      () async {
    final db = createTestDatabase();
    addTearDown(db.close);

    await SeerahDatabaseSeeder(db).seedInitialContentIfEmpty();

    final evidenceRepo = SqliteEvidenceRepository(db);
    final allNarrations = await evidenceRepo.getAllNarrations();
    expect(allNarrations.length, greaterThanOrEqualTo(4));

    final shiaNarrations =
        await evidenceRepo.getAllNarrations(tradition: SourceTradition.shia);
    expect(shiaNarrations, hasLength(1));

    final pronunciationRepo = SqlitePronunciationRepository(db);
    final entries = await pronunciationRepo.getPronunciationEntries();
    expect(entries.length, greaterThanOrEqualTo(35));

    final filtered =
        await pronunciationRepo.getPronunciationEntries(searchQuery: 'ابواء');
    expect(filtered, hasLength(1));

    final dailyRepo = SqliteDailySeerahRepository(db);
    final dailyEntries = await dailyRepo.getDailyEligibleEntries();
    expect(dailyEntries.length, greaterThanOrEqualTo(35));
  });

  testWidgets('Navigates from Home to Pronunciation Guide screen',
      (tester) async {
    final testDb = createTestDatabase();
    addTearDown(testDb.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
        ],
        child: const SeeratUnNabiApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('تلفظ رہنما'), 200);
    await tester.tap(find.text('تلفظ رہنما'));
    await tester.pumpAndSettle();

    expect(find.text('قُرَيْش'), findsOneWidget);
  });
}
