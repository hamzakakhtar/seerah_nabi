import 'package:flutter/foundation.dart';

/// Result summary for future cloud synchronization cycles.
@immutable
class SyncResult {
  const SyncResult({
    required this.syncedAt,
    required this.updatedRecordsCount,
    required this.isOfflineSkipped,
  });

  final DateTime syncedAt;
  final int updatedRecordsCount;
  final bool isOfflineSkipped;
}

/// Architectural contract for future cloud synchronization of user study data
/// (bookmarks, personal notes, reading progress) and verified research updates.
///
/// Offline-first: all read/write operations always target local SQLite first.
abstract interface class CloudSyncService {
  Future<SyncResult> syncUserStudyData();

  Future<SyncResult> pullVerifiedResearchUpdates({
    required String currentVersionTag,
  });
}

/// Offline-safe implementation used until remote sync endpoints are configured.
final class OfflineNoOpCloudSyncService implements CloudSyncService {
  const OfflineNoOpCloudSyncService();

  @override
  Future<SyncResult> syncUserStudyData() async {
    return SyncResult(
      syncedAt: DateTime.now(),
      updatedRecordsCount: 0,
      isOfflineSkipped: true,
    );
  }

  @override
  Future<SyncResult> pullVerifiedResearchUpdates({
    required String currentVersionTag,
  }) async {
    return SyncResult(
      syncedAt: DateTime.now(),
      updatedRecordsCount: 0,
      isOfflineSkipped: true,
    );
  }
}
