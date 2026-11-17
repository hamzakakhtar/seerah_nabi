import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/features/seerah_timeline/domain/timeline_event_bundle.dart';
import 'package:seerat_un_nabi/features/seerah_timeline/domain/timeline_event_model.dart';
import 'package:seerat_un_nabi/shared/models/reliability_status.dart';
import 'package:seerat_un_nabi/shared/providers/repository_providers.dart';

final timelineEraFilterProvider =
    NotifierProvider<TimelineEraFilterNotifier, String?>(
  TimelineEraFilterNotifier.new,
);

class TimelineEraFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setEra(String? eraCode) {
    state = eraCode;
  }
}

final timelineReliabilityFilterProvider =
    NotifierProvider<TimelineReliabilityFilterNotifier, ReliabilityStatus?>(
  TimelineReliabilityFilterNotifier.new,
);

class TimelineReliabilityFilterNotifier extends Notifier<ReliabilityStatus?> {
  @override
  ReliabilityStatus? build() => null;

  void setStatus(ReliabilityStatus? status) {
    state = status;
  }
}

final timelineEventsBundleProvider =
    FutureProvider<List<TimelineEventBundle>>((ref) async {
  await ref.watch(databaseInitializerProvider.future);
  final era = ref.watch(timelineEraFilterProvider);
  final reliability = ref.watch(timelineReliabilityFilterProvider);

  final timelineRepo = ref.watch(timelineRepositoryProvider);
  final locationRepo = ref.watch(historicalLocationRepositoryProvider);

  final events = await timelineRepo.getChronologicalEvents(eraCode: era);
  final filteredEvents = reliability == null
      ? events
      : events.where((e) => e.reliabilityStatus == reliability).toList();

  final bundles = <TimelineEventBundle>[];
  for (final event in filteredEvents) {
    final locations =
        await locationRepo.getLocationsForTimelineEvent(event.stableId);
    final crossRefs =
        await timelineRepo.getCrossReferencesForEntity(event.stableId);
    bundles.add(
      TimelineEventBundle(
        event: event,
        locations: locations,
        crossReferences: crossRefs,
      ),
    );
  }
  return List.unmodifiable(bundles);
});

final entityCrossReferencesProvider =
    FutureProvider.family<List<EventCrossReferenceModel>, String>(
  (ref, entityStableId) async {
    await ref.watch(databaseInitializerProvider.future);
    return ref
        .watch(timelineRepositoryProvider)
        .getCrossReferencesForEntity(entityStableId);
  },
);
