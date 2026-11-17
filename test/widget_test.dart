import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seerat_un_nabi/app.dart';
import 'package:seerat_un_nabi/core/database/database_provider.dart';

import 'helpers/test_database.dart';

void main() {
  testWidgets('SeeratUnNabiApp renders Urdu RTL home and navigates to Chapter 1',
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

    expect(find.text('سیرت النبی ﷺ'), findsOneWidget);
    expect(find.text('آپ یہاں مطالعہ چھوڑ کر گئے تھے۔'), findsOneWidget);

    final directionality = tester.widget<Directionality>(
      find.byType(Directionality).first,
    );
    expect(directionality.textDirection, TextDirection.rtl);

    await tester.tap(find.text('مطالعہ جاری رکھیں'));
    await tester.pumpAndSettle();

    expect(find.text('باب اول'), findsOneWidget);
    expect(find.text('1۔ جزیرۂ عرب کا معاشرتی اور دینی ماحول'), findsOneWidget);
  });
}
