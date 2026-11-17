import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seerat_un_nabi/app.dart';
import 'package:seerat_un_nabi/core/database/database_provider.dart';
import 'package:seerat_un_nabi/core/database/seed/seerah_database_seeder.dart';
import 'package:seerat_un_nabi/features/evidence_explorer/data/evidence_repository.dart';
import 'package:seerat_un_nabi/shared/models/reliability_status.dart';

import 'helpers/test_database.dart';

void main() {
  test('EvidenceRepository filters claims and hydrates narrations/narrators',
      () async {
    final db = createTestDatabase();
    addTearDown(db.close);

    await SeerahDatabaseSeeder(db).seedInitialContentIfEmpty();
    final repo = SqliteEvidenceRepository(db);

    final disputed =
        await repo.getClaims(statusFilter: ReliabilityStatus.disputed);
    expect(disputed, isNotEmpty);

    final ch2MondayEvidence = await repo.getEvidenceForClaim('ch2_c_01');
    expect(ch2MondayEvidence, isNotEmpty);
    expect(ch2MondayEvidence.first.narration, isNotNull);
    expect(ch2MondayEvidence.first.narration!.narrators, isNotEmpty);
    expect(
      ch2MondayEvidence.first.narration!.narrators.first.stableId,
      'nar_abu_qatadah',
    );

    final sources = await repo.getAllSources();
    expect(sources.length, greaterThanOrEqualTo(7));
  });

  testWidgets('Navigates from Home into Evidence Explorer and Arabic Sources',
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

    await tester.scrollUntilVisible(find.text('شواہد و اسناد'), 200);
    await tester.tap(find.text('شواہد و اسناد'));
    await tester.pumpAndSettle();

    expect(find.text('تمام دعوے'), findsOneWidget);
    expect(find.text('مختلف فیہ'), findsOneWidget);
  });
}
