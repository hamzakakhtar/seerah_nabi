import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seerat_un_nabi/app.dart';
import 'package:seerat_un_nabi/core/database/database_provider.dart';
import 'package:seerat_un_nabi/core/database/seed/seerah_database_seeder.dart';
import 'package:seerat_un_nabi/features/research_history/data/research_governance_repository.dart';

import 'helpers/test_database.dart';

void main() {
  test('ResearchGovernanceRepository returns seeded versions newest-first',
      () async {
    final db = createTestDatabase();
    addTearDown(db.close);

    final seeder = SeerahDatabaseSeeder(db);
    await seeder.seedInitialContentIfEmpty();
    await seeder.seedInitialContentIfEmpty();

    final repo = SqliteResearchGovernanceRepository(db);
    final allVersions = await repo.getResearchHistory();

    expect(allVersions.length, greaterThanOrEqualTo(6));
    expect(allVersions.first.versionTag, 'v1.4.1-search-and-chronology');
    expect(allVersions.last.versionTag, 'v1.0.0-phase3');

    final ch1Versions =
        await repo.getResearchHistory(chapterStableId: 'chapter_001');
    expect(ch1Versions, hasLength(1));
    expect(ch1Versions.first.versionTag, 'v1.0.0-phase3');
  });

  testWidgets('Navigates from Home to Research History and filters revisions',
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

    await tester.scrollUntilVisible(find.text('تاریخِ تحقیق'), 200);
    await tester.tap(find.text('تاریخِ تحقیق'));
    await tester.pumpAndSettle();

    expect(find.text('v1.4.1-search-and-chronology'), findsOneWidget);
    expect(find.text('تازہ ترین اشاعت'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('v1.0.0-phase3'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('v1.0.0-phase3'), findsOneWidget);

    await tester.tap(find.text('عمومی ترامیم'));
    await tester.pumpAndSettle();

    expect(find.text('v1.4.1-search-and-chronology'), findsOneWidget);
    expect(find.text('v1.0.0-phase3'), findsNothing);
  });
}
