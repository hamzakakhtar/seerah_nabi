import 'package:flutter/foundation.dart';
import 'package:seerat_un_nabi/features/evidence_explorer/domain/evidence_models.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/domain/chapter_models.dart';

/// Complete research bundle pairing an individual historical claim with
/// its primary source references, narrations, and narrator evaluations.
@immutable
class ClaimEvidenceBundle {
  const ClaimEvidenceBundle({
    required this.claim,
    required this.evidenceList,
  });

  final HistoricalClaimModel claim;
  final List<ClaimEvidenceModel> evidenceList;
}
