import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/core/database/app_database.dart';

/// Singleton lifecycle-managed SQLite [AppDatabase] provider.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
