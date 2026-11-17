import 'package:flutter/foundation.dart';

@immutable
class ResearchVersionModel {
  const ResearchVersionModel({
    required this.id,
    required this.versionTag,
    required this.changeSummaryUrdu,
    required this.revisedBy,
    required this.createdAt,
    this.chapterStableId,
  });

  final int id;
  final String versionTag;
  final String? chapterStableId;
  final String changeSummaryUrdu;
  final String revisedBy;
  final DateTime createdAt;
}
