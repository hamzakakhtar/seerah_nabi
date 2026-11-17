import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/features/reading_progress/domain/reading_progress_models.dart';
import 'package:seerat_un_nabi/shared/models/reading_settings.dart';
import 'package:seerat_un_nabi/shared/providers/reading_settings_provider.dart';
import 'package:seerat_un_nabi/shared/providers/repository_providers.dart';

@immutable
class ReadingProgressOverview {
  const ReadingProgressOverview({
    required this.lastActive,
    required this.allProgress,
    required this.recentSessions,
    required this.chapterTitlesById,
  });

  final ReadingProgressModel? lastActive;
  final List<ReadingProgressModel> allProgress;
  final List<ReadingSessionModel> recentSessions;
  final Map<String, String> chapterTitlesById;
}

final readingProgressOverviewProvider =
    FutureProvider<ReadingProgressOverview>((ref) async {
  await ref.watch(databaseInitializerProvider.future);
  final languageCode = ref.watch(
    readingSettingsProvider.select(
      (ReadingSettings s) => s.locale.languageCode,
    ),
  );
  final progressRepo = ref.watch(readingProgressRepositoryProvider);
  final chapterRepo = ref.watch(chapterRepositoryProvider);

  final lastActive = await progressRepo.getLastActiveProgress();
  final allProgress = await progressRepo.getAllChapterProgress();
  final sessions = await progressRepo.getRecentSessions();
  final chapters =
      await chapterRepo.getChapterDirectory(languageCode: languageCode);

  final titles = {for (final c in chapters) c.stableId: c.titleUrdu};

  return ReadingProgressOverview(
    lastActive: lastActive,
    allProgress: allProgress,
    recentSessions: sessions,
    chapterTitlesById: titles,
  );
});
