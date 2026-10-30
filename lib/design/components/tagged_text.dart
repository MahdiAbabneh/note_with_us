import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../../core/tags.dart';
import '../tokens.dart';
import 'content_text.dart';

/// A note's text with its `#tags` picked out in the accent colour. When
/// [onTag] is given the tags can be tapped.
class TaggedText extends StatefulWidget {
  const TaggedText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.onTag,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final ValueChanged<String>? onTag;

  @override
  State<TaggedText> createState() => _TaggedTextState();
}

class _TaggedTextState extends State<TaggedText> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The previous frame's recognizers are still in the tree until this
    // build lands, so they are released just after it.
    final previous = [..._recognizers];
    _recognizers.clear();
    if (previous.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final r in previous) {
          r.dispose();
        }
      });
    }
    final accent = context.colors.accent;
    final onTag = widget.onTag;
    final spans = <InlineSpan>[
      for (final part in splitTags(widget.text))
        if (part.isTag)
          TextSpan(
            text: part.text,
            style: TextStyle(color: accent, fontWeight: FontWeight.w700),
            recognizer: onTag == null
                ? null
                : (TapGestureRecognizer()..onTap = () => onTag(part.tag!)),
          )
        else
          TextSpan(text: part.text),
    ];
    for (final span in spans) {
      if (span is TextSpan && span.recognizer is TapGestureRecognizer) {
        _recognizers.add(span.recognizer! as TapGestureRecognizer);
      }
    }
    return SizedBox(
      width: double.infinity,
      child: Text.rich(
        TextSpan(children: spans),
        textDirection: contentDirection(widget.text),
        textAlign: TextAlign.start,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      ),
    );
  }
}
