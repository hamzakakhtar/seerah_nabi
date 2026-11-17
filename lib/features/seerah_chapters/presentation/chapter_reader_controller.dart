import 'package:flutter/foundation.dart';
import 'package:seerat_un_nabi/core/constants/route_names.dart';
import 'package:seerat_un_nabi/features/bookmarks/data/bookmark_repository.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/data/chapter_repository.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/domain/chapter_models.dart';

/// Navigation and display metadata for sequential Seerah chapters.
@immutable
class ChapterNavInfo {
  const ChapterNavInfo({
    required this.stableId,
    required this.shortTitleUrdu,
    required this.routePath,
  });

  final String stableId;
  final String shortTitleUrdu;
  final String routePath;
}

/// Shared state for any Seerah chapter loaded from SQLite.
@immutable
class ChapterReaderState {
  const ChapterReaderState({
    required this.chapter,
    required this.isBookmarked,
  });

  final ChapterModel chapter;
  final bool isBookmarked;

  ChapterReaderState copyWith({
    ChapterModel? chapter,
    bool? isBookmarked,
  }) {
    return ChapterReaderState(
      chapter: chapter ?? this.chapter,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}

/// Unified controller coordinating chapter loading, bookmark persistence, and
/// previous/next chapter navigation across all chapters.
final class ChapterReaderController {
  const ChapterReaderController({
    required ChapterRepository chapterRepository,
    required BookmarkRepository bookmarkRepository,
  })  : _chapterRepository = chapterRepository,
        _bookmarkRepository = bookmarkRepository;

  final ChapterRepository _chapterRepository;
  final BookmarkRepository _bookmarkRepository;

  static const List<ChapterNavInfo> orderedChapters = <ChapterNavInfo>[
    ChapterNavInfo(
      stableId: 'chapter_001',
      shortTitleUrdu: 'باب اول',
      routePath: RouteNames.chapterOne,
    ),
    ChapterNavInfo(
      stableId: 'chapter_002',
      shortTitleUrdu: 'باب دوم',
      routePath: RouteNames.chapterTwo,
    ),
    ChapterNavInfo(
      stableId: 'chapter_003',
      shortTitleUrdu: 'باب سوم',
      routePath: RouteNames.chapterThree,
    ),
    ChapterNavInfo(
      stableId: 'chapter_004',
      shortTitleUrdu: 'باب چہارم',
      routePath: RouteNames.chapterFour,
    ),
    ChapterNavInfo(
      stableId: 'chapter_005',
      shortTitleUrdu: 'باب پنجم',
      routePath: RouteNames.chapterFive,
    ),
    ChapterNavInfo(
      stableId: 'chapter_006',
      shortTitleUrdu: 'باب ششم',
      routePath: RouteNames.chapterSix,
    ),
    ChapterNavInfo(
      stableId: 'chapter_007',
      shortTitleUrdu: 'باب ہفتم',
      routePath: RouteNames.chapterSeven,
    ),
    ChapterNavInfo(
      stableId: 'chapter_008',
      shortTitleUrdu: 'باب ہشتم',
      routePath: RouteNames.chapterEight,
    ),
    ChapterNavInfo(
      stableId: 'chapter_009',
      shortTitleUrdu: 'باب نہم',
      routePath: RouteNames.chapterNine,
    ),
    ChapterNavInfo(
      stableId: 'chapter_010',
      shortTitleUrdu: 'باب دہم',
      routePath: RouteNames.chapterTen,
    ),
    ChapterNavInfo(
      stableId: 'chapter_011',
      shortTitleUrdu: 'باب یازدہم',
      routePath: RouteNames.chapterEleven,
    ),
    ChapterNavInfo(
      stableId: 'chapter_012',
      shortTitleUrdu: 'باب دوازدہم',
      routePath: RouteNames.chapterTwelve,
    ),
    ChapterNavInfo(
      stableId: 'chapter_013',
      shortTitleUrdu: 'باب سیزدہم',
      routePath: RouteNames.chapterThirteen,
    ),
    ChapterNavInfo(
      stableId: 'chapter_014',
      shortTitleUrdu: 'باب چہاردہم',
      routePath: RouteNames.chapterFourteen,
    ),
    ChapterNavInfo(
      stableId: 'chapter_015',
      shortTitleUrdu: 'باب پانزدہم',
      routePath: RouteNames.chapterFifteen,
    ),
    ChapterNavInfo(
      stableId: 'chapter_016',
      shortTitleUrdu: 'باب شانزدہم',
      routePath: RouteNames.chapterSixteen,
    ),
  ];

  static int indexFor(String chapterStableId) {
    return orderedChapters.indexWhere((c) => c.stableId == chapterStableId);
  }

  static String? shortTitleFor(String chapterStableId) {
    final idx = indexFor(chapterStableId);
    return idx >= 0 ? orderedChapters[idx].shortTitleUrdu : null;
  }

  static ChapterNavInfo? previousChapterFor(String chapterStableId) {
    final idx = indexFor(chapterStableId);
    return idx > 0 ? orderedChapters[idx - 1] : null;
  }

  static ChapterNavInfo? nextChapterFor(String chapterStableId) {
    final idx = indexFor(chapterStableId);
    if (idx >= 0 && idx + 1 < orderedChapters.length) {
      return orderedChapters[idx + 1];
    }
    return null;
  }

  Future<ChapterReaderState> load({
    required String chapterStableId,
    required String languageCode,
  }) async {
    final chapter = await _chapterRepository.getFullChapter(
      chapterStableId,
      languageCode: languageCode,
    );
    if (chapter == null) {
      throw StateError('Chapter $chapterStableId not found in SQLite.');
    }
    final isBookmarked =
        await _bookmarkRepository.isChapterBookmarked(chapterStableId);
    return ChapterReaderState(chapter: chapter, isBookmarked: isBookmarked);
  }

  Future<ChapterReaderState> toggleBookmark({
    required String chapterStableId,
    required ChapterReaderState current,
  }) async {
    if (current.isBookmarked) {
      await _bookmarkRepository.removeBookmarksForChapter(chapterStableId);
      return current.copyWith(isBookmarked: false);
    }
    await _bookmarkRepository.addBookmark(
      chapterStableId: chapterStableId,
      titleUrdu: current.chapter.title,
    );
    return current.copyWith(isBookmarked: true);
  }
}
