import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/features/search/domain/search_models.dart';
import 'package:seerat_un_nabi/shared/models/reading_settings.dart';
import 'package:seerat_un_nabi/shared/models/reliability_status.dart';
import 'package:seerat_un_nabi/shared/providers/reading_settings_provider.dart';
import 'package:seerat_un_nabi/shared/providers/repository_providers.dart';

/// Filter state for the offline Seerah search screen.
@immutable
class SearchFilterState {
  const SearchFilterState({
    this.query = '',
    this.category = SearchCategory.all,
    this.reliabilityFilter,
  });

  final String query;
  final SearchCategory category;
  final ReliabilityStatus? reliabilityFilter;

  SearchFilterState copyWith({
    String? query,
    SearchCategory? category,
    ReliabilityStatus? reliabilityFilter,
    bool clearReliabilityFilter = false,
  }) {
    return SearchFilterState(
      query: query ?? this.query,
      category: category ?? this.category,
      reliabilityFilter: clearReliabilityFilter
          ? null
          : (reliabilityFilter ?? this.reliabilityFilter),
    );
  }
}

final searchFilterProvider =
    NotifierProvider<SearchFilterNotifier, SearchFilterState>(
  SearchFilterNotifier.new,
);

class SearchFilterNotifier extends Notifier<SearchFilterState> {
  @override
  SearchFilterState build() => const SearchFilterState();

  void updateQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setCategory(SearchCategory category) {
    final shouldClearReliability = category != SearchCategory.all &&
        category != SearchCategory.claims &&
        category != SearchCategory.timeline;
    state = state.copyWith(
      category: category,
      clearReliabilityFilter: shouldClearReliability,
    );
  }

  void setReliabilityFilter(ReliabilityStatus? status) {
    if (status == null) {
      state = state.copyWith(clearReliabilityFilter: true);
    } else {
      state = state.copyWith(reliabilityFilter: status);
    }
  }

  void resetAll() {
    state = const SearchFilterState();
  }
}

/// Executes offline SQLite searches reactive to query, category, reliability,
/// and active reading locale.
final searchResultsProvider =
    FutureProvider.autoDispose<SearchResultsBundle>((ref) async {
  await ref.watch(databaseInitializerProvider.future);
  final filter = ref.watch(searchFilterProvider);
  final locale = ref.watch(
    readingSettingsProvider.select((ReadingSettings settings) => settings.locale),
  );

  return ref.watch(searchRepositoryProvider).searchOffline(
        query: filter.query,
        category: filter.category,
        reliabilityFilter: filter.reliabilityFilter,
        languageCode: locale.languageCode,
      );
});
