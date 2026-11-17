import 'package:flutter/foundation.dart';

@immutable
class PersonalNoteModel {
  const PersonalNoteModel({
    required this.id,
    required this.chapterStableId,
    required this.noteText,
    required this.createdAt,
    required this.updatedAt,
    this.paragraphStableId,
    this.claimStableId,
  });

  final int id;
  final String chapterStableId;
  final String? paragraphStableId;
  final String? claimStableId;
  final String noteText;
  final DateTime createdAt;
  final DateTime updatedAt;
}
