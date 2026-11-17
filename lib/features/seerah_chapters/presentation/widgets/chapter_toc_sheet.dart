import 'package:flutter/material.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/domain/chapter_models.dart';

/// Displays an interactive section outline for jumping within a Seerah chapter.
class ChapterTocSheet extends StatelessWidget {
  const ChapterTocSheet({
    super.key,
    required this.chapterTitle,
    required this.sections,
    required this.onSectionSelected,
  });

  final String chapterTitle;
  final List<SectionModel> sections;
  final ValueChanged<SectionModel> onSectionSelected;

  static Future<void> show(
    BuildContext context, {
    required String chapterTitle,
    required List<SectionModel> sections,
    required ValueChanged<SectionModel> onSectionSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => ChapterTocSheet(
        chapterTitle: chapterTitle,
        sections: sections,
        onSectionSelected: onSectionSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('فہرستِ عناوین', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(chapterTitle, style: theme.textTheme.bodySmall),
            const Divider(height: 24),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sections.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final section = sections[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      child: Text('${section.orderIndex}'),
                    ),
                    title: Text(
                      section.title,
                      style: theme.textTheme.titleMedium,
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      onSectionSelected(section);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
