import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/features/evidence_explorer/domain/evidence_explorer_state.dart';
import 'package:seerat_un_nabi/features/evidence_explorer/domain/evidence_models.dart';
import 'package:seerat_un_nabi/features/evidence_explorer/presentation/evidence_explorer_provider.dart';
import 'package:seerat_un_nabi/features/evidence_explorer/presentation/widgets/evidence_detail_card.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/domain/chapter_models.dart';
import 'package:seerat_un_nabi/shared/models/reliability_status.dart';
import 'package:seerat_un_nabi/shared/widgets/seerah_app_bar.dart';

/// Evidence Explorer screen allowing readers to inspect individual claim
/// evidence, filter all researched claims by reliability status, and examine
/// classical Sunni, Shia, and historical primary sources.
class EvidenceExplorerScreen extends ConsumerStatefulWidget {
  const EvidenceExplorerScreen({
    super.key,
    this.initialClaimId,
  });

  final String? initialClaimId;

  @override
  ConsumerState<EvidenceExplorerScreen> createState() =>
      _EvidenceExplorerScreenState();
}

class _EvidenceExplorerScreenState
    extends ConsumerState<EvidenceExplorerScreen> {
  String? _selectedClaimId;

  @override
  void initState() {
    super.initState();
    _selectedClaimId = widget.initialClaimId;
  }

  @override
  Widget build(BuildContext context) {
    final activeClaimId = _selectedClaimId;

    return Scaffold(
      appBar: SeerahAppBar(
        title: activeClaimId == null ? 'شواہد و اسناد' : 'تفصیلِ شواہد',
        actions: [
          if (activeClaimId != null)
            IconButton(
              tooltip: 'تمام دعوے دیکھیں',
              icon: const Icon(Icons.list_rounded),
              onPressed: () => setState(() => _selectedClaimId = null),
            ),
        ],
      ),
      body: activeClaimId != null
          ? _ClaimDetailView(
              claimId: activeClaimId,
              onBackToList: () => setState(() => _selectedClaimId = null),
            )
          : _ClaimsDirectoryView(
              onSelectClaim: (HistoricalClaimModel claim) =>
                  setState(() => _selectedClaimId = claim.stableId),
            ),
    );
  }
}

class _ClaimsDirectoryView extends ConsumerWidget {
  const _ClaimsDirectoryView({required this.onSelectClaim});

  final ValueChanged<HistoricalClaimModel> onSelectClaim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(evidenceStatusFilterProvider);
    final claimsAsync = ref.watch(evidenceClaimsProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('تمام دعوے'),
                selected: activeFilter == null,
                onSelected: (_) {
                  ref.read(evidenceStatusFilterProvider.notifier).setStatus(null);
                },
              ),
              const SizedBox(width: 8),
              ...ReliabilityStatus.values.map((ReliabilityStatus status) {
                final color = status.colorForBrightness(theme.brightness);
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    avatar: CircleAvatar(
                      backgroundColor: color,
                      radius: 6,
                    ),
                    label: Text(status.urduLabel),
                    selected: activeFilter == status,
                    onSelected: (_) {
                      ref
                          .read(evidenceStatusFilterProvider.notifier)
                          .setStatus(status);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        Expanded(
          child: claimsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Text(
                'شواہد لوڈ کرنے میں دشواری پیش آئی۔',
                style: theme.textTheme.bodyLarge,
              ),
            ),
            data: (List<HistoricalClaimModel> claims) {
              if (claims.isEmpty) {
                return Center(
                  child: Text(
                    'اس درجے میں کوئی تاریخی دعویٰ موجود نہیں۔',
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }
              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: claims.length,
                itemBuilder: (context, index) {
                  final claim = claims[index];
                  final statusColor =
                      claim.reliabilityStatus.colorForBrightness(theme.brightness);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onSelectClaim(claim),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  claim.reliabilityStatus.urduLabel,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: statusColor,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  claim.stableId,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              claim.claimText.trim(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              claim.classificationReason,
                              style: theme.textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ClaimDetailView extends ConsumerWidget {
  const _ClaimDetailView({
    required this.claimId,
    required this.onBackToList,
  });

  final String claimId;
  final VoidCallback onBackToList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundleAsync = ref.watch(claimEvidenceBundleProvider(claimId));
    final theme = Theme.of(context);

    return bundleAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(
          'تفصیل لوڈ کرنے میں دشواری پیش آئی۔',
          style: theme.textTheme.bodyLarge,
        ),
      ),
      data: (ClaimEvidenceBundle? bundle) {
        if (bundle == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'مطلوبہ دعویٰ دستیاب نہیں۔',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: onBackToList,
                  child: const Text('فہرست پر واپس جائیں'),
                ),
              ],
            ),
          );
        }

        final claim = bundle.claim;
        final statusColor =
            claim.reliabilityStatus.colorForBrightness(theme.brightness);

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Chip(
                      label: Text(
                        claim.reliabilityStatus.urduLabel,
                        style: TextStyle(color: statusColor),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      claim.claimText.trim(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: statusColor,
                      ),
                    ),
                    const Divider(height: 24),
                    Text(
                      'درجہ بندی کی وجہ',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      claim.classificationReason,
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (claim.scholarlyAssessment.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'علمی محاکمہ',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        claim.scholarlyAssessment,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'متعلقہ مآخذ و روایات (${bundle.evidenceList.length})',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            ...bundle.evidenceList.map(
              (ClaimEvidenceModel ev) => EvidenceDetailCard(evidence: ev),
            ),
          ],
        );
      },
    );
  }
}
