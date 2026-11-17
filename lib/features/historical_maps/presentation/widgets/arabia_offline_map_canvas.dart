import 'package:flutter/material.dart';
import 'package:seerat_un_nabi/features/historical_maps/domain/historical_location_model.dart';

/// 100% offline interactive Arabian Peninsula & Hijaz cartographic map canvas.
///
/// Projects real historical latitude/longitude coordinates (`13°N–34°N`,
/// `34°E–54°E`) onto a zoomable/pannable [InteractiveViewer] without external
/// map tile servers or API keys.
class ArabiaOfflineMapCanvas extends StatelessWidget {
  const ArabiaOfflineMapCanvas({
    super.key,
    required this.locations,
    required this.selectedLocationId,
    required this.onSelectLocation,
  });

  final List<HistoricalLocationModel> locations;
  final String? selectedLocationId;
  final ValueChanged<HistoricalLocationModel> onSelectLocation;

  static const double _minLat = 13.0;
  static const double _maxLat = 34.5;
  static const double _minLon = 34.0;
  static const double _maxLon = 54.0;

  Offset _project(double lat, double lon, Size size) {
    final xNorm = ((lon - _minLon) / (_maxLon - _minLon)).clamp(0.05, 0.95);
    final yNorm =
        (1.0 - ((lat - _minLat) / (_maxLat - _minLat))).clamp(0.05, 0.95);
    return Offset(xNorm * size.width, yNorm * size.height);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 290,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF172121) : const Color(0xFFE7EFEA),
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(16),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
            final byId = {for (final l in locations) l.stableId: l};

            return InteractiveViewer(
              minScale: 1.0,
              maxScale: 3.5,
              child: Stack(
                children: [
                  CustomPaint(
                    size: canvasSize,
                    painter: _ArabiaCartographyPainter(
                      isDark: isDark,
                      primaryColor: theme.colorScheme.primary,
                      secondaryColor: theme.colorScheme.secondary,
                      project: (lat, lon) => _project(lat, lon, canvasSize),
                      locationsById: byId,
                    ),
                  ),
                  ...locations.map((loc) {
                    final pos = _project(loc.latitude, loc.longitude, canvasSize);
                    final isSelected = loc.stableId == selectedLocationId;

                    return Positioned(
                      left: pos.dx - 16,
                      top: pos.dy - 16,
                      child: GestureDetector(
                        onTap: () => onSelectLocation(loc),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    blurRadius: 6,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.place_rounded,
                                size: isSelected ? 20 : 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface
                                    .withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.secondary
                                      : theme.colorScheme.outline,
                                ),
                              ),
                              child: Text(
                                loc.nameUrdu,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ArabiaCartographyPainter extends CustomPainter {
  _ArabiaCartographyPainter({
    required this.isDark,
    required this.primaryColor,
    required this.secondaryColor,
    required this.project,
    required this.locationsById,
  });

  final bool isDark;
  final Color primaryColor;
  final Color secondaryColor;
  final Offset Function(double lat, double lon) project;
  final Map<String, HistoricalLocationModel> locationsById;

  @override
  void paint(Canvas canvas, Size size) {
    // Editorial graticule grid
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..strokeWidth = 1;

    for (double lat = 15; lat <= 33; lat += 3) {
      final y = project(lat, 35).dy;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double lon = 36; lon <= 52; lon += 4) {
      final x = project(20, lon).dx;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Simplified Arabian Peninsula land polygon for clear offline geographic orientation
    final peninsulaCoords = <List<double>>[
      [32.5, 34.8],
      [33.5, 38.0],
      [30.0, 48.0],
      [26.0, 50.8],
      [24.0, 54.0],
      [22.0, 59.0],
      [16.5, 53.0],
      [12.8, 45.0],
      [12.7, 43.3],
      [16.0, 42.5],
      [21.5, 39.1],
      [25.5, 36.8],
      [29.5, 34.9],
    ];

    final landPath = Path();
    for (var i = 0; i < peninsulaCoords.length; i++) {
      final pt = project(peninsulaCoords[i][0], peninsulaCoords[i][1]);
      if (i == 0) {
        landPath.moveTo(pt.dx, pt.dy);
      } else {
        landPath.lineTo(pt.dx, pt.dy);
      }
    }
    landPath.close();

    final landPaint = Paint()
      ..color = isDark ? const Color(0xFF232622) : const Color(0xFFF6EFE0)
      ..style = PaintingStyle.fill;
    final coastPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(landPath, landPaint);
    canvas.drawPath(landPath, coastPaint);

    // Draw historical travel & trade route arcs between connected Seerah locations
    _drawRoute(canvas, 'loc_makkah', 'loc_abwa');
    _drawRoute(canvas, 'loc_abwa', 'loc_madinah');
    _drawRoute(canvas, 'loc_madinah', 'loc_sham_busra');
    _drawRoute(canvas, 'loc_makkah', 'loc_banu_sad');
    _drawRoute(canvas, 'loc_yemen_sanaa', 'loc_makkah');
    _drawRoute(canvas, 'loc_makkah', 'loc_habashah');
    _drawRoute(canvas, 'loc_madinah', 'loc_badr');
    _drawRoute(canvas, 'loc_makkah', 'loc_jerusalem');
    _drawRoute(canvas, 'loc_madinah', 'loc_khaybar');
    _drawRoute(canvas, 'loc_khaybar', 'loc_tabuk');
    _drawRoute(canvas, 'loc_madinah', 'loc_hudaybiyyah');
    _drawRoute(canvas, 'loc_makkah', 'loc_hunayn');
    _drawRoute(canvas, 'loc_tabuk', 'loc_mutah');
    _drawRoute(canvas, 'loc_madinah', 'loc_najran');
  }

  void _drawRoute(Canvas canvas, String fromId, String toId) {
    final a = locationsById[fromId];
    final b = locationsById[toId];
    if (a == null || b == null) return;

    final p1 = project(a.latitude, a.longitude);
    final p2 = project(b.latitude, b.longitude);
    final routePaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawLine(p1, p2, routePaint);
  }

  @override
  bool shouldRepaint(covariant _ArabiaCartographyPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.locationsById.length != locationsById.length;
  }
}
