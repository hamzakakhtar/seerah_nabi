import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/features/research_history/presentation/research_history_provider.dart';
import 'package:seerat_un_nabi/features/research_history/presentation/widgets/research_version_card.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/domain/chapter_summary.dart';
import 'package:seerat_un_nabi/shared/widgets/seerah_app_bar.dart';

/// Displays the offline SQLite editorial & scholarly revision history
/// for Seerah chapters, sources, and historical classifications.
class ResearchHistoryScreen extends ConsumerWidget {
  const ResearchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(researchHistoryChapterFilterProvider);
    final bundleAsync = ref.watch(researchHistoryBundleProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const SeerahAppBar(title: 'تاریخِ تحقیق'),
      body: bundleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'تاریخِ تحقیق لوڈ کرنے میں دشواری پیش آئی۔',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (ResearchHistoryBundle bundle) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.history_edu_outlined,
                          size: 26,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تحقیقی و اشاعتی ریکارڈ (${bundle.totalVersionCount})',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'یہاں متنِ سیرت، مآخذ، اسناد اور تاریخی درجہ بندی میں ہونے والی تمام مستند علمی ترامیم کا آف لائن ریکارڈ محفوظ ہے۔',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('تمام ترامیم'),
                      selected: selectedFilter == null,
                      onSelected: (_) {
                        ref
                            .read(researchHistoryChapterFilterProvider.notifier)
                            .setFilter(null);
                      },
                    ),
                    if (bundle.hasGlobalVersions) ...[
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('عمومی ترامیم'),
                        selected:
                        selectedFilter == researchHistoryGlobalFilter,
                        onSelected: (_) {
                          ref
                              .read(
                            researchHistoryChapterFilterProvider.notifier,
                          )
                              .setFilter(researchHistoryGlobalFilter);
                        },
                      ),
                    ],
                    for (final ChapterSummary chapter
                    in bundle.filterableChapters) ...[
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(chapter.titleUrdu),
                        selected: selectedFilter == chapter.stableId,
                        onSelected: (_) {
                          ref
                              .read(
                            researchHistoryChapterFilterProvider.notifier,
                          )
                              .setFilter(chapter.stableId);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: bundle.versions.isEmpty
                    ? Center(
                  child: Text(
                    'اس انتخاب کے لیے کوئی ترمیمی ریکارڈ موجود نہیں۔',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  itemCount: bundle.versions.length,
                  itemBuilder: (context, index) {
                    final version = bundle.versions[index];
                    final linkedChapter = version.chapterStableId == null
                        ? null
                        : bundle.chaptersById[version.chapterStableId];
                    return ResearchVersionCard(
                      version: version,
                      linkedChapter: linkedChapter,
                      isLatest: selectedFilter == null && index == 0,
                      isLast: index == bundle.versions.length - 1,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
