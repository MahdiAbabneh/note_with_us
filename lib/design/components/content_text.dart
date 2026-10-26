import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show Bidi;

/// The direction of what someone wrote, regardless of the app language:
/// an English note stays left-to-right inside the Arabic UI and an Arabic
/// note stays right-to-left inside the English one.
TextDirection contentDirection(String text) =>
    Bidi.detectRtlDirectionality(text) ? TextDirection.rtl : TextDirection.ltr;

/// Direction for a text field: follows what is typed, and the app's
/// direction while the field is empty so the hint sits where expected.
TextDirection inputDirection(BuildContext context, String text) =>
    text.trim().isEmpty ? Directionality.of(context) : contentDirection(text);

/// Text written by a person (notes, replies, messages, capsules), laid out
/// in its own direction and aligned to its own start.
class ContentText extends StatelessWidget {
  const ContentText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.fill = true,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  /// Takes the full width so short text lines up with its own start edge;
  /// turn off inside bubbles that should hug their content.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      text,
      textDirection: contentDirection(text),
      textAlign: TextAlign.start,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
    return fill ? SizedBox(width: double.infinity, child: child) : child;
  }
}
