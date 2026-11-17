import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seerat_un_nabi/app.dart';
import 'package:seerat_un_nabi/core/database/database_provider.dart';
import 'package:seerat_un_nabi/core/database/seed/seerah_database_seeder.dart';
import 'package:seerat_un_nabi/features/historical_maps/data/historical_location_repository.dart';
import 'package:seerat_un_nabi/features/seerah_timeline/data/timeline_repository.dart';

import 'helpers/test_database.dart';

void main() {
  test('Timeline, historical locations, and cross-references hydrate from SQLite',
      () async {
    final db = createTestDatabase();
    addTearDown(db.close);

    await SeerahDatabaseSeeder(db).seedInitialContentIfEmpty();

    final timelineRepo = SqliteTimelineRepository(db);
    final events = await timelineRepo.getChronologicalEvents();
    expect(events.length, greaterThanOrEqualTo(30));

    final abwaEvents = await timelineRepo.getEventsForLocation('loc_abwa');
    expect(abwaEvents, hasLength(1));
    expect(abwaEvents.first.stableId, 'tl_005_abwa');

    final crossRefs =
        await timelineRepo.getCrossReferencesForEntity('tl_005_abwa');
    expect(crossRefs.length, greaterThanOrEqualTo(2));

    final locationRepo = SqliteHistoricalLocationRepository(db);
    final locations = await locationRepo.getAllLocations();
    expect(locations.length, greaterThanOrEqualTo(16));
  });

  testWidgets('Navigates from Home to Timeline and Historical Maps',
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

    await tester.scrollUntilVisible(find.text('زمانی خطِ سیر'), 200);
    await tester.tap(find.text('زمانی خطِ سیر'));
    await tester.pumpAndSettle();

    expect(find.text('مکہ مکرمہ میں ولادتِ باسعادت ﷺ'), findsOneWidget);

    await tester.tap(find.text('ابواء').first);
    await tester.pumpAndSettle();

    expect(find.text('تاریخی نقشے'), findsOneWidget);
    expect(find.text('اس مقام سے وابستہ تاریخی واقعات'), findsOneWidget);
  });
}
