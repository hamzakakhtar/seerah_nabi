import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/features/personal_notes/domain/personal_note_model.dart';
import 'package:seerat_un_nabi/features/personal_notes/presentation/personal_notes_provider.dart';

/// Modal sheet for creating or editing a personal study note anchored to a
/// chapter, paragraph, or historical claim.
class NoteEditorSheet extends ConsumerStatefulWidget {
  const NoteEditorSheet({
    super.key,
    required this.chapterStableId,
    this.paragraphStableId,
    this.claimStableId,
    this.existingNote,
    this.contextExcerpt,
  });

  final String chapterStableId;
  final String? paragraphStableId;
  final String? claimStableId;
  final PersonalNoteModel? existingNote;
  final String? contextExcerpt;

  static Future<void> show(
    BuildContext context, {
    required String chapterStableId,
    String? paragraphStableId,
    String? claimStableId,
    PersonalNoteModel? existingNote,
    String? contextExcerpt,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => NoteEditorSheet(
        chapterStableId: chapterStableId,
        paragraphStableId: paragraphStableId,
        claimStableId: claimStableId,
        existingNote: existingNote,
        contextExcerpt: contextExcerpt,
      ),
    );
  }

  @override
  ConsumerState<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends ConsumerState<NoteEditorSheet> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.existingNote?.noteText ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSaving) return;
    setState(() => _isSaving = true);

    final notifier = ref.read(personalNotesProvider.notifier);
    if (widget.existingNote != null) {
      await notifier.updateNote(
        id: widget.existingNote!.id,
        noteText: text,
      );
    } else {
      await notifier.createNote(
        chapterStableId: widget.chapterStableId,
        paragraphStableId: widget.paragraphStableId,
        claimStableId: widget.claimStableId,
        noteText: text,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existingNote != null ? 'حاشیہ ترمیم کریں' : 'نیا ذاتی حاشیہ',
            style: theme.textTheme.titleLarge,
          ),
          if (widget.contextExcerpt != null &&
              widget.contextExcerpt!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.contextExcerpt!,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 6,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              hintText: 'اپنا علمی مشاہدہ یا ذاتی حاشیہ تحریر کریں...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('محفوظ کریں'),
            ),
          ),
        ],
      ),
    );
  }
}
