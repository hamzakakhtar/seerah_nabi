import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/features/evidence_explorer/domain/evidence_models.dart';
import 'package:seerat_un_nabi/features/source_viewer/presentation/source_viewer_provider.dart';
import 'package:seerat_un_nabi/features/source_viewer/presentation/widgets/source_card.dart';
import 'package:seerat_un_nabi/shared/widgets/seerah_app_bar.dart';

/// Original Arabic Source Viewer screen presenting classical Sunni, Shia,
/// and historical Seerah works with original Arabic excerpts.
class SourceViewerScreen extends ConsumerWidget {
  const SourceViewerScreen({
    super.key,
    this.initialSourceId,
  });

  final String? initialSourceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTradition = ref.watch(sourceTraditionFilterProvider);
    final sourcesAsync = ref.watch(sourcesListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const SeerahAppBar(title: 'عربی مآخذ'),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('تمام مآخذ'),
                  selected: selectedTradition == null,
                  onSelected: (_) {
                    ref
                        .read(sourceTraditionFilterProvider.notifier)
                        .setTradition(null);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('سنی مآخذ'),
                  selected: selectedTradition == SourceTradition.sunni,
                  onSelected: (_) {
                    ref
                        .read(sourceTraditionFilterProvider.notifier)
                        .setTradition(SourceTradition.sunni);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('شیعہ مآخذ'),
                  selected: selectedTradition == SourceTradition.shia,
                  onSelected: (_) {
                    ref
                        .read(sourceTraditionFilterProvider.notifier)
                        .setTradition(SourceTradition.shia);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('کلاسیکی تاریخ'),
                  selected:
                      selectedTradition == SourceTradition.classicalHistory,
                  onSelected: (_) {
                    ref
                        .read(sourceTraditionFilterProvider.notifier)
                        .setTradition(SourceTradition.classicalHistory);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: sourcesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text(
                  'مآخذ لوڈ کرنے میں دشواری پیش آئی۔',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              data: (List<SourceModel> sources) {
                if (sources.isEmpty) {
                  return Center(
                    child: Text(
                      'اس زمرے میں کوئی ماخذ دستیاب نہیں۔',
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }
                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: sources.length,
                  itemBuilder: (context, index) {
                    final source = sources[index];
                    return SourceCard(
                      source: source,
                      initiallyExpanded: source.stableId == initialSourceId,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
