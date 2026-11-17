import 'package:flutter/foundation.dart';
import 'package:seerat_un_nabi/shared/models/reliability_status.dart';

/// Filter categories for offline SQLite Seerah search.
enum SearchCategory {
  all,
  chapters,
  claims,
  timeline,
  sources,
  locations,
  pronunciation;

  String get urduLabel => switch (this) {
        SearchCategory.all => 'تمام نتائج',
        SearchCategory.chapters => 'ابواب و متن',
        SearchCategory.claims => 'تاریخی بیانات',
        SearchCategory.timeline => 'زمانی خطِ سیر',
        SearchCategory.sources => 'مآخذ و کتب',
        SearchCategory.locations => 'تاریخی مقامات',
        SearchCategory.pronunciation => 'تلفظ رہنما',
      };
}

/// A single unified search hit produced strictly from local SQLite records.
@immutable
class SearchResultItem {
  const SearchResultItem({
    required this.stableId,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.snippet,
    required this.routePath,
    this.reliabilityStatus,
    this.badgeLabel,
  });

  final String stableId;
  final SearchCategory category;
  final String title;
  final String subtitle;
  final String snippet;
  final String routePath;
  final ReliabilityStatus? reliabilityStatus;
  final String? badgeLabel;
}

/// Aggregated offline search output including per-category match counts.
@immutable
class SearchResultsBundle {
  const SearchResultsBundle({
    required this.query,
    required this.selectedCategory,
    required this.items,
    required this.categoryCounts,
    this.selectedReliability,
  });

  const SearchResultsBundle.empty({
    this.query = '',
    this.selectedCategory = SearchCategory.all,
    this.selectedReliability,
  })  : items = const <SearchResultItem>[],
        categoryCounts = const <SearchCategory, int>{};

  final String query;
  final SearchCategory selectedCategory;
  final ReliabilityStatus? selectedReliability;
  final List<SearchResultItem> items;
  final Map<SearchCategory, int> categoryCounts;

  int countFor(SearchCategory category) {
    if (category == SearchCategory.all) {
      return categoryCounts.values.fold<int>(0, (sum, count) => sum + count);
    }
    return categoryCounts[category] ?? 0;
  }
}
