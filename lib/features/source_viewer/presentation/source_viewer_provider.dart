import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/features/evidence_explorer/domain/evidence_models.dart';
import 'package:seerat_un_nabi/shared/providers/repository_providers.dart';

final sourceTraditionFilterProvider =
    NotifierProvider<SourceTraditionFilterNotifier, SourceTradition?>(
  SourceTraditionFilterNotifier.new,
);

class SourceTraditionFilterNotifier extends Notifier<SourceTradition?> {
  @override
  SourceTradition? build() => null;

  void setTradition(SourceTradition? tradition) {
    state = tradition;
  }
}

final sourcesListProvider = FutureProvider<List<SourceModel>>((ref) async {
  await ref.watch(databaseInitializerProvider.future);
  final tradition = ref.watch(sourceTraditionFilterProvider);
  final all = await ref.watch(evidenceRepositoryProvider).getAllSources();
  if (tradition == null) return all;
  return all.where((s) => s.tradition == tradition).toList(growable: false);
});

final sourceReferencesProvider =
    FutureProvider.family<List<SourceReferenceModel>, String>(
  (ref, sourceStableId) async {
    await ref.watch(databaseInitializerProvider.future);
    return ref
        .watch(evidenceRepositoryProvider)
        .getReferencesForSource(sourceStableId);
  },
);
