import 'package:seerat_un_nabi/core/constants/route_names.dart';
import 'package:seerat_un_nabi/features/reading_progress/data/reading_progress_repository.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/data/chapter_repository.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/domain/chapter_summary.dart';
import 'package:seerat_un_nabi/features/seerah_home/domain/seerah_home_state.dart';

/// Repository powering the Seerah Home Screen via SQLite chapters and
/// persisted reading progress.
abstract interface class SeerahHomeRepository {
  Future<SeerahHomeState> loadHomeOverview({required String languageCode});
}

final class SqliteSeerahHomeRepository implements SeerahHomeRepository {
  SqliteSeerahHomeRepository({
    required ChapterRepository chapterRepository,
    required ReadingProgressRepository readingProgressRepository,
  })  : _chapterRepository = chapterRepository,
        _readingProgressRepository = readingProgressRepository;

  final ChapterRepository _chapterRepository;
  final ReadingProgressRepository _readingProgressRepository;

  static const List<ChapterSummary> _emptyDatabaseFallback = <ChapterSummary>[
    ChapterSummary(
      stableId: 'chapter_001',
      orderIndex: 1,
      titleUrdu: 'باب اول: ابتدائی تاریخی پس منظر',
      subtitleUrdu: 'SQLite ڈیٹابیس تیار ہے',
      routePath: RouteNames.chapterOne,
      eraLabelUrdu: 'قبل از بعثت',
    ),
    ChapterSummary(
      stableId: 'chapter_002',
      orderIndex: 2,
      titleUrdu: 'باب دوم: ولادتِ مبارکہ و ابتدائی پرورش',
      subtitleUrdu: 'SQLite ڈیٹابیس تیار ہے',
      routePath: RouteNames.chapterTwo,
      eraLabelUrdu: 'عہدِ طفولیت',
    ),
  ];

  @override
  Future<SeerahHomeState> loadHomeOverview({
    required String languageCode,
  }) async {
    final dbChapters = await _chapterRepository.getChapterDirectory(
      languageCode: languageCode,
    );
    final chapters =
        dbChapters.isNotEmpty ? dbChapters : _emptyDatabaseFallback;

    final lastProgress =
        await _readingProgressRepository.getLastActiveProgress();

    ChapterSummary? activeChapter;
    if (lastProgress != null) {
      for (final chapter in chapters) {
        if (chapter.stableId == lastProgress.chapterStableId) {
          activeChapter = chapter;
          break;
        }
      }
    }
    activeChapter ??= chapters.first;

    final baseRoute = activeChapter.routePath.isNotEmpty
        ? activeChapter.routePath
        : '/chapters/id/${activeChapter.stableId}';
    final scrollOffset = lastProgress?.scrollOffset ?? 0.0;
    final resumeRoute = scrollOffset > 0
        ? '$baseRoute?offset=${scrollOffset.toStringAsFixed(1)}'
        : baseRoute;

    return SeerahHomeState(
      chapters: chapters,
      lastChapterTitleUrdu: activeChapter.titleUrdu,
      lastChapterRoute: resumeRoute,
      progressFraction: lastProgress?.completionFraction ?? 0.0,
      lastScrollOffset: scrollOffset,
    );
  }
}
