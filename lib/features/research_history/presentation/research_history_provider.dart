import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/features/research_history/domain/research_version_model.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/domain/chapter_summary.dart';
import 'package:seerat_un_nabi/shared/providers/repository_providers.dart';


/// Filter token representing global (non-chapter-specific) revisions.
const String researchHistoryGlobalFilter = '__global__';

@immutable
class ResearchHistoryBundle {
  const ResearchHistoryBundle({
    required this.versions,
    required this.totalVersionCount,
    required this.hasGlobalVersions,
    required this.chaptersById,
    required this.filterableChapters,
  });

  final List<ResearchVersionModel> versions;
  final int totalVersionCount;
  final bool hasGlobalVersions;
  final Map<String, ChapterSummary> chaptersById;
  final List<ChapterSummary> filterableChapters;
}

final researchHistoryChapterFilterProvider =
NotifierProvider<ResearchHistoryChapterFilterNotifier, String?>(
  ResearchHistoryChapterFilterNotifier.new,
);

class ResearchHistoryChapterFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setFilter(String? chapterFilter) {
    state = chapterFilter;
  }
}

final researchHistoryBundleProvider =
FutureProvider.autoDispose<ResearchHistoryBundle>((ref) async {
  await ref.watch(databaseInitializerProvider.future);
  final selectedFilter = ref.watch(researchHistoryChapterFilterProvider);

  final governanceRepo = ref.watch(researchGovernanceRepositoryProvider);
  final chapterRepo = ref.watch(chapterRepositoryProvider);

  final allVersions = await governanceRepo.getResearchHistory();
  final directory = await chapterRepo.getChapterDirectory();

  final chaptersById = <String, ChapterSummary>{
    for (final chapter in directory) chapter.stableId: chapter,
  };

  final referencedChapterIds = allVersions
      .map((v) => v.chapterStableId)
      .whereType<String>()
      .toSet();

  final filterableChapters = directory
      .where((c) => referencedChapterIds.contains(c.stableId))
      .toList(growable: false);

  final hasGlobalVersions =
  allVersions.any((v) => v.chapterStableId == null);

  final filteredVersions = switch (selectedFilter) {
    null => allVersions,
    researchHistoryGlobalFilter =>
        allVersions.where((v) => v.chapterStableId == null).toList(growable: false),
    final chapterId => allVersions
        .where((v) => v.chapterStableId == chapterId)
        .toList(growable: false),
  };

  return ResearchHistoryBundle(
    versions: filteredVersions,
    totalVersionCount: allVersions.length,
    hasGlobalVersions: hasGlobalVersions,
    chaptersById: Map.unmodifiable(chaptersById),
    filterableChapters: List.unmodifiable(filterableChapters),
  );
});
