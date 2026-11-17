import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seerat_un_nabi/app.dart';
import 'package:seerat_un_nabi/core/database/database_provider.dart';
import 'package:seerat_un_nabi/core/database/seed/seerah_database_seeder.dart';
import 'package:seerat_un_nabi/features/search/data/search_repository.dart';
import 'package:seerat_un_nabi/features/search/domain/search_models.dart';
import 'package:seerat_un_nabi/shared/models/reliability_status.dart';

import 'helpers/test_database.dart';

void main() {
  group('Offline SQLite Search', () {
    test('Matches unvoweled Urdu query against Arabic tashkeel and Seerah tables',
        () async {
      final db = createTestDatabase();
      addTearDown(db.close);

      await SeerahDatabaseSeeder(db).seedInitialContentIfEmpty();
      final repo = SqliteSearchRepository(db);

      final emptyResult = await repo.searchOffline(query: '   ');
      expect(emptyResult.items, isEmpty);

      final quraishBundle = await repo.searchOffline(query: 'قریش');
      expect(quraishBundle.items, isNotEmpty);
      expect(
        quraishBundle.countFor(SearchCategory.pronunciation),
        greaterThanOrEqualTo(1),
      );

      final abwaBundle = await repo.searchOffline(query: 'ابواء');
      expect(abwaBundle.items, isNotEmpty);
      expect(
        abwaBundle.items.any((item) => item.title.contains('الْأَبْوَاء')),
        isTrue,
      );

      final confirmedClaimsOnly = await repo.searchOffline(
        query: 'حلیمہ',
        category: SearchCategory.claims,
        reliabilityFilter: ReliabilityStatus.confirmed,
      );
      expect(
        confirmedClaimsOnly.items.every(
          (item) =>
              item.category == SearchCategory.claims &&
              item.reliabilityStatus == ReliabilityStatus.confirmed,
        ),
        isTrue,
      );

      final badrBundle = await repo.searchOffline(query: 'بدر');
      expect(badrBundle.items, isNotEmpty);
      expect(
        badrBundle.countFor(SearchCategory.chapters),
        greaterThanOrEqualTo(1),
      );
      expect(
        badrBundle.countFor(SearchCategory.locations),
        greaterThanOrEqualTo(1),
      );

      final hudaybiyyahBundle = await repo.searchOffline(query: 'حدیبیہ');
      expect(hudaybiyyahBundle.items, isNotEmpty);
      expect(
        hudaybiyyahBundle.countFor(SearchCategory.chapters),
        greaterThanOrEqualTo(1),
      );
      expect(
        hudaybiyyahBundle.countFor(SearchCategory.timeline),
        greaterThanOrEqualTo(1),
      );

      final shamailBundle = await repo.searchOffline(query: 'شمائل');
      expect(shamailBundle.items, isNotEmpty);
      expect(
        shamailBundle.countFor(SearchCategory.chapters),
        greaterThanOrEqualTo(1),
      );
      expect(
        shamailBundle.countFor(SearchCategory.pronunciation),
        greaterThanOrEqualTo(1),
      );
    });

    testWidgets('Navigates from Home AppBar search action and runs offline search',
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

      await tester.tap(find.byIcon(Icons.search_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('تحقیقی تلاش'), findsOneWidget);
      expect(find.text('مکمل آف لائن تحقیقی تلاش'), findsOneWidget);

      await tester.tap(find.text('قریش'));
      await tester.pumpAndSettle();

      expect(find.textContaining('نتائج موصول ہوئے'), findsOneWidget);
      expect(find.textContaining('قُرَيْش'), findsWidgets);
    });
  });
}
