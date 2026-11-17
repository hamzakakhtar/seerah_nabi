import 'package:flutter/material.dart';

/// Displays the Smart Reading Progress card with the required Urdu prompt:
/// "آپ یہاں مطالعہ چھوڑ کر گئے تھے۔"
class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({
    super.key,
    required this.chapterTitleUrdu,
    required this.progressFraction,
    required this.onContinueTap,
  });

  final String chapterTitleUrdu;
  final double progressFraction;
  final VoidCallback onContinueTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'آپ یہاں مطالعہ چھوڑ کر گئے تھے۔',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              chapterTitleUrdu,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progressFraction.clamp(0.0, 1.0),
              borderRadius: BorderRadius.circular(6),
              minHeight: 6,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: onContinueTap,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('مطالعہ جاری رکھیں'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
