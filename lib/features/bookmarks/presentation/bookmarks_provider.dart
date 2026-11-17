import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/features/bookmarks/domain/bookmark_model.dart';
import 'package:seerat_un_nabi/shared/providers/repository_providers.dart';

/// Riverpod provider managing persisted SQLite bookmarks.
final bookmarksProvider =
    AsyncNotifierProvider<BookmarksNotifier, List<BookmarkModel>>(
  BookmarksNotifier.new,
);

class BookmarksNotifier extends AsyncNotifier<List<BookmarkModel>> {
  @override
  Future<List<BookmarkModel>> build() async {
    await ref.watch(databaseInitializerProvider.future);
    return ref.watch(bookmarkRepositoryProvider).getAllBookmarks();
  }

  Future<void> addBookmark({
    required String chapterStableId,
    String? sectionStableId,
    String? paragraphStableId,
    required String titleUrdu,
  }) async {
    await ref.read(bookmarkRepositoryProvider).addBookmark(
          chapterStableId: chapterStableId,
          sectionStableId: sectionStableId,
          paragraphStableId: paragraphStableId,
          titleUrdu: titleUrdu,
        );
    ref.invalidateSelf();
  }

  Future<void> removeBookmark(int id) async {
    await ref.read(bookmarkRepositoryProvider).removeBookmarkById(id);
    ref.invalidateSelf();
  }
}
