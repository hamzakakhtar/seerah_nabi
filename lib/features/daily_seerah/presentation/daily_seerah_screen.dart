import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:seerat_un_nabi/core/constants/route_names.dart';
import 'package:seerat_un_nabi/features/daily_seerah/data/daily_seerah_repository.dart';
import 'package:seerat_un_nabi/features/daily_seerah/presentation/daily_seerah_provider.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/domain/chapter_models.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/presentation/widgets/claim_quick_inspector_sheet.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/presentation/widgets/claim_rich_paragraph.dart';
import 'package:seerat_un_nabi/shared/providers/reading_settings_provider.dart';
import 'package:seerat_un_nabi/shared/widgets/seerah_app_bar.dart';

/// Daily Seerah screen presenting a deterministic daily researched reading
/// reflection with full reliability colors and interactive evidence inspection.
class DailySeerahScreen extends ConsumerStatefulWidget {
  const DailySeerahScreen({super.key});

  @override
  ConsumerState<DailySeerahScreen> createState() => _DailySeerahScreenState();
}

class _DailySeerahScreenState extends ConsumerState<DailySeerahScreen> {
  int? _manualOffset;
  String? _selectedClaimId;

  String _routeForChapter(String chapterStableId) => switch (chapterStableId) {
        'chapter_001' => RouteNames.chapterOne,
        'chapter_002' => RouteNames.chapterTwo,
        _ => '/chapters/id/$chapterStableId',
      };

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(dailySeerahEntriesProvider);
    final readingSettings = ref.watch(readingSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const SeerahAppBar(title: 'روزمرہ سیرت'),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(
            'روزمرہ اقتباس لوڈ کرنے میں دشواری پیش آئی۔',
            style: theme.textTheme.bodyLarge,
          ),
        ),
        data: (List<DailySeerahEntry> entries) {
          if (entries.isEmpty) {
            return Center(
              child: Text(
                'روزمرہ مطالعے کے لیے اقتباسات ابھی شامل نہیں کیے گئے۔',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          final now = DateTime.now();
          final daySeed = now.year * 366 + now.month * 31 + now.day;
          final index = (_manualOffset ?? daySeed) % entries.length;
          final entry = entries[index];

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Chip(label: Text(entry.eraLabelUrdu)),
                          const Spacer(),
                          Text(
                            'اقتباس ${index + 1} از ${entries.length}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        entry.chapterTitleUrdu,
                        style: theme.textTheme.titleLarge,
                      ),
                      const Divider(height: 24),
                      ClaimRichParagraph(
                        paragraph: entry.paragraph,
                        fontSize: readingSettings.fontSize,
                        selectedClaimId: _selectedClaimId,
                        onClaimTap: (HistoricalClaimModel claim) {
                          setState(() => _selectedClaimId = claim.stableId);
                          ClaimQuickInspectorSheet.show(context, claim: claim);
                        },
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _manualOffset = (index + 1) % entries.length;
                                _selectedClaimId = null;
                              });
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('اگلا اقتباس'),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: () => context.push(
                              _routeForChapter(entry.paragraph.chapterStableId),
                            ),
                            icon: const Icon(Icons.menu_book_outlined, size: 18),
                            label: const Text('مکمل باب پڑھیں'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
