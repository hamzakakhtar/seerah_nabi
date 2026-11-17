import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/features/bookmarks/presentation/bookmarks_provider.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/presentation/chapter_reader_controller.dart';
import 'package:seerat_un_nabi/shared/models/reading_settings.dart';
import 'package:seerat_un_nabi/shared/providers/reading_settings_provider.dart';
import 'package:seerat_un_nabi/shared/providers/repository_providers.dart';

/// Unified family AsyncNotifierProvider for any Seerah chapter keyed by its
/// immutable `chapterStableId` (e.g., `chapter_001`..`chapter_016`).
final chapterReaderProvider = AsyncNotifierProvider.family<
    ChapterReaderNotifier, ChapterReaderState, String>(
  ChapterReaderNotifier.new,
);

class ChapterReaderNotifier
    extends FamilyAsyncNotifier<ChapterReaderState, String> {
  ChapterReaderController get _controller => ChapterReaderController(
        chapterRepository: ref.read(chapterRepositoryProvider),
        bookmarkRepository: ref.read(bookmarkRepositoryProvider),
      );

  @override
  Future<ChapterReaderState> build(String arg) async {
    await ref.watch(databaseInitializerProvider.future);
    final languageCode = ref.watch(
      readingSettingsProvider.select(
        (ReadingSettings s) => s.locale.languageCode,
      ),
    );
    return _controller.load(
      chapterStableId: arg,
      languageCode: languageCode,
    );
  }

  Future<void> toggleBookmark() async {
    final ChapterReaderState? current = state.valueOrNull;
    if (current == null) return;
    final updated = await _controller.toggleBookmark(
      chapterStableId: arg,
      current: current,
    );
    state = AsyncData(updated);
    ref.invalidate(bookmarksProvider);
  }
}
