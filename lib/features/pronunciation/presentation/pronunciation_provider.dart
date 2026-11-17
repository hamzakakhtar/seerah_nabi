import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/features/pronunciation/domain/pronunciation_entry_model.dart';
import 'package:seerat_un_nabi/shared/providers/repository_providers.dart';

final pronunciationSearchQueryProvider =
    NotifierProvider<PronunciationSearchQueryNotifier, String>(
  PronunciationSearchQueryNotifier.new,
);

class PronunciationSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }
}

final pronunciationEntriesProvider =
    FutureProvider<List<PronunciationEntryModel>>((ref) async {
  await ref.watch(databaseInitializerProvider.future);
  final query = ref.watch(pronunciationSearchQueryProvider);
  return ref
      .watch(pronunciationRepositoryProvider)
      .getPronunciationEntries(searchQuery: query);
});
