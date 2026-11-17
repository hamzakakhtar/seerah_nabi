import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/features/personal_notes/domain/personal_note_model.dart';
import 'package:seerat_un_nabi/shared/providers/repository_providers.dart';

/// Manages all persisted personal study notes across the application.
final personalNotesProvider =
    AsyncNotifierProvider<PersonalNotesNotifier, List<PersonalNoteModel>>(
  PersonalNotesNotifier.new,
);

/// Provides personal notes scoped to a specific chapter.
final chapterNotesProvider =
    FutureProvider.family<List<PersonalNoteModel>, String>(
  (ref, chapterStableId) async {
    await ref.watch(databaseInitializerProvider.future);
    // Watch all notes so mutations automatically refresh chapter views.
    final all = await ref.watch(personalNotesProvider.future);
    return all
        .where((n) => n.chapterStableId == chapterStableId)
        .toList(growable: false);
  },
);

class PersonalNotesNotifier extends AsyncNotifier<List<PersonalNoteModel>> {
  @override
  Future<List<PersonalNoteModel>> build() async {
    await ref.watch(databaseInitializerProvider.future);
    return ref.watch(personalNoteRepositoryProvider).getAllNotes();
  }

  Future<void> createNote({
    required String chapterStableId,
    String? paragraphStableId,
    String? claimStableId,
    required String noteText,
  }) async {
    if (noteText.trim().isEmpty) return;
    await ref.read(personalNoteRepositoryProvider).createNote(
          chapterStableId: chapterStableId,
          paragraphStableId: paragraphStableId,
          claimStableId: claimStableId,
          noteText: noteText.trim(),
        );
    ref.invalidateSelf();
  }

  Future<void> updateNote({
    required int id,
    required String noteText,
  }) async {
    if (noteText.trim().isEmpty) return;
    await ref.read(personalNoteRepositoryProvider).updateNote(
          id: id,
          noteText: noteText.trim(),
        );
    ref.invalidateSelf();
  }

  Future<void> deleteNote(int id) async {
    await ref.read(personalNoteRepositoryProvider).deleteNote(id);
    ref.invalidateSelf();
  }
}
