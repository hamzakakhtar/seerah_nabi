import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:seerat_un_nabi/core/constants/route_names.dart';
import 'package:seerat_un_nabi/features/bookmarks/domain/bookmark_model.dart';
import 'package:seerat_un_nabi/features/bookmarks/presentation/bookmarks_provider.dart';
import 'package:seerat_un_nabi/shared/widgets/seerah_app_bar.dart';

/// Displays all user-saved Seerah bookmarks with direct navigation and removal.
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  String _routeForChapter(String chapterStableId) => switch (chapterStableId) {
        'chapter_001' => RouteNames.chapterOne,
        'chapter_002' => RouteNames.chapterTwo,
        _ => '/chapters/id/$chapterStableId',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const SeerahAppBar(title: 'نشانِ مطالعہ'),
      body: bookmarksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(
            'نشانِ مطالعہ لوڈ کرنے میں دشواری پیش آئی۔',
            style: theme.textTheme.bodyLarge,
          ),
        ),
        data: (List<BookmarkModel> bookmarks) {
          if (bookmarks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bookmark_border_rounded,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ابھی کوئی نشانِ مطالعہ محفوظ نہیں ہے۔',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'کسی بھی باب کے مطالعے کے دوران اوپر موجود نشانِ مطالعہ بٹن سے باب محفوظ کریں۔',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              final bookmark = bookmarks[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.12),
                    foregroundColor: theme.colorScheme.primary,
                    child: const Icon(Icons.bookmark_rounded),
                  ),
                  title: Text(
                    bookmark.titleUrdu,
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'محفوظ شدہ: ${bookmark.createdAt.toLocal().toString().split('.').first}',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: IconButton(
                    tooltip: 'حذف کریں',
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () {
                      ref
                          .read(bookmarksProvider.notifier)
                          .removeBookmark(bookmark.id);
                    },
                  ),
                  onTap: () {
                    context.push(_routeForChapter(bookmark.chapterStableId));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
