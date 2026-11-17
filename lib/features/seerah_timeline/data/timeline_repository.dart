import 'package:seerat_un_nabi/core/database/app_database.dart';
import 'package:seerat_un_nabi/features/seerah_timeline/domain/timeline_event_model.dart';
import 'package:seerat_un_nabi/shared/models/reliability_status.dart';

abstract interface class TimelineRepository {
  Future<List<TimelineEventModel>> getChronologicalEvents({String? eraCode});

  Future<List<TimelineEventModel>> getEventsForLocation(
    String locationStableId,
  );

  Future<List<EventCrossReferenceModel>> getCrossReferencesForEntity(
    String entityStableId,
  );
}

final class SqliteTimelineRepository implements TimelineRepository {
  SqliteTimelineRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<TimelineEventModel>> getChronologicalEvents({
    String? eraCode,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      'timeline_events',
      where: eraCode != null ? 'era_code = ?' : null,
      whereArgs: eraCode != null ? [eraCode] : null,
      orderBy: 'order_index ASC',
    );
    return rows.map(_mapEvent).toList(growable: false);
  }

  @override
  Future<List<TimelineEventModel>> getEventsForLocation(
    String locationStableId,
  ) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT t.*
      FROM timeline_events t
      INNER JOIN event_locations el
        ON el.timeline_event_stable_id = t.stable_id
      WHERE el.location_stable_id = ?
      ORDER BY t.order_index ASC
      ''',
      [locationStableId],
    );
    return rows.map(_mapEvent).toList(growable: false);
  }

  @override
  Future<List<EventCrossReferenceModel>> getCrossReferencesForEntity(
    String entityStableId,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      'event_cross_references',
      where: 'source_entity_id = ? OR target_entity_id = ?',
      whereArgs: [entityStableId, entityStableId],
    );
    return rows
        .map(
          (r) => EventCrossReferenceModel(
            id: AppDatabase.readInt(r['id']),
            sourceEntityId: AppDatabase.readString(r['source_entity_id']),
            targetEntityId: AppDatabase.readString(r['target_entity_id']),
            targetType: AppDatabase.readString(r['target_type']),
            relationType: AppDatabase.readString(r['relation_type']),
            descriptionUrdu: AppDatabase.readString(r['description_urdu']),
          ),
        )
        .toList(growable: false);
  }

  TimelineEventModel _mapEvent(Map<String, Object?> r) {
    return TimelineEventModel(
      stableId: AppDatabase.readString(r['stable_id']),
      chapterStableId: AppDatabase.readString(r['chapter_stable_id']),
      claimStableId: AppDatabase.readNullableString(r['claim_stable_id']),
      hijriYear: AppDatabase.readNullableInt(r['hijri_year']),
      gregorianYear: AppDatabase.readNullableInt(r['gregorian_year']),
      eraCode: AppDatabase.readString(r['era_code']),
      orderIndex: AppDatabase.readInt(r['order_index']),
      titleUrdu: AppDatabase.readString(r['title_urdu']),
      summaryUrdu: AppDatabase.readString(r['summary_urdu']),
      reliabilityStatus: ReliabilityStatus.fromStorage(
        AppDatabase.readString(r['reliability_status']),
      ),
    );
  }
}
