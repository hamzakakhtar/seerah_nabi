import 'package:seerat_un_nabi/core/database/app_database.dart';
import 'package:seerat_un_nabi/features/historical_maps/domain/historical_location_model.dart';

abstract interface class HistoricalLocationRepository {
  Future<List<HistoricalLocationModel>> getAllLocations();

  Future<List<HistoricalLocationModel>> getLocationsForTimelineEvent(
    String timelineEventStableId,
  );
}

final class SqliteHistoricalLocationRepository
    implements HistoricalLocationRepository {
  SqliteHistoricalLocationRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<HistoricalLocationModel>> getAllLocations() async {
    final db = await _db.database;
    final rows = await db.query(
      'historical_locations',
      orderBy: 'name_urdu ASC',
    );
    return rows.map(_map).toList(growable: false);
  }

  @override
  Future<List<HistoricalLocationModel>> getLocationsForTimelineEvent(
    String timelineEventStableId,
  ) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT hl.*
      FROM historical_locations hl
      INNER JOIN event_locations el
        ON el.location_stable_id = hl.stable_id
      WHERE el.timeline_event_stable_id = ?
      ''',
      [timelineEventStableId],
    );
    return rows.map(_map).toList(growable: false);
  }

  HistoricalLocationModel _map(Map<String, Object?> r) {
    return HistoricalLocationModel(
      stableId: AppDatabase.readString(r['stable_id']),
      nameArabic: AppDatabase.readString(r['name_arabic']),
      nameUrdu: AppDatabase.readString(r['name_urdu']),
      regionUrdu: AppDatabase.readString(r['region_urdu']),
      latitude: AppDatabase.readDouble(r['latitude']),
      longitude: AppDatabase.readDouble(r['longitude']),
      historicalSignificanceUrdu: AppDatabase.readString(
        r['historical_significance_urdu'],
      ),
    );
  }
}
