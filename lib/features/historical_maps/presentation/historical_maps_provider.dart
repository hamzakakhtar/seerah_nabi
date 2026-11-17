import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/features/historical_maps/domain/historical_location_model.dart';
import 'package:seerat_un_nabi/features/seerah_timeline/domain/timeline_event_model.dart';
import 'package:seerat_un_nabi/shared/providers/repository_providers.dart';

final historicalLocationsProvider =
    FutureProvider<List<HistoricalLocationModel>>((ref) async {
  await ref.watch(databaseInitializerProvider.future);
  return ref.watch(historicalLocationRepositoryProvider).getAllLocations();
});

final eventsAtLocationProvider =
    FutureProvider.family<List<TimelineEventModel>, String>(
  (ref, locationStableId) async {
    await ref.watch(databaseInitializerProvider.future);
    return ref
        .watch(timelineRepositoryProvider)
        .getEventsForLocation(locationStableId);
  },
);
