import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:seerat_un_nabi/core/constants/route_names.dart';
import 'package:seerat_un_nabi/features/seerah_timeline/domain/timeline_event_bundle.dart';

/// Displays an individual chronological Seerah event with timeline rail,
/// year badge, reliability color, linked map pins, and cross-references.
class TimelineEventCard extends StatelessWidget {
  const TimelineEventCard({
    super.key,
    required this.bundle,
    required this.isLast,
  });

  final TimelineEventBundle bundle;
  final bool isLast;

  String _routeForChapter(String chapterStableId) => switch (chapterStableId) {
        'chapter_001' => RouteNames.chapterOne,
        'chapter_002' => RouteNames.chapterTwo,
        'chapter_003' => RouteNames.chapterThree,
        'chapter_004' => RouteNames.chapterFour,
        'chapter_005' => RouteNames.chapterFive,
        'chapter_006' => RouteNames.chapterSix,
        'chapter_007' => RouteNames.chapterSeven,
        'chapter_008' => RouteNames.chapterEight,
        'chapter_009' => RouteNames.chapterNine,
        'chapter_010' => RouteNames.chapterTen,
        'chapter_011' => RouteNames.chapterEleven,
        'chapter_012' => RouteNames.chapterTwelve,
        'chapter_013' => RouteNames.chapterThirteen,
        'chapter_014' => RouteNames.chapterFourteen,
        'chapter_015' => RouteNames.chapterFifteen,
        'chapter_016' => RouteNames.chapterSixteen,
        _ => '/chapters/id/$chapterStableId',
      };

  String _eraLabelUrdu(String eraCode) => switch (eraCode) {
        'pre_prophethood' => 'قبل از بعثت',
        'childhood' => 'عہدِ طفولیت',
        'early_makkan' => 'ابتدائی مکی دور',
        'late_makkan' => 'آخری مکی دور',
        'hijrah_madinan' => 'ہجرت و مدنی ابتدا',
        'madinan_era' => 'مدنی دور و تکمیلِ رسالت',
        'thematic_seerah' => 'شمائل و اہلِ بیت',
        'makkan' => 'مکی دور',
        'madinan' => 'مدنی دور',
        _ => eraCode,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = bundle.event;
    final statusColor =
        event.reliabilityStatus.colorForBrightness(theme.brightness);

    final yearLabel = event.hijriYear != null
        ? '${event.hijriYear}ھ'
        : (event.gregorianYear != null
            ? 'تقریباً ${event.gregorianYear}ء'
            : _eraLabelUrdu(event.eraCode));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(top: 18),
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2.5,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Chip(label: Text(yearLabel)),
                        Chip(label: Text(_eraLabelUrdu(event.eraCode))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      event.titleUrdu,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.summaryUrdu,
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (bundle.locations.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: bundle.locations
                            .map(
                              (loc) => ActionChip(
                                avatar: const Icon(
                                  Icons.place_outlined,
                                  size: 16,
                                ),
                                label: Text(loc.nameUrdu),
                                onPressed: () => context.push(
                                  '${RouteNames.historicalMaps}?locationId=${loc.stableId}',
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                    if (bundle.crossReferences.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'متصل واقعات (${bundle.crossReferences.length})',
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(height: 4),
                            ...bundle.crossReferences.map(
                              (cr) => Text(
                                '• ${cr.descriptionUrdu}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        TextButton.icon(
                          onPressed: () => context.push(
                            _routeForChapter(event.chapterStableId),
                          ),
                          icon: const Icon(Icons.menu_book_outlined, size: 18),
                          label: const Text('باب پڑھیں'),
                        ),
                        if (event.claimStableId != null)
                          TextButton.icon(
                            onPressed: () => context.push(
                              '${RouteNames.evidenceExplorer}?claimId=${event.claimStableId}',
                            ),
                            icon: const Icon(Icons.verified_outlined, size: 18),
                            label: const Text('شواہد دیکھیں'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
