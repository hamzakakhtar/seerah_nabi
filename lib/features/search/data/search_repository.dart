import 'package:seerat_un_nabi/core/constants/app_constants.dart';
import 'package:seerat_un_nabi/core/constants/route_names.dart';
import 'package:seerat_un_nabi/core/database/app_database.dart';
import 'package:seerat_un_nabi/features/search/domain/search_models.dart';
import 'package:seerat_un_nabi/shared/models/reliability_status.dart';
import 'package:sqflite/sqflite.dart';

/// Contract for querying Seerah content, claims, timeline events, primary
/// sources, historical locations, and pronunciation guides completely offline.
abstract interface class SearchRepository {
  Future<SearchResultsBundle> searchOffline({
    required String query,
    SearchCategory category = SearchCategory.all,
    ReliabilityStatus? reliabilityFilter,
    String languageCode = AppConstants.defaultLanguageCode,
  });
}

/// Offline-first SQLite (`sqflite`) implementation of [SearchRepository].
///
/// Normalizes Arabic diacritics (tashkeel) and common Arabic/Urdu letter
/// variants so unvoweled Urdu searches accurately match classical Arabic
/// names, places, and titles stored in SQLite.
final class SqliteSearchRepository implements SearchRepository {
  SqliteSearchRepository(this._db);

  final AppDatabase _db;

  static final RegExp _arabicDiacritics = RegExp(
    r'[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]',
  );

  @override
  Future<SearchResultsBundle> searchOffline({
    required String query,
    SearchCategory category = SearchCategory.all,
    ReliabilityStatus? reliabilityFilter,
    String languageCode = AppConstants.defaultLanguageCode,
  }) async {
    final normalizedQuery = _normalizeText(query);
    if (normalizedQuery.isEmpty) {
      return SearchResultsBundle.empty(
        query: query,
        selectedCategory: category,
        selectedReliability: reliabilityFilter,
      );
    }

    final db = await _db.database;
    final allMatches = <SearchResultItem>[];

    if (reliabilityFilter == null) {
      allMatches.addAll(
        await _searchChaptersAndSections(db, normalizedQuery, languageCode),
      );
    }

    allMatches.addAll(
      await _searchHistoricalClaims(
        db,
        normalizedQuery,
        languageCode,
        reliabilityFilter: reliabilityFilter,
      ),
    );

    allMatches.addAll(
      await _searchTimelineEvents(
        db,
        normalizedQuery,
        reliabilityFilter: reliabilityFilter,
      ),
    );

    if (reliabilityFilter == null) {
      allMatches.addAll(await _searchSources(db, normalizedQuery));
      allMatches.addAll(await _searchLocations(db, normalizedQuery));
      allMatches.addAll(await _searchPronunciations(db, normalizedQuery));
    }

    final counts = <SearchCategory, int>{};
    for (final item in allMatches) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }

    final filteredItems = category == SearchCategory.all
        ? allMatches
        : allMatches
            .where((item) => item.category == category)
            .toList(growable: false);

    return SearchResultsBundle(
      query: query,
      selectedCategory: category,
      selectedReliability: reliabilityFilter,
      items: List<SearchResultItem>.unmodifiable(filteredItems),
      categoryCounts: Map<SearchCategory, int>.unmodifiable(counts),
    );
  }

  Future<List<SearchResultItem>> _searchChaptersAndSections(
    Database db,
    String normalizedQuery,
    String languageCode,
  ) async {
    final chapterRows = await db.query('chapters', orderBy: 'order_index ASC');
    if (chapterRows.isEmpty) return const <SearchResultItem>[];

    final chapterTrRows = await db.query(
      'chapter_translations',
      where: 'language_code = ?',
      whereArgs: [languageCode],
    );
    final fallbackChapterTrRows =
        languageCode == AppConstants.defaultLanguageCode
            ? chapterTrRows
            : await db.query(
                'chapter_translations',
                where: 'language_code = ?',
                whereArgs: [AppConstants.defaultLanguageCode],
              );

    final chapterTrMap = <String, Map<String, Object?>>{
      for (final tr in fallbackChapterTrRows)
        AppDatabase.readString(tr['chapter_stable_id']): tr,
      for (final tr in chapterTrRows)
        AppDatabase.readString(tr['chapter_stable_id']): tr,
    };

    final sectionRows = await db.query('sections', orderBy: 'order_index ASC');
    final sectionTrRows = await db.query(
      'section_translations',
      where: 'language_code = ?',
      whereArgs: [languageCode],
    );
    final fallbackSectionTrRows =
        languageCode == AppConstants.defaultLanguageCode
            ? sectionTrRows
            : await db.query(
                'section_translations',
                where: 'language_code = ?',
                whereArgs: [AppConstants.defaultLanguageCode],
              );

    final sectionTitleMap = <String, String>{
      for (final tr in fallbackSectionTrRows)
        AppDatabase.readString(tr['section_stable_id']):
            AppDatabase.readString(tr['title']),
      for (final tr in sectionTrRows)
        AppDatabase.readString(tr['section_stable_id']):
            AppDatabase.readString(tr['title']),
    };

    final sectionTitlesByChapter = <String, List<String>>{};
    for (final s in sectionRows) {
      final title = sectionTitleMap[AppDatabase.readString(s['stable_id'])];
      if (title != null && title.isNotEmpty) {
        sectionTitlesByChapter
            .putIfAbsent(
              AppDatabase.readString(s['chapter_stable_id']),
              () => <String>[],
            )
            .add(title);
      }
    }

    final results = <SearchResultItem>[];
    for (final row in chapterRows) {
      final stableId = AppDatabase.readString(row['stable_id']);
      final eraCode = AppDatabase.readString(row['era_code']);
      final routeKey = AppDatabase.readString(row['route_key']);
      final orderIndex = AppDatabase.readInt(row['order_index']);

      final tr = chapterTrMap[stableId];
      final title =
          tr != null ? AppDatabase.readString(tr['title'], stableId) : stableId;
      final subtitle = tr != null ? AppDatabase.readString(tr['subtitle']) : '';
      final eraLabel = tr != null
          ? AppDatabase.readString(tr['era_label'], eraCode)
          : eraCode;
      final summary = tr != null ? AppDatabase.readString(tr['summary']) : '';
      final sectionTitles =
          sectionTitlesByChapter[stableId] ?? const <String>[];

      final matchingSection = sectionTitles.cast<String?>().firstWhere(
            (s) => s != null && _matchesNormalized(s, normalizedQuery),
            orElse: () => null,
          );

      final matchesChapter = _matchesAny(
        [title, subtitle, eraLabel, summary],
        normalizedQuery,
      );

      if (!matchesChapter && matchingSection == null) {
        continue;
      }

      final routePath =
          routeKey.isNotEmpty ? routeKey : '/chapters/id/$stableId';

      final snippet = matchingSection != null && !matchesChapter
          ? 'متعلقہ ذیلی عنوان: $matchingSection'
          : (summary.isNotEmpty ? summary : subtitle);

      results.add(
        SearchResultItem(
          stableId: stableId,
          category: SearchCategory.chapters,
          title: title,
          subtitle: subtitle.isNotEmpty ? subtitle : eraLabel,
          snippet: snippet,
          routePath: routePath,
          badgeLabel: 'باب $orderIndex • $eraLabel',
        ),
      );
    }

    return results;
  }

  Future<List<SearchResultItem>> _searchHistoricalClaims(
    Database db,
    String normalizedQuery,
    String languageCode, {
    ReliabilityStatus? reliabilityFilter,
  }) async {
    final claimRows = await db.query(
      'historical_claims',
      where: reliabilityFilter != null ? 'reliability_status = ?' : null,
      whereArgs: reliabilityFilter != null
          ? [reliabilityFilter.storageValue]
          : null,
    );
    if (claimRows.isEmpty) return const <SearchResultItem>[];

    final claimTrRows = await db.query(
      'historical_claim_translations',
      where: 'language_code = ?',
      whereArgs: [languageCode],
    );
    final fallbackClaimTrRows =
        languageCode == AppConstants.defaultLanguageCode
            ? claimTrRows
            : await db.query(
                'historical_claim_translations',
                where: 'language_code = ?',
                whereArgs: [AppConstants.defaultLanguageCode],
              );

    final claimTrMap = <String, Map<String, Object?>>{
      for (final tr in fallbackClaimTrRows)
        AppDatabase.readString(tr['claim_stable_id']): tr,
      for (final tr in claimTrRows)
        AppDatabase.readString(tr['claim_stable_id']): tr,
    };

    final chapterTrRows = await db.query(
      'chapter_translations',
      where: 'language_code = ?',
      whereArgs: [languageCode],
    );
    final fallbackChapterTrRows =
        languageCode == AppConstants.defaultLanguageCode
            ? chapterTrRows
            : await db.query(
                'chapter_translations',
                where: 'language_code = ?',
                whereArgs: [AppConstants.defaultLanguageCode],
              );
    final chapterTitleMap = <String, String>{
      for (final tr in fallbackChapterTrRows)
        AppDatabase.readString(tr['chapter_stable_id']):
            AppDatabase.readString(tr['title']),
      for (final tr in chapterTrRows)
        AppDatabase.readString(tr['chapter_stable_id']):
            AppDatabase.readString(tr['title']),
    };

    final results = <SearchResultItem>[];
    for (final claim in claimRows) {
      final claimId = AppDatabase.readString(claim['stable_id']);
      final chapterId = AppDatabase.readString(claim['chapter_stable_id']);
      final reason = AppDatabase.readString(claim['classification_reason']);
      final assessment = AppDatabase.readString(claim['scholarly_assessment']);

      final tr = claimTrMap[claimId];
      final claimText =
          tr != null ? AppDatabase.readString(tr['claim_text']) : '';
      final explanationNote =
          tr != null ? AppDatabase.readString(tr['explanation_note']) : '';

      final matches = _matchesAny(
        [
          claimText,
          explanationNote,
          reason,
          assessment,
        ],
        normalizedQuery,
      );
      if (!matches) continue;

      final status = ReliabilityStatus.fromStorage(
        AppDatabase.readString(claim['reliability_status']),
      );
      final chapterTitle = chapterTitleMap[chapterId] ?? chapterId;

      results.add(
        SearchResultItem(
          stableId: claimId,
          category: SearchCategory.claims,
          title: _truncateSnippet(claimText, maxLength: 110),
          subtitle: chapterTitle,
          snippet: explanationNote.isNotEmpty ? explanationNote : reason,
          routePath: '${RouteNames.evidenceExplorer}?claimId=$claimId',
          reliabilityStatus: status,
          badgeLabel: status.urduLabel,
        ),
      );
    }

    return results;
  }

  Future<List<SearchResultItem>> _searchTimelineEvents(
    Database db,
    String normalizedQuery, {
    ReliabilityStatus? reliabilityFilter,
  }) async {
    final rows = await db.query(
      'timeline_events',
      where: reliabilityFilter != null ? 'reliability_status = ?' : null,
      whereArgs: reliabilityFilter != null
          ? [reliabilityFilter.storageValue]
          : null,
      orderBy: 'order_index ASC',
    );
    final results = <SearchResultItem>[];
    for (final row in rows) {
      final hijriYear = AppDatabase.readNullableInt(row['hijri_year']);
      final gregorianYear = AppDatabase.readNullableInt(row['gregorian_year']);
      final titleUrdu = AppDatabase.readString(row['title_urdu']);
      final summaryUrdu = AppDatabase.readString(row['summary_urdu']);
      final eraCode = AppDatabase.readString(row['era_code']);

      final hijriText = hijriYear != null ? '$hijriYear' : '';
      final gregorianText = gregorianYear != null ? '$gregorianYear' : '';

      final matches = _matchesAny(
        [
          titleUrdu,
          summaryUrdu,
          eraCode,
          hijriText,
          gregorianText,
        ],
        normalizedQuery,
      );
      if (!matches) continue;

      final yearBadge = _formatYearBadge(hijriYear, gregorianYear);
      results.add(
        SearchResultItem(
          stableId: AppDatabase.readString(row['stable_id']),
          category: SearchCategory.timeline,
          title: titleUrdu,
          subtitle: yearBadge.isNotEmpty ? yearBadge : 'زمانی خطِ سیر',
          snippet: summaryUrdu,
          routePath: RouteNames.timeline,
          reliabilityStatus: ReliabilityStatus.fromStorage(
            AppDatabase.readString(row['reliability_status']),
          ),
          badgeLabel: yearBadge.isNotEmpty ? yearBadge : null,
        ),
      );
    }

    return results;
  }

  Future<List<SearchResultItem>> _searchSources(
    Database db,
    String normalizedQuery,
  ) async {
    final sourceRows = await db.query('sources');
    if (sourceRows.isEmpty) return const <SearchResultItem>[];

    final refRows = await db.query('source_references');
    final refsBySource = <String, List<Map<String, Object?>>>{};
    for (final ref in refRows) {
      refsBySource
          .putIfAbsent(
            AppDatabase.readString(ref['source_stable_id']),
            () => <Map<String, Object?>>[],
          )
          .add(ref);
    }

    final results = <SearchResultItem>[];
    for (final source in sourceRows) {
      final stableId = AppDatabase.readString(source['stable_id']);
      final titleUrdu = AppDatabase.readString(source['title_urdu']);
      final titleArabic = AppDatabase.readString(source['title_arabic']);
      final authorUrdu = AppDatabase.readString(source['author_urdu']);
      final authorArabic = AppDatabase.readString(source['author_arabic']);
      final sourceType = AppDatabase.readString(source['source_type']);
      final tradition = AppDatabase.readString(source['tradition']);

      final refs = refsBySource[stableId] ?? const <Map<String, Object?>>[];
      final matchingRef = refs.cast<Map<String, Object?>?>().firstWhere(
            (r) =>
                r != null &&
                _matchesAny(
                  [
                    AppDatabase.readString(r['urdu_translation']),
                    AppDatabase.readString(r['original_arabic_excerpt']),
                  ],
                  normalizedQuery,
                ),
            orElse: () => null,
          );

      final matchesSource = _matchesAny(
        [
          titleUrdu,
          titleArabic,
          authorUrdu,
          authorArabic,
          sourceType,
        ],
        normalizedQuery,
      );

      if (!matchesSource && matchingRef == null) continue;

      final traditionLabel = switch (tradition) {
        'sunni' => 'سنی مآخذ',
        'shia' => 'شیعہ مآخذ',
        'classical_history' => 'قدیم تاریخ',
        _ => 'سیرت',
      };

      final refUrdu = matchingRef != null
          ? AppDatabase.readString(matchingRef['urdu_translation'])
          : '';
      final refArabic = matchingRef != null
          ? AppDatabase.readString(matchingRef['original_arabic_excerpt'])
          : '';

      final snippet = matchingRef != null && !matchesSource
          ? (refUrdu.isNotEmpty ? refUrdu : refArabic)
          : '$titleArabic — $authorArabic';

      results.add(
        SearchResultItem(
          stableId: stableId,
          category: SearchCategory.sources,
          title: titleUrdu,
          subtitle: authorUrdu,
          snippet: snippet,
          routePath: '${RouteNames.sourceViewer}?sourceId=$stableId',
          badgeLabel: traditionLabel,
        ),
      );
    }

    return results;
  }

  Future<List<SearchResultItem>> _searchLocations(
    Database db,
    String normalizedQuery,
  ) async {
    final rows = await db.query('historical_locations');
    final results = <SearchResultItem>[];
    for (final row in rows) {
      final nameUrdu = AppDatabase.readString(row['name_urdu']);
      final nameArabic = AppDatabase.readString(row['name_arabic']);
      final regionUrdu = AppDatabase.readString(row['region_urdu']);
      final significance = AppDatabase.readString(
        row['historical_significance_urdu'],
      );
      final stableId = AppDatabase.readString(row['stable_id']);

      final matches = _matchesAny(
        [
          nameUrdu,
          nameArabic,
          regionUrdu,
          significance,
        ],
        normalizedQuery,
      );
      if (!matches) continue;

      results.add(
        SearchResultItem(
          stableId: stableId,
          category: SearchCategory.locations,
          title: '$nameUrdu ($nameArabic)',
          subtitle: regionUrdu,
          snippet: significance,
          routePath: '${RouteNames.historicalMaps}?locationId=$stableId',
          badgeLabel: regionUrdu,
        ),
      );
    }
    return results;
  }

  Future<List<SearchResultItem>> _searchPronunciations(
    Database db,
    String normalizedQuery,
  ) async {
    final rows = await db.query('pronunciation_entries');
    final results = <SearchResultItem>[];
    for (final row in rows) {
      final termUrdu = AppDatabase.readString(row['term_urdu']);
      final termArabic = AppDatabase.readString(row['term_arabic']);
      final transliteration = AppDatabase.readString(row['transliteration']);
      final phoneticGuide = AppDatabase.readString(row['phonetic_guide']);
      final urduExplanation = AppDatabase.readString(row['urdu_explanation']);

      final matches = _matchesAny(
        [
          termUrdu,
          termArabic,
          transliteration,
          phoneticGuide,
          urduExplanation,
        ],
        normalizedQuery,
      );
      if (!matches) continue;

      results.add(
        SearchResultItem(
          stableId: AppDatabase.readString(row['stable_id']),
          category: SearchCategory.pronunciation,
          title: '$termArabic — $termUrdu',
          subtitle: 'صوتی تقسیم: $phoneticGuide ($transliteration)',
          snippet: urduExplanation,
          routePath: RouteNames.pronunciation,
          badgeLabel: transliteration,
        ),
      );
    }
    return results;
  }

  bool _matchesAny(List<String> fields, String normalizedQuery) {
    for (final field in fields) {
      if (_matchesNormalized(field, normalizedQuery)) {
        return true;
      }
    }
    return false;
  }

  bool _matchesNormalized(String candidate, String normalizedQuery) {
    if (candidate.isEmpty) return false;
    return _normalizeText(candidate).contains(normalizedQuery);
  }

  String _normalizeText(String input) {
    final trimmed = input.trim().toLowerCase();
    if (trimmed.isEmpty) return '';

    final withoutDiacritics = trimmed.replaceAll(_arabicDiacritics, '');
    final buffer = StringBuffer();
    for (var i = 0; i < withoutDiacritics.length; i++) {
      final char = withoutDiacritics[i];
      switch (char) {
        case 'أ':
        case 'إ':
        case 'آ':
        case 'ٱ':
          buffer.write('ا');
        case 'ي':
        case 'ى':
        case 'ئ':
          buffer.write('ی');
        case 'ك':
          buffer.write('ک');
        case 'ة':
        case 'ھ':
        case 'ه':
          buffer.write('ہ');
        case 'ؤ':
          buffer.write('و');
        default:
          buffer.write(char);
      }
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _formatYearBadge(int? hijriYear, int? gregorianYear) {
    final parts = <String>[];
    if (hijriYear != null) {
      parts.add(
        hijriYear < 0 ? '${hijriYear.abs()} قبل ہجرت' : '$hijriYear ہجری',
      );
    }
    if (gregorianYear != null) {
      parts.add('$gregorianYear عیسوی');
    }
    return parts.join(' • ');
  }

  String _truncateSnippet(String text, {int maxLength = 120}) {
    final cleaned = text.trim();
    if (cleaned.length <= maxLength) return cleaned;
    return '${cleaned.substring(0, maxLength)}…';
  }
}
