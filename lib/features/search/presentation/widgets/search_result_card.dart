import 'package:flutter/material.dart';
import 'package:seerat_un_nabi/features/search/domain/search_models.dart';

/// Card presenting a single offline search hit with category badge, optional
/// reliability indicator, and direct navigation callback.
class SearchResultCard extends StatelessWidget {
  const SearchResultCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final SearchResultItem item;
  final VoidCallback onTap;

  IconData _iconForCategory(SearchCategory category) => switch (category) {
        SearchCategory.all => Icons.search_rounded,
        SearchCategory.chapters => Icons.menu_book_rounded,
        SearchCategory.claims => Icons.verified_outlined,
        SearchCategory.timeline => Icons.timeline_rounded,
        SearchCategory.sources => Icons.library_books_outlined,
        SearchCategory.locations => Icons.place_outlined,
        SearchCategory.pronunciation => Icons.record_voice_over_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reliabilityColor =
        item.reliabilityStatus?.colorForBrightness(theme.brightness);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
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
                      color: theme.colorScheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _iconForCategory(item.category),
                          size: 15,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.category.urduLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.reliabilityStatus != null &&
                      reliabilityColor != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: reliabilityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: reliabilityColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        item.reliabilityStatus!.urduLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: reliabilityColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else if (item.badgeLabel != null &&
                      item.badgeLabel!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.badgeLabel!,
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (item.subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (item.snippet.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  item.snippet,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
