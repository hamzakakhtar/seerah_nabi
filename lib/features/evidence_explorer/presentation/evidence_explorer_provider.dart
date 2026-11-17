import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/features/evidence_explorer/domain/evidence_explorer_state.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/domain/chapter_models.dart';
import 'package:seerat_un_nabi/shared/models/reading_settings.dart';
import 'package:seerat_un_nabi/shared/models/reliability_status.dart';
import 'package:seerat_un_nabi/shared/providers/reading_settings_provider.dart';
import 'package:seerat_un_nabi/shared/providers/repository_providers.dart';

final evidenceStatusFilterProvider =
    NotifierProvider<EvidenceStatusFilterNotifier, ReliabilityStatus?>(
  EvidenceStatusFilterNotifier.new,
);

class EvidenceStatusFilterNotifier extends Notifier<ReliabilityStatus?> {
  @override
  ReliabilityStatus? build() => null;

  void setStatus(ReliabilityStatus? status) {
    state = status;
  }
}

final evidenceClaimsProvider =
    FutureProvider<List<HistoricalClaimModel>>((ref) async {
  await ref.watch(databaseInitializerProvider.future);
  final status = ref.watch(evidenceStatusFilterProvider);
  final languageCode = ref.watch(
    readingSettingsProvider.select(
      (ReadingSettings s) => s.locale.languageCode,
    ),
  );
  return ref.watch(evidenceRepositoryProvider).getClaims(
        statusFilter: status,
        languageCode: languageCode,
      );
});

final claimEvidenceBundleProvider =
    FutureProvider.family<ClaimEvidenceBundle?, String>((ref, claimId) async {
  await ref.watch(databaseInitializerProvider.future);
  final languageCode = ref.watch(
    readingSettingsProvider.select(
      (ReadingSettings s) => s.locale.languageCode,
    ),
  );
  final repo = ref.watch(evidenceRepositoryProvider);
  final claim = await repo.getClaimById(claimId, languageCode: languageCode);
  if (claim == null) return null;
  final evidence = await repo.getEvidenceForClaim(claimId);
  return ClaimEvidenceBundle(claim: claim, evidenceList: evidence);
});
