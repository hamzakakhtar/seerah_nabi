/// Architectural contract for the offline-first SQLite database.
abstract interface class DatabaseContract {
  Future<void> initialize();

  Future<void> close();
}

/// Placeholder implementation for Phase 1 dependency wiring prior to Phase 2.
final class PhaseOneDatabasePlaceholder implements DatabaseContract {
  bool _initialized = false;

  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<void> close() async {
    _initialized = false;
  }
}
