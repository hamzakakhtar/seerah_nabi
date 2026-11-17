import 'package:flutter/foundation.dart';
import 'package:seerat_un_nabi/features/historical_maps/domain/historical_location_model.dart';
import 'package:seerat_un_nabi/features/seerah_timeline/domain/timeline_event_model.dart';

/// Complete chronological event bundle combining the event, its geographic
/// locations, and related Seerah event cross-references.
@immutable
class TimelineEventBundle {
  const TimelineEventBundle({
    required this.event,
    required this.locations,
    required this.crossReferences,
  });

  final TimelineEventModel event;
  final List<HistoricalLocationModel> locations;
  final List<EventCrossReferenceModel> crossReferences;
}
