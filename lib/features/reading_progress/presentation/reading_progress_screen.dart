import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:seerat_un_nabi/core/constants/route_names.dart';
import 'package:seerat_un_nabi/features/reading_progress/domain/reading_progress_models.dart';
import 'package:seerat_un_nabi/features/reading_progress/presentation/reading_progress_provider.dart';
import 'package:seerat_un_nabi/features/seerah_home/presentation/widgets/continue_reading_card.dart';
import 'package:seerat_un_nabi/shared/widgets/seerah_app_bar.dart';

/// Displays Smart Reading Progress, per-chapter completion bars, and recent
/// reading session history.
class ReadingProgressScreen extends ConsumerWidget {
  const ReadingProgressScreen({super.key});

  String _routeForChapter(String chapterStableId, {double? offset}) {
    final base = switch (chapterStableId) {
      'chapter_001' => RouteNames.chapterOne,
      'chapter_002' => RouteNames.chapterTwo,
      _ => '/chapters/id/$chapterStableId',
    };
    if (offset != null && offset > 0) {
      return '$base?offset=${offset.toStringAsFixed(1)}';
    }
    return base;
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds سیکنڈ';
    final minutes = seconds ~/ 60;
    final rem = seconds % 60;
    return rem == 0 ? '$minutes منٹ' : '$minutes منٹ $rem سیکنڈ';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(readingProgressOverviewProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const SeerahAppBar(title: 'رفتارِ مطالعہ'),
      body: overviewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(
            'مطالعے کا ریکارڈ لوڈ کرنے میں دشواری پیش آئی۔',
            style: theme.textTheme.bodyLarge,
          ),
        ),
        data: (ReadingProgressOverview overview) {
          final last = overview.lastActive;
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              if (last != null) ...[
                ContinueReadingCard(
                  chapterTitleUrdu:
                      overview.chapterTitlesById[last.chapterStableId] ??
                          last.chapterStableId,
                  progressFraction: last.completionFraction,
                  onContinueTap: () => context.push(
                    _routeForChapter(
                      last.chapterStableId,
                      offset: last.scrollOffset,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                'ابواب کی تکمیل',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (overview.allProgress.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'مطالعہ شروع کرنے پر ہر باب کی پیش رفت خودکار طور پر یہاں محفوظ ہوگی۔',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                )
              else
                ...overview.allProgress.map((ReadingProgressModel p) {
                  final title = overview.chapterTitlesById[p.chapterStableId] ??
                      p.chapterStableId;
                  final percent = (p.completionFraction * 100).round();
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(title, style: theme.textTheme.titleMedium),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: p.completionFraction.clamp(0.0, 1.0),
                            borderRadius: BorderRadius.circular(6),
                            minHeight: 6,
                          ),
                          const SizedBox(height: 4),
                          Text('$percent٪ مکمل', style: theme.textTheme.bodySmall),
                        ],
                      ),
                      onTap: () => context.push(
                        _routeForChapter(
                          p.chapterStableId,
                          offset: p.scrollOffset,
                        ),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20),
              Text(
                'حالیہ نشستیں',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (overview.recentSessions.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'ابھی کوئی مطالعاتی نشست ریکارڈ نہیں ہوئی۔',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                )
              else
                ...overview.recentSessions.map((ReadingSessionModel s) {
                  final title = overview.chapterTitlesById[s.chapterStableId] ??
                      s.chapterStableId;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.history_rounded),
                      title: Text(title, style: theme.textTheme.titleMedium),
                      subtitle: Text(
                        'دورانیہ: ${_formatDuration(s.durationSeconds)} — '
                        '${s.startedAt.toLocal().toString().split('.').first}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
