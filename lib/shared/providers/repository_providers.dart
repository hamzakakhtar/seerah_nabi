import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/core/database/database_provider.dart';
import 'package:seerat_un_nabi/core/database/seed/seerah_database_seeder.dart';
import 'package:seerat_un_nabi/core/sync/cloud_sync_service.dart';
import 'package:seerat_un_nabi/features/bookmarks/data/bookmark_repository.dart';
import 'package:seerat_un_nabi/features/daily_seerah/data/daily_seerah_repository.dart';
import 'package:seerat_un_nabi/features/evidence_explorer/data/evidence_repository.dart';
import 'package:seerat_un_nabi/features/historical_maps/data/historical_location_repository.dart';
import 'package:seerat_un_nabi/features/personal_notes/data/personal_note_repository.dart';
import 'package:seerat_un_nabi/features/pronunciation/data/pronunciation_repository.dart';
import 'package:seerat_un_nabi/features/reading_progress/data/reading_progress_repository.dart';
import 'package:seerat_un_nabi/features/research_history/data/research_governance_repository.dart';
import 'package:seerat_un_nabi/features/search/data/search_repository.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/data/chapter_repository.dart';
import 'package:seerat_un_nabi/features/seerah_timeline/data/timeline_repository.dart';

/// Ensures initial researched Urdu Seerah chapters and sources are seeded
/// once into local SQLite before any UI reads from repositories.
final databaseInitializerProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  await SeerahDatabaseSeeder(db).seedInitialContentIfEmpty();
});

/// Centralized Riverpod dependency injection for all SQLite repositories
/// and offline-first sync contracts.
final chapterRepositoryProvider = Provider<ChapterRepository>((ref) {
  return SqliteChapterRepository(ref.watch(appDatabaseProvider));
});

final evidenceRepositoryProvider = Provider<EvidenceRepository>((ref) {
  return SqliteEvidenceRepository(ref.watch(appDatabaseProvider));
});

final readingProgressRepositoryProvider =
    Provider<ReadingProgressRepository>((ref) {
  return SqliteReadingProgressRepository(ref.watch(appDatabaseProvider));
});

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return SqliteBookmarkRepository(ref.watch(appDatabaseProvider));
});

final personalNoteRepositoryProvider = Provider<PersonalNoteRepository>((ref) {
  return SqlitePersonalNoteRepository(ref.watch(appDatabaseProvider));
});

final timelineRepositoryProvider = Provider<TimelineRepository>((ref) {
  return SqliteTimelineRepository(ref.watch(appDatabaseProvider));
});

final historicalLocationRepositoryProvider =
    Provider<HistoricalLocationRepository>((ref) {
  return SqliteHistoricalLocationRepository(ref.watch(appDatabaseProvider));
});

final pronunciationRepositoryProvider =
    Provider<PronunciationRepository>((ref) {
  return SqlitePronunciationRepository(ref.watch(appDatabaseProvider));
});

final dailySeerahRepositoryProvider = Provider<DailySeerahRepository>((ref) {
  return SqliteDailySeerahRepository(ref.watch(appDatabaseProvider));
});

final researchGovernanceRepositoryProvider =
    Provider<ResearchGovernanceRepository>((ref) {
  return SqliteResearchGovernanceRepository(ref.watch(appDatabaseProvider));
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SqliteSearchRepository(ref.watch(appDatabaseProvider));
});

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  return const OfflineNoOpCloudSyncService();
});
