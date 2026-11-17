import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:seerat_un_nabi/core/constants/route_names.dart';
import 'package:seerat_un_nabi/core/theme/app_typography.dart';
import 'package:seerat_un_nabi/features/historical_maps/domain/historical_location_model.dart';
import 'package:seerat_un_nabi/features/historical_maps/presentation/historical_maps_provider.dart';
import 'package:seerat_un_nabi/features/historical_maps/presentation/widgets/arabia_offline_map_canvas.dart';
import 'package:seerat_un_nabi/features/seerah_timeline/domain/timeline_event_model.dart';
import 'package:seerat_un_nabi/shared/widgets/seerah_app_bar.dart';

/// Offline Historical Maps screen displaying Seerah geographic sites, travel
/// corridors, coordinates, and linked chronological events.
class HistoricalMapsScreen extends ConsumerStatefulWidget {
  const HistoricalMapsScreen({
    super.key,
    this.initialLocationId,
  });

  final String? initialLocationId;

  @override
  ConsumerState<HistoricalMapsScreen> createState() =>
      _HistoricalMapsScreenState();
}

class _HistoricalMapsScreenState extends ConsumerState<HistoricalMapsScreen> {
  String? _selectedLocationId;

  @override
  void initState() {
    super.initState();
    _selectedLocationId = widget.initialLocationId;
  }

  String _routeForChapter(String chapterStableId) => switch (chapterStableId) {
        'chapter_001' => RouteNames.chapterOne,
        'chapter_002' => RouteNames.chapterTwo,
        _ => '/chapters/id/$chapterStableId',
      };

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(historicalLocationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const SeerahAppBar(title: 'تاریخی نقشے'),
      body: locationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(
            'تاریخی نقشہ لوڈ کرنے میں دشواری پیش آئی۔',
            style: theme.textTheme.bodyLarge,
          ),
        ),
        data: (List<HistoricalLocationModel> locations) {
          if (locations.isEmpty) {
            return Center(
              child: Text(
                'تاریخی مقامات کا ریکارڈ ابھی خالی ہے۔',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          final selectedLocation = locations.firstWhere(
            (HistoricalLocationModel l) =>
                l.stableId == (_selectedLocationId ?? 'loc_makkah'),
            orElse: () => locations.first,
          );

          final eventsAsync =
              ref.watch(eventsAtLocationProvider(selectedLocation.stableId));

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              ArabiaOfflineMapCanvas(
                locations: locations,
                selectedLocationId: selectedLocation.stableId,
                onSelectLocation: (HistoricalLocationModel loc) {
                  setState(() => _selectedLocationId = loc.stableId);
                },
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: locations
                      .map(
                        (HistoricalLocationModel loc) => Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: ChoiceChip(
                            label: Text(loc.nameUrdu),
                            selected: loc.stableId == selectedLocation.stableId,
                            onSelected: (_) {
                              setState(() => _selectedLocationId = loc.stableId);
                            },
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 14),
              _SelectedLocationCard(location: selectedLocation),
              const SizedBox(height: 16),
              Text(
                'اس مقام سے وابستہ تاریخی واقعات',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              eventsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => Text(
                  'متعلقہ واقعات لوڈ کرنے میں دشواری پیش آئی۔',
                  style: theme.textTheme.bodySmall,
                ),
                data: (List<TimelineEventModel> events) {
                  if (events.isEmpty) {
                    return Text(
                      'اس مقام سے متعلق مزید واقعات اگلے ابواب میں شامل ہوں گے۔',
                      style: theme.textTheme.bodySmall,
                    );
                  }
                  return Column(
                    children: events
                        .map(
                          (TimelineEventModel event) => Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(
                                event.titleUrdu,
                                style: theme.textTheme.titleMedium,
                              ),
                              subtitle: Text(
                                event.summaryUrdu,
                                style: theme.textTheme.bodySmall,
                              ),
                              trailing: const Icon(Icons.chevron_left_rounded),
                              onTap: () => context.push(
                                _routeForChapter(event.chapterStableId),
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SelectedLocationCard extends StatelessWidget {
  const _SelectedLocationCard({required this.location});

  final HistoricalLocationModel location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(label: Text(location.regionUrdu)),
                const Spacer(),
                Text(
                  '${location.latitude.toStringAsFixed(2)}°N, '
                  '${location.longitude.toStringAsFixed(2)}°E',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              location.nameUrdu,
              style: theme.textTheme.headlineMedium,
            ),
            Text(
              location.nameArabic,
              style: AppTypography.arabicSource(
                color: theme.colorScheme.secondary,
                fontSize: 18,
              ),
              textDirection: TextDirection.rtl,
            ),
            if (location.historicalSignificanceUrdu.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                location.historicalSignificanceUrdu,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
