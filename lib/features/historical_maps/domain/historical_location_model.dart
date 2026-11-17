import 'package:flutter/foundation.dart';

@immutable
class HistoricalLocationModel {
  const HistoricalLocationModel({
    required this.stableId,
    required this.nameArabic,
    required this.nameUrdu,
    required this.regionUrdu,
    required this.latitude,
    required this.longitude,
    required this.historicalSignificanceUrdu,
  });

  final String stableId;
  final String nameArabic;
  final String nameUrdu;
  final String regionUrdu;
  final double latitude;
  final double longitude;
  final String historicalSignificanceUrdu;
}
