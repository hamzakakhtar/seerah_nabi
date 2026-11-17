import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/features/evidence_explorer/domain/evidence_models.dart';
import 'package:seerat_un_nabi/shared/providers/repository_providers.dart';

final narrationTraditionFilterProvider =
    NotifierProvider<NarrationTraditionFilterNotifier, SourceTradition?>(
  NarrationTraditionFilterNotifier.new,
);

class NarrationTraditionFilterNotifier extends Notifier<SourceTradition?> {
  @override
  SourceTradition? build() => null;

  void setTradition(SourceTradition? tradition) {
    state = tradition;
  }
}

final narrationsListProvider = FutureProvider<List<NarrationModel>>((ref) async {
  await ref.watch(databaseInitializerProvider.future);
  final tradition = ref.watch(narrationTraditionFilterProvider);
  return ref
      .watch(evidenceRepositoryProvider)
      .getAllNarrations(tradition: tradition);
});

final comparedNarrationIdsProvider =
    NotifierProvider<ComparedNarrationIdsNotifier, List<String>>(
  ComparedNarrationIdsNotifier.new,
);

class ComparedNarrationIdsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => const <String>[];

  void toggleSelection(String narrationStableId) {
    if (state.contains(narrationStableId)) {
      state = state
          .where((id) => id != narrationStableId)
          .toList(growable: false);
      return;
    }
    if (state.length >= 2) {
      state = <String>[state.last, narrationStableId];
    } else {
      state = <String>[...state, narrationStableId];
    }
  }

  void clear() {
    state = const <String>[];
  }
}
