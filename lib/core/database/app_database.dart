import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:seerat_un_nabi/core/constants/app_constants.dart';
import 'package:sqflite/sqflite.dart';

/// Normalized offline-first SQLite database (`sqflite`) for Seerat-un-Nabi ﷺ.
///
/// Supports hundreds of chapters, multilingual content keyed by immutable
/// stable IDs, individual claim reliability tracking, primary evidence,
/// smart reading progress, and scholarly governance without any code generation.
class AppDatabase {
  AppDatabase()
      : _inMemory = false,
        _databaseFactory = null;

  /// Constructor for in-memory unit & widget tests (`sqflite_common_ffi`).
  AppDatabase.forTesting({DatabaseFactory? databaseFactory})
      : _inMemory = true,
        _databaseFactory = databaseFactory;

  final bool _inMemory;
  final DatabaseFactory? _databaseFactory;
  Database? _db;
  Future<Database>? _openingFuture;

  Future<Database> get database {
    final existing = _db;
    if (existing != null) {
      return Future<Database>.value(existing);
    }
    return _openingFuture ??= _open();
  }

  Future<void> close() async {
    final opening = _openingFuture;
    if (opening != null && _db == null) {
      try {
        final opened = await opening;
        await opened.close();
      } catch (_) {}
    } else if (_db != null) {
      await _db!.close();
    }
    _db = null;
    _openingFuture = null;
  }

  Future<Database> _open() async {
    final options = OpenDatabaseOptions(
      version: AppConstants.databaseSchemaVersion,
      singleInstance: !_inMemory,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (Database db, int version) async {
        await _createSchema(db);
        await _createPerformanceIndexes(db);
        await _seedInitialMetadata(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        // Structured migration path for future schema versions.
      },
    );

    final Database opened;
    if (_inMemory) {
      final factory = _databaseFactory ?? databaseFactory;
      opened = await factory.openDatabase(inMemoryDatabasePath, options: options);
    } else {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dbFolder.path, AppConstants.databaseFileName);
      final factory = _databaseFactory;
      if (factory != null) {
        opened = await factory.openDatabase(dbPath, options: options);
      } else {
        opened = await openDatabase(
          dbPath,
          version: options.version,
          singleInstance: options.singleInstance,
          onConfigure: options.onConfigure,
          onCreate: options.onCreate,
          onUpgrade: options.onUpgrade,
        );
      }
    }

    _db = opened;
    return opened;
  }

  Future<void> _createSchema(Database db) async {
    const statements = <String>[
      '''
      CREATE TABLE IF NOT EXISTS languages (
        code TEXT NOT NULL PRIMARY KEY,
        name_native TEXT NOT NULL,
        name_english TEXT NOT NULL,
        direction TEXT NOT NULL DEFAULT 'rtl',
        is_active INTEGER NOT NULL DEFAULT 1
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS chapters (
        stable_id TEXT NOT NULL PRIMARY KEY,
        order_index INTEGER NOT NULL,
        era_code TEXT NOT NULL,
        route_key TEXT NOT NULL,
        is_published INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER) * 1000),
        updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER) * 1000)
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS chapter_translations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_stable_id TEXT NOT NULL REFERENCES chapters(stable_id) ON DELETE CASCADE,
        language_code TEXT NOT NULL REFERENCES languages(code) ON DELETE RESTRICT,
        title TEXT NOT NULL,
        subtitle TEXT NOT NULL DEFAULT '',
        era_label TEXT NOT NULL,
        summary TEXT NOT NULL DEFAULT '',
        UNIQUE(chapter_stable_id, language_code)
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS sections (
        stable_id TEXT NOT NULL PRIMARY KEY,
        chapter_stable_id TEXT NOT NULL REFERENCES chapters(stable_id) ON DELETE CASCADE,
        order_index INTEGER NOT NULL
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS section_translations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        section_stable_id TEXT NOT NULL REFERENCES sections(stable_id) ON DELETE CASCADE,
        language_code TEXT NOT NULL REFERENCES languages(code) ON DELETE RESTRICT,
        title TEXT NOT NULL,
        UNIQUE(section_stable_id, language_code)
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS paragraphs (
        stable_id TEXT NOT NULL PRIMARY KEY,
        section_stable_id TEXT NOT NULL REFERENCES sections(stable_id) ON DELETE CASCADE,
        chapter_stable_id TEXT NOT NULL REFERENCES chapters(stable_id) ON DELETE CASCADE,
        order_index INTEGER NOT NULL,
        is_daily_eligible INTEGER NOT NULL DEFAULT 0
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS paragraph_translations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        paragraph_stable_id TEXT NOT NULL REFERENCES paragraphs(stable_id) ON DELETE CASCADE,
        language_code TEXT NOT NULL REFERENCES languages(code) ON DELETE RESTRICT,
        plain_text TEXT NOT NULL,
        UNIQUE(paragraph_stable_id, language_code)
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS historical_claims (
        stable_id TEXT NOT NULL PRIMARY KEY,
        paragraph_stable_id TEXT NOT NULL REFERENCES paragraphs(stable_id) ON DELETE CASCADE,
        chapter_stable_id TEXT NOT NULL REFERENCES chapters(stable_id) ON DELETE CASCADE,
        order_in_paragraph INTEGER NOT NULL,
        reliability_status TEXT NOT NULL,
        classification_reason TEXT NOT NULL,
        scholarly_assessment TEXT NOT NULL DEFAULT '',
        is_chronologically_verified INTEGER NOT NULL DEFAULT 0,
        research_version_id INTEGER
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS historical_claim_translations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        claim_stable_id TEXT NOT NULL REFERENCES historical_claims(stable_id) ON DELETE CASCADE,
        language_code TEXT NOT NULL REFERENCES languages(code) ON DELETE RESTRICT,
        claim_text TEXT NOT NULL,
        explanation_note TEXT NOT NULL DEFAULT '',
        UNIQUE(claim_stable_id, language_code)
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS sources (
        stable_id TEXT NOT NULL PRIMARY KEY,
        title_arabic TEXT NOT NULL,
        title_urdu TEXT NOT NULL,
        author_arabic TEXT NOT NULL,
        author_urdu TEXT NOT NULL,
        tradition TEXT NOT NULL,
        author_death_hijri INTEGER,
        source_type TEXT NOT NULL
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS source_references (
        stable_id TEXT NOT NULL PRIMARY KEY,
        source_stable_id TEXT NOT NULL REFERENCES sources(stable_id) ON DELETE CASCADE,
        volume TEXT NOT NULL DEFAULT '',
        page_number TEXT NOT NULL DEFAULT '',
        section_or_hadith_number TEXT NOT NULL DEFAULT '',
        original_arabic_excerpt TEXT NOT NULL DEFAULT '',
        urdu_translation TEXT NOT NULL DEFAULT ''
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS narrators (
        stable_id TEXT NOT NULL PRIMARY KEY,
        name_arabic TEXT NOT NULL,
        name_urdu TEXT NOT NULL,
        death_hijri INTEGER,
        scholarly_grading TEXT NOT NULL DEFAULT '',
        biographical_note TEXT NOT NULL DEFAULT ''
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS narrations (
        stable_id TEXT NOT NULL PRIMARY KEY,
        source_reference_stable_id TEXT NOT NULL REFERENCES source_references(stable_id) ON DELETE CASCADE,
        matn_arabic TEXT NOT NULL,
        urdu_summary TEXT NOT NULL,
        isnad_chain_summary TEXT NOT NULL DEFAULT '',
        hadith_grade TEXT NOT NULL DEFAULT '',
        historical_weight_note TEXT NOT NULL DEFAULT '',
        tradition TEXT NOT NULL
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS narration_narrators (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        narration_stable_id TEXT NOT NULL REFERENCES narrations(stable_id) ON DELETE CASCADE,
        narrator_stable_id TEXT NOT NULL REFERENCES narrators(stable_id) ON DELETE CASCADE,
        chain_position INTEGER NOT NULL
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS claim_evidence (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        claim_stable_id TEXT NOT NULL REFERENCES historical_claims(stable_id) ON DELETE CASCADE,
        source_reference_stable_id TEXT NOT NULL REFERENCES source_references(stable_id) ON DELETE CASCADE,
        narration_stable_id TEXT REFERENCES narrations(stable_id) ON DELETE SET NULL,
        evidence_role TEXT NOT NULL,
        notes_urdu TEXT NOT NULL DEFAULT ''
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS event_cross_references (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_entity_id TEXT NOT NULL,
        target_entity_id TEXT NOT NULL,
        target_type TEXT NOT NULL,
        relation_type TEXT NOT NULL,
        description_urdu TEXT NOT NULL DEFAULT ''
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS timeline_events (
        stable_id TEXT NOT NULL PRIMARY KEY,
        chapter_stable_id TEXT NOT NULL REFERENCES chapters(stable_id) ON DELETE CASCADE,
        claim_stable_id TEXT REFERENCES historical_claims(stable_id) ON DELETE SET NULL,
        hijri_year INTEGER,
        gregorian_year INTEGER,
        era_code TEXT NOT NULL,
        order_index INTEGER NOT NULL,
        title_urdu TEXT NOT NULL,
        summary_urdu TEXT NOT NULL,
        reliability_status TEXT NOT NULL
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS historical_locations (
        stable_id TEXT NOT NULL PRIMARY KEY,
        name_arabic TEXT NOT NULL,
        name_urdu TEXT NOT NULL,
        region_urdu TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        historical_significance_urdu TEXT NOT NULL DEFAULT ''
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS event_locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timeline_event_stable_id TEXT NOT NULL REFERENCES timeline_events(stable_id) ON DELETE CASCADE,
        location_stable_id TEXT NOT NULL REFERENCES historical_locations(stable_id) ON DELETE CASCADE
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_stable_id TEXT NOT NULL REFERENCES chapters(stable_id) ON DELETE CASCADE,
        section_stable_id TEXT,
        paragraph_stable_id TEXT,
        title_urdu TEXT NOT NULL,
        created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER) * 1000)
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS reading_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_stable_id TEXT NOT NULL UNIQUE REFERENCES chapters(stable_id) ON DELETE CASCADE,
        section_stable_id TEXT,
        paragraph_stable_id TEXT,
        scroll_offset REAL NOT NULL DEFAULT 0.0,
        completion_fraction REAL NOT NULL DEFAULT 0.0,
        is_last_active INTEGER NOT NULL DEFAULT 1,
        updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER) * 1000)
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS reading_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_stable_id TEXT NOT NULL REFERENCES chapters(stable_id) ON DELETE CASCADE,
        started_at INTEGER NOT NULL,
        ended_at INTEGER,
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        paragraphs_read INTEGER NOT NULL DEFAULT 0
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS personal_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_stable_id TEXT NOT NULL REFERENCES chapters(stable_id) ON DELETE CASCADE,
        paragraph_stable_id TEXT REFERENCES paragraphs(stable_id) ON DELETE SET NULL,
        claim_stable_id TEXT REFERENCES historical_claims(stable_id) ON DELETE SET NULL,
        note_text TEXT NOT NULL,
        created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER) * 1000),
        updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER) * 1000)
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS pronunciation_entries (
        stable_id TEXT NOT NULL PRIMARY KEY,
        term_arabic TEXT NOT NULL,
        term_urdu TEXT NOT NULL,
        transliteration TEXT NOT NULL,
        phonetic_guide TEXT NOT NULL,
        urdu_explanation TEXT NOT NULL DEFAULT ''
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS research_versions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        version_tag TEXT NOT NULL,
        chapter_stable_id TEXT REFERENCES chapters(stable_id) ON DELETE SET NULL,
        change_summary_urdu TEXT NOT NULL,
        revised_by TEXT NOT NULL,
        created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER) * 1000)
      );
      ''',
      '''
      CREATE TABLE IF NOT EXISTS scholar_reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_stable_id TEXT NOT NULL REFERENCES chapters(stable_id) ON DELETE CASCADE,
        reviewer_name TEXT NOT NULL,
        credentials TEXT NOT NULL DEFAULT '',
        review_status TEXT NOT NULL,
        notes_urdu TEXT NOT NULL DEFAULT '',
        reviewed_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER) * 1000)
      );
      ''',
    ];

    for (final sql in statements) {
      await db.execute(sql);
    }
  }

  Future<void> _createPerformanceIndexes(Database db) async {
    const indexStatements = <String>[
      'CREATE INDEX IF NOT EXISTS idx_chapters_order ON chapters(order_index);',
      'CREATE INDEX IF NOT EXISTS idx_sections_chapter ON sections(chapter_stable_id, order_index);',
      'CREATE INDEX IF NOT EXISTS idx_paragraphs_section ON paragraphs(section_stable_id, order_index);',
      'CREATE INDEX IF NOT EXISTS idx_claims_paragraph ON historical_claims(paragraph_stable_id, order_in_paragraph);',
      'CREATE INDEX IF NOT EXISTS idx_claims_status ON historical_claims(reliability_status);',
      'CREATE INDEX IF NOT EXISTS idx_evidence_claim ON claim_evidence(claim_stable_id);',
      'CREATE INDEX IF NOT EXISTS idx_timeline_order ON timeline_events(order_index);',
      'CREATE INDEX IF NOT EXISTS idx_bookmarks_chapter ON bookmarks(chapter_stable_id);',
      'CREATE INDEX IF NOT EXISTS idx_notes_chapter ON personal_notes(chapter_stable_id);',
    ];
    for (final sql in indexStatements) {
      await db.execute(sql);
    }
  }

  /// Seeds language metadata including Urdu, Pashto, Arabic, Persian, and English.
  Future<void> _seedInitialMetadata(Database db) async {
    final batch = db.batch();
    const languages = <Map<String, Object?>>[
      {
        'code': 'ur',
        'name_native': 'اردو',
        'name_english': 'Urdu',
        'direction': 'rtl',
        'is_active': 1,
      },
      {
        'code': 'ps',
        'name_native': 'پښتو',
        'name_english': 'Pashto',
        'direction': 'rtl',
        'is_active': 1,
      },
      {
        'code': 'ar',
        'name_native': 'العربية',
        'name_english': 'Arabic',
        'direction': 'rtl',
        'is_active': 1,
      },
      {
        'code': 'en',
        'name_native': 'English',
        'name_english': 'English',
        'direction': 'ltr',
        'is_active': 1,
      },
      {
        'code': 'fa',
        'name_native': 'فارسی',
        'name_english': 'Persian',
        'direction': 'rtl',
        'is_active': 1,
      },
    ];
    for (final row in languages) {
      batch.insert(
        'languages',
        row,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  static bool readBool(Object? value) => value == 1 || value == true;

  static int readInt(Object? value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  static int? readNullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  static double readDouble(Object? value, [double fallback = 0.0]) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return fallback;
  }

  static String readString(Object? value, [String fallback = '']) {
    return value is String ? value : fallback;
  }

  static String? readNullableString(Object? value) {
    return value is String ? value : null;
  }

  static DateTime readDateTime(Object? value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static DateTime? readNullableDateTime(Object? value) {
    if (value == null) return null;
    return readDateTime(value);
  }

  static String placeholders(int count) =>
      List<String>.filled(count, '?').join(', ');
}
