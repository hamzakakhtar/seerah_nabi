import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/features/seerah_timeline/domain/timeline_event_bundle.dart';
import 'package:seerat_un_nabi/features/seerah_timeline/presentation/timeline_provider.dart';
import 'package:seerat_un_nabi/features/seerah_timeline/presentation/widgets/timeline_event_card.dart';
import 'package:seerat_un_nabi/shared/widgets/seerah_app_bar.dart';

/// Interactive Chronological Seerah Timeline screen with era filtering,
/// map location links, and event cross-references.
class SeerahTimelineScreen extends ConsumerWidget {
  const SeerahTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedEra = ref.watch(timelineEraFilterProvider);
    final eventsAsync = ref.watch(timelineEventsBundleProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const SeerahAppBar(title: 'زمانی خطِ سیر'),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('تمام ادوار'),
                  selected: selectedEra == null,
                  onSelected: (_) {
                    ref.read(timelineEraFilterProvider.notifier).setEra(null);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('قبل از بعثت'),
                  selected: selectedEra == 'pre_prophethood',
                  onSelected: (_) {
                    ref
                        .read(timelineEraFilterProvider.notifier)
                        .setEra('pre_prophethood');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('عہدِ طفولیت'),
                  selected: selectedEra == 'childhood',
                  onSelected: (_) {
                    ref
                        .read(timelineEraFilterProvider.notifier)
                        .setEra('childhood');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('ابتدائی مکی دور'),
                  selected: selectedEra == 'early_makkan',
                  onSelected: (_) {
                    ref
                        .read(timelineEraFilterProvider.notifier)
                        .setEra('early_makkan');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('آخری مکی دور'),
                  selected: selectedEra == 'late_makkan',
                  onSelected: (_) {
                    ref
                        .read(timelineEraFilterProvider.notifier)
                        .setEra('late_makkan');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('ہجرت و مدنی ابتدا'),
                  selected: selectedEra == 'hijrah_madinan',
                  onSelected: (_) {
                    ref
                        .read(timelineEraFilterProvider.notifier)
                        .setEra('hijrah_madinan');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('مدنی دور و تکمیلِ رسالت'),
                  selected: selectedEra == 'madinan_era',
                  onSelected: (_) {
                    ref
                        .read(timelineEraFilterProvider.notifier)
                        .setEra('madinan_era');
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('شمائل و اہلِ بیت'),
                  selected: selectedEra == 'thematic_seerah',
                  onSelected: (_) {
                    ref
                        .read(timelineEraFilterProvider.notifier)
                        .setEra('thematic_seerah');
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text(
                  'زمانی خطِ سیر لوڈ کرنے میں دشواری پیش آئی۔',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              data: (List<TimelineEventBundle> bundles) {
                if (bundles.isEmpty) {
                  return Center(
                    child: Text(
                      'اس دور کے واقعات جلد شامل کیے جائیں گے۔',
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: bundles.length,
                  itemBuilder: (context, index) => TimelineEventCard(
                    bundle: bundles[index],
                    isLast: index == bundles.length - 1,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
