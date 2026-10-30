import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../tokens.dart';
import 'content_text.dart';

/// Labelled text field with a soft filled style and accent focus ring.
class NwuField extends StatefulWidget {
  const NwuField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.icon,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
    this.maxLines = 1,
    this.maxLength,
    this.autofillHints,
    this.readOnly = false,
    this.onTap,
    this.trailing,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final int maxLines;
  final int? maxLength;
  final Iterable<String>? autofillHints;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? trailing;
  final TextCapitalization textCapitalization;

  @override
  State<NwuField> createState() => _NwuFieldState();
}

class _NwuFieldState extends State<NwuField> {
  final _focus = FocusNode();
  late bool _hidden = widget.obscure;

  /// Direction of the typed text at the last rebuild. The field follows
  /// the text, so English stays left-to-right in the Arabic app and the
  /// other way round; this only avoids rebuilding on every keystroke.
  TextDirection? _direction;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    widget.controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(NwuField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    _focus.dispose();
    super.dispose();
  }

  void _onText() {
    final direction = inputDirection(context, widget.controller.text);
    if (direction != _direction) setState(() => _direction = direction);
  }

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final focused = _focus.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: t.label.copyWith(color: c.inkSoft)),
          const SizedBox(height: Space.xs),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: _focus,
          obscureText: _hidden,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onFieldSubmitted: widget.onSubmitted,
          maxLines: widget.obscure ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          autofillHints: widget.autofillHints,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          textCapitalization: widget.textCapitalization,
          textDirection: inputDirection(context, widget.controller.text),
          style: t.body,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: t.body.copyWith(color: c.muted),
            filled: true,
            fillColor: focused ? c.raised : c.surface,
            counterText: '',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Space.md,
              vertical: 17,
            ),
            prefixIcon: widget.icon == null
                ? null
                : Icon(
                    widget.icon,
                    size: 20,
                    color: focused ? c.accent : c.muted,
                  ),
            suffixIcon: widget.obscure
                ? IconButton(
                    onPressed: () => setState(() => _hidden = !_hidden),
                    icon: Icon(
                      _hidden ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                      size: 20,
                      color: c.muted,
                    ),
                  )
                : widget.trailing,
            enabledBorder: _border(c.line),
            focusedBorder: _border(c.accent, 1.6),
            errorBorder: _border(c.danger),
            focusedErrorBorder: _border(c.danger, 1.6),
            errorStyle: t.caption.copyWith(color: c.danger),
          ),
        ),
      ],
    );
  }
}

/// Rounded search box.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: c.line),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Space.md),
      child: Row(
        children: [
          Icon(CupertinoIcons.search, size: 19, color: c.muted),
          const SizedBox(width: Space.xs),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autofocus: autofocus,
              style: context.text.body,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: context.text.body.copyWith(color: c.muted),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
