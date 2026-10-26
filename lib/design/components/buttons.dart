import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../tokens.dart';
import 'pressable.dart';

/// Visual weight of an [NwuButton].
enum ButtonTone { ink, accent, outline, ghost, danger }

/// The app's pill button.
class NwuButton extends StatelessWidget {
  const NwuButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = ButtonTone.ink,
    this.icon,
    this.leading,
    this.loading = false,
    this.expand = true,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonTone tone;
  final IconData? icon;
  final Widget? leading;
  final bool loading;
  final bool expand;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg, border) = switch (tone) {
      ButtonTone.ink => (c.ink, c.canvas, Colors.transparent),
      ButtonTone.accent => (c.accent, c.onAccent, Colors.transparent),
      ButtonTone.outline => (Colors.transparent, c.ink, c.line),
      ButtonTone.ghost => (Colors.transparent, c.ink, Colors.transparent),
      ButtonTone.danger => (
        c.danger.withValues(alpha: 0.1),
        c.danger,
        Colors.transparent,
      ),
    };
    final disabled = onPressed == null || loading;
    final height = compact ? 40.0 : 56.0;

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          CupertinoActivityIndicator(color: fg, radius: 9)
        else ...[
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          if (icon != null) ...[
            Icon(icon, size: compact ? 17 : 19, color: fg),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.label.copyWith(
                color: fg,
                fontSize: compact ? 14 : 16,
              ),
            ),
          ),
        ],
      ],
    );

    return Pressable(
      onTap: disabled ? null : onPressed,
      child: AnimatedOpacity(
        duration: Motion.fast,
        opacity: onPressed == null ? 0.4 : 1,
        child: AnimatedContainer(
          duration: Motion.base,
          curve: Motion.ease,
          height: height,
          padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(color: border, width: 1.2),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// A round icon button used in headers and toolbars.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 44,
    this.filled = true,
    this.color,
    this.iconColor,
    this.semanticLabel,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final bool filled;
  final Color? color;
  final Color? iconColor;
  final String? semanticLabel;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onPressed,
      scale: 0.9,
      semanticLabel: semanticLabel,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: filled ? (color ?? c.raised) : Colors.transparent,
              shape: BoxShape.circle,
              border: filled && color == null
                  ? Border.all(color: c.line)
                  : null,
            ),
            child: Icon(icon, size: size * 0.45, color: iconColor ?? c.ink),
          ),
          if (badge)
            PositionedDirectional(
              top: 2,
              end: 2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: c.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.canvas, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
