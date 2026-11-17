import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:seerat_un_nabi/core/constants/route_names.dart';
import 'package:seerat_un_nabi/features/personal_notes/domain/personal_note_model.dart';
import 'package:seerat_un_nabi/features/personal_notes/presentation/personal_notes_provider.dart';
import 'package:seerat_un_nabi/features/personal_notes/presentation/widgets/note_editor_sheet.dart';
import 'package:seerat_un_nabi/shared/widgets/seerah_app_bar.dart';

/// Displays all personal study notes saved across chapters, paragraphs, and claims.
class PersonalNotesScreen extends ConsumerWidget {
  const PersonalNotesScreen({super.key});

  String _routeForChapter(String chapterStableId) => switch (chapterStableId) {
        'chapter_001' => RouteNames.chapterOne,
        'chapter_002' => RouteNames.chapterTwo,
        _ => '/chapters/id/$chapterStableId',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(personalNotesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const SeerahAppBar(title: 'ذاتی حواشی'),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(
            'ذاتی حواشی لوڈ کرنے میں دشواری پیش آئی۔',
            style: theme.textTheme.bodyLarge,
          ),
        ),
        data: (List<PersonalNoteModel> notes) {
          if (notes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ابھی کوئی ذاتی حاشیہ تحریر نہیں کیا گیا۔',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'مطالعے کے دوران کسی بھی پیراگراف یا دعوے پر ذاتی علمی نوٹ محفوظ کیا جا سکتا ہے۔',
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
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Chip(label: Text(note.chapterStableId)),
                          if (note.claimStableId != null)
                            Chip(label: Text(note.claimStableId!)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        note.noteText,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            note.updatedAt.toLocal().toString().split('.').first,
                            style: theme.textTheme.bodySmall,
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'باب کھولیں',
                            icon: const Icon(Icons.menu_book_outlined),
                            onPressed: () => context.push(
                              _routeForChapter(note.chapterStableId),
                            ),
                          ),
                          IconButton(
                            tooltip: 'ترمیم',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => NoteEditorSheet.show(
                              context,
                              chapterStableId: note.chapterStableId,
                              existingNote: note,
                            ),
                          ),
                          IconButton(
                            tooltip: 'حذف کریں',
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () {
                              ref
                                  .read(personalNotesProvider.notifier)
                                  .deleteNote(note.id);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
