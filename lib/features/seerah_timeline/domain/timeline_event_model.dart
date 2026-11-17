import 'package:flutter/foundation.dart';
import 'package:seerat_un_nabi/shared/models/reliability_status.dart';

@immutable
class TimelineEventModel {
  const TimelineEventModel({
    required this.stableId,
    required this.chapterStableId,
    required this.eraCode,
    required this.orderIndex,
    required this.titleUrdu,
    required this.summaryUrdu,
    required this.reliabilityStatus,
    this.claimStableId,
    this.hijriYear,
    this.gregorianYear,
  });

  final String stableId;
  final String chapterStableId;
  final String? claimStableId;
  final int? hijriYear;
  final int? gregorianYear;
  final String eraCode;
  final int orderIndex;
  final String titleUrdu;
  final String summaryUrdu;
  final ReliabilityStatus reliabilityStatus;
}

@immutable
class EventCrossReferenceModel {
  const EventCrossReferenceModel({
    required this.id,
    required this.sourceEntityId,
    required this.targetEntityId,
    required this.targetType,
    required this.relationType,
    required this.descriptionUrdu,
  });

  final int id;
  final String sourceEntityId;
  final String targetEntityId;
  final String targetType;
  final String relationType;
  final String descriptionUrdu;
}
