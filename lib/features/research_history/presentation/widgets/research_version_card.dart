import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:seerat_un_nabi/features/research_history/domain/research_version_model.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/domain/chapter_summary.dart';

/// Editorial revision-history timeline card displaying a scholarly version tag,
/// revision authority, date, linked chapter, and Urdu summary of changes.
class ResearchVersionCard extends StatelessWidget {
  const ResearchVersionCard({
    super.key,
    required this.version,
    required this.isLatest,
    required this.isLast,
    this.linkedChapter,
  });

  final ResearchVersionModel version;
  final bool isLatest;
  final bool isLast;
  final ChapterSummary? linkedChapter;

  String _formatDate(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _revisedByUrdu(String revisedBy) {
    if (revisedBy == 'Seerah Research Editorial Board') {
      return 'مجلسِ ادارت و تحقیقِ سیرت';
    }
    return revisedBy;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = isLatest
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(top: 18),
                  decoration: BoxDecoration(
                    color: accentColor,
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
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              version.versionTag,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: accentColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        if (isLatest)
                          Chip(
                            label: const Text('تازہ ترین اشاعت'),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.10),
                          ),
                        Chip(
                          avatar: const Icon(
                            Icons.calendar_today_outlined,
                            size: 15,
                          ),
                          label: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(_formatDate(version.createdAt)),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      version.changeSummaryUrdu,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'مرتب و مصدقہ: ${_revisedByUrdu(version.revisedBy)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (linkedChapter != null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: () => context.push(
                            linkedChapter!.routePath,
                          ),
                          icon: const Icon(
                            Icons.menu_book_outlined,
                            size: 18,
                          ),
                          label: Text(
                            'متعلقہ باب کھولیں: ${linkedChapter!.titleUrdu}',
                          ),
                        ),
                      ),
                    ],
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
