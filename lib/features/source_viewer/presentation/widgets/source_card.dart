import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/core/theme/app_typography.dart';
import 'package:seerat_un_nabi/features/evidence_explorer/domain/evidence_models.dart';
import 'package:seerat_un_nabi/features/source_viewer/presentation/source_viewer_provider.dart';

/// Displays a classical Seerah/Hadith/History source with its Arabic title,
/// Urdu metadata, tradition badge, and expandable original Arabic excerpts.
class SourceCard extends ConsumerWidget {
  const SourceCard({
    super.key,
    required this.source,
    this.initiallyExpanded = false,
  });

  final SourceModel source;
  final bool initiallyExpanded;

  String _traditionLabel(SourceTradition tradition) => switch (tradition) {
        SourceTradition.sunni => 'سنی مآخذ',
        SourceTradition.shia => 'شیعہ مآخذ',
        SourceTradition.classicalHistory => 'کلاسیکی تاریخ',
        SourceTradition.biographical => 'تراجم و سیرت',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final refsAsync = ref.watch(sourceReferencesProvider(source.stableId));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          source.titleArabic,
          style: AppTypography.arabicSource(
            color: theme.colorScheme.onSurface,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
          textDirection: TextDirection.rtl,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${source.titleUrdu} — ${source.authorUrdu}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Chip(label: Text(_traditionLabel(source.tradition))),
                  if (source.authorDeathHijri != null)
                    Chip(label: Text('وفات: ${source.authorDeathHijri}ھ')),
                ],
              ),
            ],
          ),
        ),
        children: [
          refsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Text(
              'عبارات لوڈ کرنے میں دشواری پیش آئی۔',
              style: theme.textTheme.bodySmall,
            ),
            data: (List<SourceReferenceModel> references) {
              if (references.isEmpty) {
                return Text(
                  'اس کتاب کے منتخب اقتباسات اگلے مراحل میں شامل کیے جائیں گے۔',
                  style: theme.textTheme.bodySmall,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: references.map((SourceReferenceModel r) {
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (r.sectionOrHadithNumber.isNotEmpty)
                          Text(
                            r.sectionOrHadithNumber,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (r.originalArabicExcerpt.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            r.originalArabicExcerpt,
                            style: AppTypography.arabicSource(
                              color: theme.colorScheme.onSurface,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                        if (r.urduTranslation.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            r.urduTranslation,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}
