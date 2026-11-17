import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:seerat_un_nabi/core/constants/route_names.dart';
import 'package:seerat_un_nabi/core/theme/app_typography.dart';
import 'package:seerat_un_nabi/features/evidence_explorer/domain/evidence_models.dart';
import 'package:seerat_un_nabi/features/narration_comparison/presentation/narration_comparison_provider.dart';
import 'package:seerat_un_nabi/shared/widgets/seerah_app_bar.dart';

/// Allows readers to compare narrations across Sunni, Shia, and classical
/// historical sources side by side, inspecting matn, isnad, and historical weight.
class NarrationComparisonScreen extends ConsumerWidget {
  const NarrationComparisonScreen({super.key});

  String _traditionLabel(SourceTradition t) => switch (t) {
        SourceTradition.sunni => 'سنی مآخذ',
        SourceTradition.shia => 'شیعہ مآخذ',
        SourceTradition.classicalHistory => 'کلاسیکی تاریخ',
        SourceTradition.biographical => 'تراجم و سیرت',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTradition = ref.watch(narrationTraditionFilterProvider);
    final narrationsAsync = ref.watch(narrationsListProvider);
    final selectedIds = ref.watch(comparedNarrationIdsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: SeerahAppBar(
        title: 'تقابلِ روایات',
        actions: [
          if (selectedIds.isNotEmpty)
            IconButton(
              tooltip: 'انتخاب صاف کریں',
              icon: const Icon(Icons.clear_all_rounded),
              onPressed: () {
                ref.read(comparedNarrationIdsProvider.notifier).clear();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('تمام روایات'),
                  selected: activeTradition == null,
                  onSelected: (_) {
                    ref
                        .read(narrationTraditionFilterProvider.notifier)
                        .setTradition(null);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('سنی مآخذ'),
                  selected: activeTradition == SourceTradition.sunni,
                  onSelected: (_) {
                    ref
                        .read(narrationTraditionFilterProvider.notifier)
                        .setTradition(SourceTradition.sunni);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('شیعہ مآخذ'),
                  selected: activeTradition == SourceTradition.shia,
                  onSelected: (_) {
                    ref
                        .read(narrationTraditionFilterProvider.notifier)
                        .setTradition(SourceTradition.shia);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('کلاسیکی تاریخ'),
                  selected: activeTradition == SourceTradition.classicalHistory,
                  onSelected: (_) {
                    ref
                        .read(narrationTraditionFilterProvider.notifier)
                        .setTradition(SourceTradition.classicalHistory);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: narrationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text(
                  'روایات لوڈ کرنے میں دشواری پیش آئی۔',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              data: (List<NarrationModel> narrations) {
                if (narrations.isEmpty) {
                  return Center(
                    child: Text(
                      'اس زمرے میں کوئی روایت موجود نہیں۔',
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }

                final compared = narrations
                    .where((NarrationModel n) => selectedIds.contains(n.stableId))
                    .toList(growable: false);

                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  children: [
                    if (compared.length == 2) ...[
                      _SideBySideComparisonPanel(
                        first: compared[0],
                        second: compared[1],
                        traditionLabel: _traditionLabel,
                      ),
                      const SizedBox(height: 18),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'تقابل کے لیے نیچے سے کوئی سی دو روایات منتخب کریں (${selectedIds.length}/2 منتخب)۔',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ...narrations.map((NarrationModel narration) {
                      final isSelected =
                          selectedIds.contains(narration.stableId);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Chip(
                                    label: Text(
                                      _traditionLabel(narration.tradition),
                                    ),
                                  ),
                                  const Spacer(),
                                  FilterChip(
                                    label: Text(
                                      isSelected ? 'منتخب' : 'تقابل میں شامل کریں',
                                    ),
                                    selected: isSelected,
                                    onSelected: (_) {
                                      ref
                                          .read(
                                            comparedNarrationIdsProvider
                                                .notifier,
                                          )
                                          .toggleSelection(narration.stableId);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                narration.reference.source.titleUrdu,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  narration.matnArabic,
                                  style: AppTypography.arabicSource(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                narration.urduSummary,
                                style: theme.textTheme.bodyMedium,
                              ),
                              if (narration.hadithGrade.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'اسنادی درجہ: ${narration.hadithGrade}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                              if (narration.historicalWeightNote.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'تاریخی وزن: ${narration.historicalWeightNote}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                              const SizedBox(height: 6),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: TextButton.icon(
                                  onPressed: () => context.push(
                                    '${RouteNames.sourceViewer}?sourceId=${narration.reference.source.stableId}',
                                  ),
                                  icon: const Icon(
                                    Icons.library_books_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('ماخذ دیکھیں'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SideBySideComparisonPanel extends StatelessWidget {
  const _SideBySideComparisonPanel({
    required this.first,
    required this.second,
    required this.traditionLabel,
  });

  final NarrationModel first;
  final NarrationModel second;
  final String Function(SourceTradition) traditionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primary.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تقابلی جائزہ', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _ComparisonColumn(n: first, label: traditionLabel)),
                const SizedBox(width: 12),
                Expanded(child: _ComparisonColumn(n: second, label: traditionLabel)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonColumn extends StatelessWidget {
  const _ComparisonColumn({
    required this.n,
    required this.label,
  });

  final NarrationModel n;
  final String Function(SourceTradition) label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            n.reference.source.titleUrdu,
            style: theme.textTheme.titleMedium,
          ),
          Text(
            label(n.tradition),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const Divider(height: 16),
          Text(
            n.urduSummary,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اسناد: ${n.hadithGrade}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'تاریخی حیثیت: ${n.historicalWeightNote}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
