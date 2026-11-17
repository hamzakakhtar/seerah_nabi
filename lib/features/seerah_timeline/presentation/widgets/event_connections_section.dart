import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/features/seerah_timeline/domain/timeline_event_model.dart';
import 'package:seerat_un_nabi/features/seerah_timeline/presentation/timeline_provider.dart';

/// Reusable widget showing connected Seerah events/claims for an entity ID.
class EventConnectionsSection extends ConsumerWidget {
  const EventConnectionsSection({
    super.key,
    required this.entityStableId,
  });

  final String entityStableId;

  String _relationLabel(String relationType) => switch (relationType) {
        'background' => 'تاریخی پس منظر',
        'consequence' => 'تاریخی نتیجہ',
        'chronological_anchor' => 'زمانی ربط',
        'connected_family_event' => 'خاندانی و سوانحی ربط',
        _ => 'باہمی تعلق',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refsAsync = ref.watch(entityCrossReferencesProvider(entityStableId));
    final theme = Theme.of(context);

    return refsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (List<EventCrossReferenceModel> refs) {
        if (refs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 24),
            Text(
              'باہمی تاریخی روابط',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...refs.map(
              (EventCrossReferenceModel r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Chip(label: Text(_relationLabel(r.relationType))),
                      if (r.descriptionUrdu.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          r.descriptionUrdu,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
