import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/features/daily_seerah/data/daily_seerah_repository.dart';
import 'package:seerat_un_nabi/shared/models/reading_settings.dart';
import 'package:seerat_un_nabi/shared/providers/reading_settings_provider.dart';
import 'package:seerat_un_nabi/shared/providers/repository_providers.dart';

final dailySeerahEntriesProvider =
    FutureProvider<List<DailySeerahEntry>>((ref) async {
  await ref.watch(databaseInitializerProvider.future);
  final languageCode = ref.watch(
    readingSettingsProvider.select(
      (ReadingSettings s) => s.locale.languageCode,
    ),
  );
  return ref
      .watch(dailySeerahRepositoryProvider)
      .getDailyEligibleEntries(languageCode: languageCode);
});
