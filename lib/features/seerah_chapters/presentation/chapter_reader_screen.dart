import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/presentation/chapter_reader_controller.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/presentation/chapter_reader_provider.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/presentation/widgets/chapter_reader_body.dart';
import 'package:seerat_un_nabi/shared/widgets/seerah_app_bar.dart';

/// Unified Seerah chapter reader screen supporting all chapters by
/// [chapterStableId] with bookmark persistence and sequential navigation.
class ChapterReaderScreen extends ConsumerWidget {
  const ChapterReaderScreen({
    super.key,
    required this.chapterStableId,
    this.initialScrollOffset = 0.0,
  });

  final String chapterStableId;
  final double initialScrollOffset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapterAsync = ref.watch(chapterReaderProvider(chapterStableId));
    final isBookmarked = chapterAsync.when(
      data: (ChapterReaderState state) => state.isBookmarked,
      loading: () => false,
      error: (_, __) => false,
    );

    final shortTitle = ChapterReaderController.shortTitleFor(chapterStableId);

    // Fallback add kiya hai taake appBarTitle hamesha non-nullable String rahay
    final String appBarTitle = shortTitle ??
        chapterAsync.when(
          data: (ChapterReaderState state) => state.chapter.title,
          loading: () => 'مطالعۂ سیرت',
          error: (_, __) => 'مطالعۂ سیرت',
        ) ??
        'مطالعۂ سیرت';

    final previous =
    ChapterReaderController.previousChapterFor(chapterStableId);
    final next = ChapterReaderController.nextChapterFor(chapterStableId);

    return Scaffold(
      appBar: SeerahAppBar(
        title: appBarTitle,
        actions: [
          IconButton(
            tooltip: 'نشانِ مطالعہ',
            icon: Icon(
              isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
            ),
            onPressed: () {
              ref
                  .read(chapterReaderProvider(chapterStableId).notifier)
                  .toggleBookmark();
            },
          ),
        ],
      ),
      body: chapterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '${shortTitle ?? 'باب'} لوڈ کرنے میں دشواری پیش آئی۔',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        data: (ChapterReaderState chapterState) => ChapterReaderBody(
          chapter: chapterState.chapter,
          initialScrollOffset: initialScrollOffset,
          previousChapterLabel: previous != null
              ? 'پچھلا باب: ${previous.shortTitleUrdu}'
              : null,
          onPreviousChapter:
          previous != null ? () => context.go(previous.routePath) : null,
          nextChapterLabel:
          next != null ? 'اگلا باب: ${next.shortTitleUrdu}' : null,
          onNextChapter: next != null ? () => context.go(next.routePath) : null,
        ),
      ),
    );
  }
}