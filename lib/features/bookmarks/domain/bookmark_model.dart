import 'package:flutter/foundation.dart';

@immutable
class BookmarkModel {
  const BookmarkModel({
    required this.id,
    required this.chapterStableId,
    required this.titleUrdu,
    required this.createdAt,
    this.sectionStableId,
    this.paragraphStableId,
  });

  final int id;
  final String chapterStableId;
  final String? sectionStableId;
  final String? paragraphStableId;
  final String titleUrdu;
  final DateTime createdAt;
}
