import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerat_un_nabi/core/widgets/reliability_legend_banner.dart';
import 'package:seerat_un_nabi/features/personal_notes/domain/personal_note_model.dart';
import 'package:seerat_un_nabi/features/personal_notes/presentation/personal_notes_provider.dart';
import 'package:seerat_un_nabi/features/personal_notes/presentation/widgets/note_editor_sheet.dart';
import 'package:seerat_un_nabi/features/reading_progress/data/reading_progress_repository.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/domain/chapter_models.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/presentation/widgets/chapter_toc_sheet.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/presentation/widgets/claim_quick_inspector_sheet.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/presentation/widgets/claim_rich_paragraph.dart';
import 'package:seerat_un_nabi/features/seerah_home/presentation/seerah_home_provider.dart';
import 'package:seerat_un_nabi/shared/providers/reading_settings_provider.dart';
import 'package:seerat_un_nabi/shared/providers/repository_providers.dart';

/// Shared Urdu editorial reading interface for Seerah chapters.
///
/// Automatically tracks Smart Reading Progress (chapter, section, paragraph,
/// scroll offset, and reading sessions), renders reliability-colored claims,
/// and enables attaching personal notes to paragraphs or individual claims.
class ChapterReaderBody extends ConsumerStatefulWidget {
  const ChapterReaderBody({
    super.key,
    required this.chapter,
    this.initialScrollOffset = 0.0,
    this.previousChapterLabel,
    this.onPreviousChapter,
    this.nextChapterLabel,
    this.onNextChapter,
  });

  final ChapterModel chapter;
  final double initialScrollOffset;
  final String? previousChapterLabel;
  final VoidCallback? onPreviousChapter;
  final String? nextChapterLabel;
  final VoidCallback? onNextChapter;

  @override
  ConsumerState<ChapterReaderBody> createState() => _ChapterReaderBodyState();
}

class _ChapterReaderBodyState extends ConsumerState<ChapterReaderBody> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = <String, GlobalKey>{};

  late final ReadingProgressRepository _progressRepository;
  String? _selectedClaimId;
  String? _activeSectionId;
  String? _activeParagraphId;
  double _lastSavedFraction = -1;
  int? _activeSessionId;
  DateTime? _sessionStartedAt;

  @override
  void initState() {
    super.initState();
    _progressRepository = ref.read(readingProgressRepositoryProvider);
    _initSectionKeys();
    _scrollController.addListener(_onScroll);
    _beginSession();

    if (widget.initialScrollOffset > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final max = _scrollController.position.maxScrollExtent;
          _scrollController.jumpTo(widget.initialScrollOffset.clamp(0.0, max));
        }
      });
    }
  }

  void _initSectionKeys() {
    _sectionKeys.clear();
    for (final SectionModel section in widget.chapter.sections) {
      _sectionKeys[section.stableId] = GlobalKey();
    }
    if (widget.chapter.sections.isNotEmpty) {
      _activeSectionId = widget.chapter.sections.first.stableId;
      if (widget.chapter.sections.first.paragraphs.isNotEmpty) {
        _activeParagraphId =
            widget.chapter.sections.first.paragraphs.first.stableId;
      }
    }
  }

  Future<void> _beginSession() async {
    _sessionStartedAt = DateTime.now();
    _activeSessionId = await _progressRepository.startReadingSession(
      widget.chapter.stableId,
    );
  }

  @override
  void didUpdateWidget(covariant ChapterReaderBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapter.stableId != widget.chapter.stableId) {
      _closeCurrentSession();
      _initSectionKeys();
      _selectedClaimId = null;
      _lastSavedFraction = -1;
      _beginSession();
    }
  }

  void _closeCurrentSession() {
    final sessionId = _activeSessionId;
    final startedAt = _sessionStartedAt;
    if (sessionId == null || startedAt == null) return;
    final elapsed = DateTime.now().difference(startedAt).inSeconds;
    final paragraphCount = widget.chapter.sections
        .expand((SectionModel s) => s.paragraphs)
        .length;
    _progressRepository.endReadingSession(
      sessionId: sessionId,
      durationSeconds: elapsed < 1 ? 1 : elapsed,
      paragraphsRead: paragraphCount,
    );
    _activeSessionId = null;
  }

  @override
  void dispose() {
    _closeCurrentSession();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final fraction = maxExtent > 0
        ? (_scrollController.offset / maxExtent).clamp(0.0, 1.0)
        : 0.0;

    if ((fraction - _lastSavedFraction).abs() >= 0.08) {
      _lastSavedFraction = fraction;
      _progressRepository.saveProgress(
        chapterStableId: widget.chapter.stableId,
        sectionStableId: _activeSectionId,
        paragraphStableId: _activeParagraphId,
        scrollOffset: _scrollController.offset,
        completionFraction: fraction,
      );
      ref.invalidate(seerahHomeProvider);
    }
  }

  void _scrollToSection(SectionModel section) {
    _activeSectionId = section.stableId;
    if (section.paragraphs.isNotEmpty) {
      _activeParagraphId = section.paragraphs.first.stableId;
    }
    final key = _sectionKeys[section.stableId];
    final targetContext = key?.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final readingSettings = ref.watch(readingSettingsProvider);
    final chapterNotesAsync =
        ref.watch(chapterNotesProvider(widget.chapter.stableId));
    final theme = Theme.of(context);
    final chapter = widget.chapter;
    final notesCount = chapterNotesAsync.when(
      data: (List<PersonalNoteModel> notes) => notes.length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(label: Text(chapter.eraLabel)),
                    const Spacer(),
                    if (notesCount > 0)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 6),
                        child: Chip(
                          avatar: const Icon(Icons.edit_note_rounded, size: 16),
                          label: Text('$notesCount حواشی'),
                        ),
                      ),
                    if (chapter.sections.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => ChapterTocSheet.show(
                          context,
                          chapterTitle: chapter.title,
                          sections: chapter.sections,
                          onSectionSelected: _scrollToSection,
                        ),
                        icon: const Icon(Icons.list_alt_rounded, size: 18),
                        label: const Text('عناوین'),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  chapter.title,
                  style: theme.textTheme.headlineMedium,
                ),
                if (chapter.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    chapter.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
                if (chapter.summary.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    chapter.summary,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (!readingSettings.hasSeenReliabilityLegend) ...[
          const SizedBox(height: 14),
          ReliabilityLegendBanner(
            onDismiss: () {
              ref
                  .read(readingSettingsProvider.notifier)
                  .dismissReliabilityLegend();
            },
          ),
        ],
        const SizedBox(height: 18),
        ...chapter.sections.map((SectionModel section) {
          return Padding(
            key: _sectionKeys[section.stableId],
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsetsDirectional.only(start: 12),
                  decoration: BoxDecoration(
                    border: BorderDirectional(
                      start: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 3.5,
                      ),
                    ),
                  ),
                  child: Text(
                    section.title,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 14),
                ...section.paragraphs.map(
                  (ParagraphModel paragraph) => Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClaimRichParagraph(
                          paragraph: paragraph,
                          fontSize: readingSettings.fontSize,
                          selectedClaimId: _selectedClaimId,
                          onClaimTap: (HistoricalClaimModel claim) {
                            setState(() {
                              _selectedClaimId = claim.stableId;
                              _activeSectionId = section.stableId;
                              _activeParagraphId = paragraph.stableId;
                            });
                            ClaimQuickInspectorSheet.show(context, claim: claim);
                          },
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton.icon(
                            onPressed: () {
                              NoteEditorSheet.show(
                                context,
                                chapterStableId: chapter.stableId,
                                paragraphStableId: paragraph.stableId,
                                contextExcerpt: paragraph.plainText,
                              );
                            },
                            icon: const Icon(Icons.note_add_outlined, size: 16),
                            label: const Text('حاشیہ لکھیں'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const Divider(height: 32),
        Row(
          children: [
            if (widget.onPreviousChapter != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onPreviousChapter,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(widget.previousChapterLabel ?? 'پچھلا باب'),
                ),
              ),
            if (widget.onPreviousChapter != null &&
                widget.onNextChapter != null)
              const SizedBox(width: 12),
            if (widget.onNextChapter != null)
              Expanded(
                child: FilledButton.icon(
                  onPressed: widget.onNextChapter,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(widget.nextChapterLabel ?? 'اگلا باب'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
