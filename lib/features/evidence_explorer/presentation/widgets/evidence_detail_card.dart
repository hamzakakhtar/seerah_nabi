import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:seerat_un_nabi/core/constants/route_names.dart';
import 'package:seerat_un_nabi/core/theme/app_typography.dart';
import 'package:seerat_un_nabi/features/evidence_explorer/domain/evidence_models.dart';

/// Displays a single [ClaimEvidenceModel] with primary source metadata,
/// original Arabic excerpt, narration chain, and distinct Hadith vs.
/// historical evaluation notes.
class EvidenceDetailCard extends StatelessWidget {
  const EvidenceDetailCard({
    super.key,
    required this.evidence,
  });

  final ClaimEvidenceModel evidence;

  String _roleLabelUrdu(EvidenceRole role) => switch (role) {
        EvidenceRole.primarySupport => 'بنیادی دلیل',
        EvidenceRole.corroborating => 'تائیدی شہادت',
        EvidenceRole.conflicting => 'اختلافی روایت',
        EvidenceRole.weaknessReason => 'اسنادی کمزوری کی وضاحت',
      };

  String _traditionLabelUrdu(SourceTradition tradition) => switch (tradition) {
        SourceTradition.sunni => 'سنی مآخذ',
        SourceTradition.shia => 'شیعہ مآخذ',
        SourceTradition.classicalHistory => 'کلاسیکی تاریخ',
        SourceTradition.biographical => 'تراجم و سیرت',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ref = evidence.reference;
    final source = ref.source;
    final narration = evidence.narration;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(label: Text(_roleLabelUrdu(evidence.evidenceRole))),
                Chip(label: Text(_traditionLabelUrdu(source.tradition))),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              source.titleUrdu,
              style: theme.textTheme.titleLarge,
            ),
            Text(
              '${source.titleArabic} — ${source.authorUrdu}',
              style: theme.textTheme.bodySmall,
            ),
            if (ref.sectionOrHadithNumber.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                ref.sectionOrHadithNumber,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (ref.originalArabicExcerpt.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  ref.originalArabicExcerpt,
                  style: AppTypography.arabicSource(
                    color: theme.colorScheme.onSurface,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
            if (ref.urduTranslation.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(ref.urduTranslation, style: theme.textTheme.bodyMedium),
            ],
            if (narration != null) ...[
              const Divider(height: 24),
              Text(
                'اسنادی و تاریخی جائزہ',
                style: theme.textTheme.titleMedium,
              ),
              if (narration.hadithGrade.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'محدثین کا حکم: ${narration.hadithGrade}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (narration.historicalWeightNote.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'تاریخی وزن: ${narration.historicalWeightNote}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (narration.isnadChainSummary.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'سلسلہ سند: ${narration.isnadChainSummary}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (narration.narrators.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: narration.narrators
                      .map(
                        (n) => Chip(
                          avatar: const Icon(Icons.person_outline, size: 16),
                          label: Text(
                            n.deathHijri != null
                                ? '${n.nameUrdu} (وفات: ${n.deathHijri}ھ)'
                                : n.nameUrdu,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ],
            if (evidence.notesUrdu.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                evidence.notesUrdu,
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () {
                  context.push(
                    '${RouteNames.sourceViewer}?sourceId=${source.stableId}',
                  );
                },
                icon: const Icon(Icons.library_books_outlined, size: 18),
                label: const Text('اصل عربی ماخذ دیکھیں'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
