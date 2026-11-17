import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:seerat_un_nabi/core/constants/route_names.dart';
import 'package:seerat_un_nabi/features/bookmarks/presentation/bookmarks_screen.dart';
import 'package:seerat_un_nabi/features/daily_seerah/presentation/daily_seerah_screen.dart';
import 'package:seerat_un_nabi/features/evidence_explorer/presentation/evidence_explorer_screen.dart';
import 'package:seerat_un_nabi/features/historical_maps/presentation/historical_maps_screen.dart';
import 'package:seerat_un_nabi/features/narration_comparison/presentation/narration_comparison_screen.dart';
import 'package:seerat_un_nabi/features/personal_notes/presentation/personal_notes_screen.dart';
import 'package:seerat_un_nabi/features/pronunciation/presentation/pronunciation_screen.dart';
import 'package:seerat_un_nabi/features/reading_progress/presentation/reading_progress_screen.dart';
import 'package:seerat_un_nabi/features/research_history/presentation/research_history_screen.dart';
import 'package:seerat_un_nabi/features/search/presentation/search_screen.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/presentation/chapter_reader_screen.dart';
import 'package:seerat_un_nabi/features/seerah_home/presentation/seerah_home_screen.dart';
import 'package:seerat_un_nabi/features/seerah_timeline/presentation/seerah_timeline_screen.dart';
import 'package:seerat_un_nabi/features/source_viewer/presentation/source_viewer_screen.dart';
import 'package:seerat_un_nabi/shared/widgets/feature_placeholder_screen.dart';

/// Centralized GoRouter configuration managed via Riverpod.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.home,
    routes: [
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        builder: (context, state) => const SeerahHomeScreen(),
      ),
      GoRoute(
        path: RouteNames.chapterOne,
        name: 'chapter_one',
        builder: (context, state) => ChapterReaderScreen(
          chapterStableId: 'chapter_001',
          initialScrollOffset:
              double.tryParse(state.uri.queryParameters['offset'] ?? '') ?? 0.0,
        ),
      ),
      GoRoute(
        path: RouteNames.chapterTwo,
        name: 'chapter_two',
        builder: (context, state) => ChapterReaderScreen(
          chapterStableId: 'chapter_002',
          initialScrollOffset:
              double.tryParse(state.uri.queryParameters['offset'] ?? '') ?? 0.0,
        ),
      ),
      GoRoute(
        path: RouteNames.chapterThree,
        name: 'chapter_three',
        builder: (context, state) => ChapterReaderScreen(
          chapterStableId: 'chapter_003',
          initialScrollOffset:
              double.tryParse(state.uri.queryParameters['offset'] ?? '') ?? 0.0,
        ),
      ),
      GoRoute(
        path: RouteNames.chapterFour,
        name: 'chapter_four',
        builder: (context, state) => ChapterReaderScreen(
          chapterStableId: 'chapter_004',
          initialScrollOffset:
              double.tryParse(state.uri.queryParameters['offset'] ?? '') ?? 0.0,
        ),
      ),
      GoRoute(
        path: RouteNames.chapterFive,
        name: 'chapter_five',
        builder: (context, state) => ChapterReaderScreen(
          chapterStableId: 'chapter_005',
          initialScrollOffset:
              double.tryParse(state.uri.queryParameters['offset'] ?? '') ?? 0.0,
        ),
      ),
      GoRoute(
        path: RouteNames.chapterSix,
        name: 'chapter_six',
        builder: (context, state) => ChapterReaderScreen(
          chapterStableId: 'chapter_006',
          initialScrollOffset:
              double.tryParse(state.uri.queryParameters['offset'] ?? '') ?? 0.0,
        ),
      ),
      GoRoute(
        path: RouteNames.chapterSeven,
        name: 'chapter_seven',
        builder: (context, state) => ChapterReaderScreen(
          chapterStableId: 'chapter_007',
          initialScrollOffset:
              double.tryParse(state.uri.queryParameters['offset'] ?? '') ?? 0.0,
        ),
      ),
      GoRoute(
        path: RouteNames.chapterEight,
        name: 'chapter_eight',
        builder: (context, state) => ChapterReaderScreen(
          chapterStableId: 'chapter_008',
          initialScrollOffset:
              double.tryParse(state.uri.queryParameters['offset'] ?? '') ?? 0.0,
        ),
      ),
      GoRoute(
        path: RouteNames.chapterNine,
        name: 'chapter_nine',
        builder: (context, state) => ChapterReaderScreen(
          chapterStableId: 'chapter_009',
          initialScrollOffset:
              double.tryParse(state.uri.queryParameters['offset'] ?? '') ?? 0.0,
        ),
      ),
      GoRoute(
        path: RouteNames.chapterTen,
        name: 'chapter_ten',
        builder: (context, state) => ChapterReaderScreen(
          chapterStableId: 'chapter_010',
          initialScrollOffset:
              double.tryParse(state.uri.queryParameters['offset'] ?? '') ?? 0.0,
        ),
      ),
      GoRoute(
        path: RouteNames.chapterEleven,
        name: 'chapter_eleven',
        builder: (context, state) => ChapterReaderScreen(
          chapterStableId: 'chapter_011',
          initialScrollOffset:
              double.tryParse(state.uri.queryParameters['offset'] ?? '') ?? 0.0,
        ),
      ),
      GoRoute(
        path: RouteNames.chapterTwelve,
        name: 'chapter_twelve',
        builder: (context, state) => ChapterReaderScreen(
          chapterStableId: 'chapter_012',
          initialScrollOffset:
              double.tryParse(state.uri.queryParameters['offset'] ?? '') ?? 0.0,
        ),
      ),
      GoRoute(
        path: RouteNames.chapterThirteen,
        name: 'chapter_thirteen',
        builder: (context, state) => ChapterReaderScreen(
          chapterStableId: 'chapter_013',
          initialScrollOffset:
              double.tryParse(state.uri.queryParameters['offset'] ?? '') ?? 0.0,
        ),
      ),
      GoRoute(
        path: RouteNames.chapterFourteen,
        name: 'chapter_fourteen',
        builder: (context, state) => ChapterReaderScreen(
          chapterStableId: 'chapter_014',
          initialScrollOffset:
              double.tryParse(state.uri.queryParameters['offset'] ?? '') ?? 0.0,
        ),
      ),
      GoRoute(
        path: RouteNames.chapterFifteen,
        name: 'chapter_fifteen',
        builder: (context, state) => ChapterReaderScreen(
          chapterStableId: 'chapter_015',
          initialScrollOffset:
              double.tryParse(state.uri.queryParameters['offset'] ?? '') ?? 0.0,
        ),
      ),
      GoRoute(
        path: RouteNames.chapterSixteen,
        name: 'chapter_sixteen',
        builder: (context, state) => ChapterReaderScreen(
          chapterStableId: 'chapter_016',
          initialScrollOffset:
              double.tryParse(state.uri.queryParameters['offset'] ?? '') ?? 0.0,
        ),
      ),
      GoRoute(
        path: '/chapters/id/:stableId',
        name: 'dynamic_chapter',
        builder: (context, state) => ChapterReaderScreen(
          chapterStableId: state.pathParameters['stableId'] ?? 'chapter_001',
          initialScrollOffset:
              double.tryParse(state.uri.queryParameters['offset'] ?? '') ?? 0.0,
        ),
      ),
      GoRoute(
        path: RouteNames.timeline,
        name: 'timeline',
        builder: (context, state) => const SeerahTimelineScreen(),
      ),
      GoRoute(
        path: RouteNames.historicalMaps,
        name: 'historical_maps',
        builder: (context, state) => HistoricalMapsScreen(
          initialLocationId: state.uri.queryParameters['locationId'],
        ),
      ),
      GoRoute(
        path: RouteNames.evidenceExplorer,
        name: 'evidence_explorer',
        builder: (context, state) => EvidenceExplorerScreen(
          initialClaimId: state.uri.queryParameters['claimId'],
        ),
      ),
      GoRoute(
        path: RouteNames.narrationComparison,
        name: 'narration_comparison',
        builder: (context, state) => const NarrationComparisonScreen(),
      ),
      GoRoute(
        path: RouteNames.search,
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: RouteNames.askAi,
        name: 'ask_ai',
        builder: (context, state) => const FeaturePlaceholderScreen(
          titleUrdu: 'تحقیقی معاون',
          phaseLabel: 'Phase 8',
          descriptionUrdu:
          'مستند تاریخی ریکارڈ اور حوالہ جات کی بنیاد پر سوالات کے جوابات کا نظام۔',
          icon: Icons.psychology_alt_outlined,
        ),
      ),
      GoRoute(
        path: RouteNames.pronunciation,
        name: 'pronunciation',
        builder: (context, state) => const PronunciationScreen(),
      ),
      GoRoute(
        path: RouteNames.dailySeerah,
        name: 'daily_seerah',
        builder: (context, state) => const DailySeerahScreen(),
      ),
      GoRoute(
        path: RouteNames.sourceViewer,
        name: 'source_viewer',
        builder: (context, state) => SourceViewerScreen(
          initialSourceId: state.uri.queryParameters['sourceId'],
        ),
      ),
      GoRoute(
        path: RouteNames.bookmarks,
        name: 'bookmarks',
        builder: (context, state) => const BookmarksScreen(),
      ),
      GoRoute(
        path: RouteNames.personalNotes,
        name: 'personal_notes',
        builder: (context, state) => const PersonalNotesScreen(),
      ),
      GoRoute(
        path: RouteNames.readingProgress,
        name: 'reading_progress',
        builder: (context, state) => const ReadingProgressScreen(),
      ),
      GoRoute(
        path: RouteNames.researchHistory,
        name: 'research_history',
        builder: (context, state) => const ResearchHistoryScreen(),
      ),
      GoRoute(
        path: RouteNames.scholarReview,
        name: 'scholar_review',
        builder: (context, state) => const FeaturePlaceholderScreen(
          titleUrdu: 'علمی نظرِ ثانی',
          phaseLabel: 'Phase 9',
          descriptionUrdu:
          'اہلِ علم اور محققین کی تصدیق و نظرِ ثانی کا نظام۔',
          icon: Icons.fact_check_outlined,
        ),
      ),
    ],
  );
});
