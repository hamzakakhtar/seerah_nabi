import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:seerat_un_nabi/core/constants/route_names.dart';
import 'package:seerat_un_nabi/core/theme/app_typography.dart';
import 'package:seerat_un_nabi/features/evidence_explorer/domain/evidence_models.dart';
import 'package:seerat_un_nabi/features/personal_notes/presentation/widgets/note_editor_sheet.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/domain/chapter_models.dart';
import 'package:seerat_un_nabi/features/seerah_timeline/presentation/widgets/event_connections_section.dart';
import 'package:seerat_un_nabi/shared/providers/repository_providers.dart';

final _claimEvidenceFutureProvider =
    FutureProvider.family<List<ClaimEvidenceModel>, String>(
  (ref, claimStableId) async {
    return ref
        .watch(evidenceRepositoryProvider)
        .getEvidenceForClaim(claimStableId);
  },
);

/// Displays historical classification reasoning, scholarly assessment, and
/// classical primary sources when a reader taps a colored claim in the text,
/// with direct navigation to the full Evidence Explorer and Source Viewer.
class ClaimQuickInspectorSheet extends ConsumerWidget {
  const ClaimQuickInspectorSheet({
    super.key,
    required this.claim,
  });

  final HistoricalClaimModel claim;

  static Future<void> show(
    BuildContext context, {
    required HistoricalClaimModel claim,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ClaimQuickInspectorSheet(claim: claim),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor =
        claim.reliabilityStatus.colorForBrightness(theme.brightness);
    final evidenceAsync =
        ref.watch(_claimEvidenceFutureProvider(claim.stableId));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    claim.reliabilityStatus.urduLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(
                      '${RouteNames.evidenceExplorer}?claimId=${claim.stableId}',
                    );
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('تفصیلی شواہد'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              claim.claimText.trim(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: statusColor,
              ),
            ),
            const Divider(height: 28),
            Text(
              'تحقیقی وجہ اور علمی جائزہ',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              claim.classificationReason,
              style: theme.textTheme.bodyMedium,
            ),
            if (claim.scholarlyAssessment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                claim.scholarlyAssessment,
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  NoteEditorSheet.show(
                    context,
                    chapterStableId: claim.chapterStableId,
                    paragraphStableId: claim.paragraphStableId,
                    claimStableId: claim.stableId,
                    contextExcerpt: claim.claimText.trim(),
                  );
                },
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('اس نکتے پر ذاتی حاشیہ لکھیں'),
              ),
            ),
            const Divider(height: 28),
            Text(
              'بنیادی مآخذ و حوالہ جات',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            evidenceAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Text(
                'حوالہ جات لوڈ کرنے میں دشواری پیش آئی۔',
                style: theme.textTheme.bodySmall,
              ),
              data: (List<ClaimEvidenceModel> evidenceList) {
                if (evidenceList.isEmpty) {
                  return Text(
                    'اس دعوے کے تفصیلی مآخذ ریکارڈ میں محفوظ کیے جا رہے ہیں۔',
                    style: theme.textTheme.bodySmall,
                  );
                }
                return Column(
                  children: evidenceList
                      .map(
                        (ClaimEvidenceModel ev) =>
                            _EvidenceSourceCard(evidence: ev),
                      )
                      .toList(growable: false),
                );
              },
            ),
            EventConnectionsSection(entityStableId: claim.stableId),
          ],
        );
      },
    );
  }
}

class _EvidenceSourceCard extends StatelessWidget {
  const _EvidenceSourceCard({required this.evidence});

  final ClaimEvidenceModel evidence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ref = evidence.reference;
    final source = ref.source;
    final narration = evidence.narration;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${source.titleUrdu} (${source.authorUrdu})',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'اصل عربی ماخذ',
                  icon: const Icon(Icons.library_books_outlined, size: 18),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(
                      '${RouteNames.sourceViewer}?sourceId=${source.stableId}',
                    );
                  },
                ),
              ],
            ),
            if (ref.sectionOrHadithNumber.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                ref.sectionOrHadithNumber,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
            if (ref.originalArabicExcerpt.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
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
              const SizedBox(height: 8),
              Text(
                ref.urduTranslation,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (narration != null && narration.hadithGrade.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'اسنادی حیثیت: ${narration.hadithGrade}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (evidence.notesUrdu.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                evidence.notesUrdu,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
