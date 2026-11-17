import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:seerat_un_nabi/core/constants/route_names.dart';
import 'package:seerat_un_nabi/core/widgets/reliability_legend_banner.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/domain/chapter_summary.dart';
import 'package:seerat_un_nabi/features/seerah_home/domain/seerah_home_state.dart';
import 'package:seerat_un_nabi/features/seerah_home/presentation/seerah_home_provider.dart';
import 'package:seerat_un_nabi/features/seerah_home/presentation/widgets/chapter_directory_card.dart';
import 'package:seerat_un_nabi/features/seerah_home/presentation/widgets/continue_reading_card.dart';
import 'package:seerat_un_nabi/features/seerah_home/presentation/widgets/research_tools_grid.dart';
import 'package:seerat_un_nabi/shared/providers/reading_settings_provider.dart';
import 'package:seerat_un_nabi/shared/widgets/seerah_app_bar.dart';

/// Primary Seerah Home Screen featuring editorial book layout, first-open
/// reliability legend, Smart Reading Progress banner, era-filtered chapter
/// directory, and research tool navigation.
class SeerahHomeScreen extends ConsumerStatefulWidget {
  const SeerahHomeScreen({super.key});

  @override
  ConsumerState<SeerahHomeScreen> createState() => _SeerahHomeScreenState();
}

class _SeerahHomeScreenState extends ConsumerState<SeerahHomeScreen> {
  String? _selectedEraFilter;

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(seerahHomeProvider);
    final readingSettings = ref.watch(readingSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: SeerahAppBar(
        title: 'سیرت النبی ﷺ',
        actions: [
          IconButton(
            tooltip: 'تلاش',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push(RouteNames.search),
          ),
        ],
      ),
      body: homeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'فہرست لوڈ کرنے میں دشواری پیش آئی۔',
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
        data: (SeerahHomeState homeState) {
          final eraLabels = <String>{
            for (final ChapterSummary c in homeState.chapters) c.eraLabelUrdu,
          }.toList(growable: false);

          final filteredChapters = _selectedEraFilter == null
              ? homeState.chapters
              : homeState.chapters
                  .where(
                    (ChapterSummary c) => c.eraLabelUrdu == _selectedEraFilter,
                  )
                  .toList(growable: false);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تحقیقی و مستند مطالعۂ سیرت',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تاریخی شواہد، مستند مآخذ اور سلیس اردو اسلوب پر مبنی علمی پیشکش',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!readingSettings.hasSeenReliabilityLegend) ...[
                ReliabilityLegendBanner(
                  onDismiss: () {
                    ref
                        .read(readingSettingsProvider.notifier)
                        .dismissReliabilityLegend();
                  },
                ),
                const SizedBox(height: 16),
              ],
              ContinueReadingCard(
                chapterTitleUrdu: homeState.lastChapterTitleUrdu,
                progressFraction: homeState.progressFraction,
                onContinueTap: () => context.push(homeState.lastChapterRoute),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'ابوابِ سیرت',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Text(
                    '${filteredChapters.length} ابواب',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              if (eraLabels.length > 1) ...[
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('تمام ادوار'),
                        selected: _selectedEraFilter == null,
                        onSelected: (_) {
                          setState(() => _selectedEraFilter = null);
                        },
                      ),
                      const SizedBox(width: 8),
                      ...eraLabels.map(
                        (String era) => Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: ChoiceChip(
                            label: Text(era),
                            selected: _selectedEraFilter == era,
                            onSelected: (_) {
                              setState(() => _selectedEraFilter = era);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              ...filteredChapters.map(
                (ChapterSummary chapter) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ChapterDirectoryCard(
                    chapter: chapter,
                    onTap: () => context.push(
                      chapter.routePath.isNotEmpty
                          ? chapter.routePath
                          : '/chapters/id/${chapter.stableId}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'تحقیقی و مطالعاتی سہولیات',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              const ResearchToolsGrid(),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
