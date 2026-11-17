import 'package:flutter/foundation.dart';

enum ScholarReviewStatus {
  pending,
  approved,
  revisionRequested;

  static ScholarReviewStatus fromStorage(String value) => switch (value) {
        'approved' => ScholarReviewStatus.approved,
        'revision_requested' => ScholarReviewStatus.revisionRequested,
        _ => ScholarReviewStatus.pending,
      };

  String get storageValue => switch (this) {
        ScholarReviewStatus.pending => 'pending',
        ScholarReviewStatus.approved => 'approved',
        ScholarReviewStatus.revisionRequested => 'revision_requested',
      };
}

@immutable
class ScholarReviewModel {
  const ScholarReviewModel({
    required this.id,
    required this.chapterStableId,
    required this.reviewerName,
    required this.credentials,
    required this.reviewStatus,
    required this.notesUrdu,
    required this.reviewedAt,
  });

  final int id;
  final String chapterStableId;
  final String reviewerName;
  final String credentials;
  final ScholarReviewStatus reviewStatus;
  final String notesUrdu;
  final DateTime reviewedAt;
}
