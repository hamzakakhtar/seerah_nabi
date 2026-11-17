import 'package:seerat_un_nabi/core/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

AppDatabase createTestDatabase() {
  sqfliteFfiInit();
  return AppDatabase.forTesting(databaseFactory: databaseFactoryFfiNoIsolate);
}
