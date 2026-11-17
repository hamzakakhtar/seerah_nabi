import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/features/seerah_home/data/seerah_home_repository.dart';
import 'package:seerat_un_nabi/features/seerah_home/domain/seerah_home_state.dart';
import 'package:seerat_un_nabi/shared/models/reading_settings.dart';
import 'package:seerat_un_nabi/shared/providers/reading_settings_provider.dart';
import 'package:seerat_un_nabi/shared/providers/repository_providers.dart';

final seerahHomeRepositoryProvider = Provider<SeerahHomeRepository>((ref) {
  return SqliteSeerahHomeRepository(
    chapterRepository: ref.watch(chapterRepositoryProvider),
    readingProgressRepository: ref.watch(readingProgressRepositoryProvider),
  );
});

final seerahHomeProvider = FutureProvider<SeerahHomeState>((ref) async {
  await ref.watch(databaseInitializerProvider.future);
  final locale = ref.watch(
    readingSettingsProvider.select((ReadingSettings settings) => settings.locale),
  );
  return ref
      .watch(seerahHomeRepositoryProvider)
      .loadHomeOverview(languageCode: locale.languageCode);
});
