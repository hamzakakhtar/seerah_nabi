import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:seerat_un_nabi/features/seerah_chapters/domain/chapter_models.dart';

/// Renders a Seerah [ParagraphModel] with individual [HistoricalClaimModel]
/// spans colored according to their [ReliabilityStatus], while keeping the
/// Urdu narrative uninterrupted and clean.
class ClaimRichParagraph extends StatefulWidget {
  const ClaimRichParagraph({
    super.key,
    required this.paragraph,
    required this.fontSize,
    required this.onClaimTap,
    this.selectedClaimId,
  });

  final ParagraphModel paragraph;
  final double fontSize;
  final ValueChanged<HistoricalClaimModel> onClaimTap;
  final String? selectedClaimId;

  @override
  State<ClaimRichParagraph> createState() => _ClaimRichParagraphState();
}

class _ClaimRichParagraphState extends State<ClaimRichParagraph> {
  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];

  @override
  void initState() {
    super.initState();
    _rebuildRecognizers();
  }

  @override
  void didUpdateWidget(covariant ClaimRichParagraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paragraph.stableId != widget.paragraph.stableId ||
        oldWidget.paragraph.claims.length != widget.paragraph.claims.length) {
      _disposeRecognizers();
      _rebuildRecognizers();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _rebuildRecognizers() {
    for (final claim in widget.paragraph.claims) {
      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onClaimTap(claim);
      _recognizers.add(recognizer);
    }
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyLarge?.copyWith(
      fontSize: widget.fontSize,
    );

    if (widget.paragraph.claims.isEmpty) {
      return SelectableText(
        widget.paragraph.plainText,
        style: baseStyle,
        textAlign: TextAlign.justify,
      );
    }

    final spans = <InlineSpan>[];
    for (var i = 0; i < widget.paragraph.claims.length; i++) {
      final claim = widget.paragraph.claims[i];
      final claimColor =
          claim.reliabilityStatus.colorForBrightness(theme.brightness);
      final isSelected = widget.selectedClaimId == claim.stableId;

      spans.add(
        TextSpan(
          text: claim.claimText,
          recognizer: i < _recognizers.length ? _recognizers[i] : null,
          style: baseStyle?.copyWith(
            color: claimColor,
            backgroundColor: isSelected
                ? claimColor.withValues(alpha: 0.14)
                : Colors.transparent,
          ),
        ),
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.justify,
    );
  }
}
