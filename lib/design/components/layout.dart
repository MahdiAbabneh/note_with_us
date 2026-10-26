import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../tokens.dart';
import 'buttons.dart';
import 'pressable.dart';

/// Large serif page title with optional overline and trailing actions.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.overline,
    this.actions = const [],
  });

  final String title;
  final String? overline;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.md,
        Space.gutter,
        Space.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overline != null) ...[
                  Text(overline!.toUpperCase(), style: context.text.overline),
                  const SizedBox(height: Space.xxs),
                ],
                Text(title, style: context.text.display),
              ],
            ),
          ),
          for (final action in actions) ...[
            const SizedBox(width: Space.xs),
            action,
          ],
        ],
      ),
    );
  }
}

/// Compact top bar for pushed screens: back button, title, actions.
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions = const [],
    this.close = false,
  });

  final String? title;
  final Widget? titleWidget;
  final List<Widget> actions;

  /// Shows an X instead of a back chevron, for modal screens.
  final bool close;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 60,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.md),
          child: Row(
            children: [
              CircleIconButton(
                icon: close
                    ? CupertinoIcons.xmark
                    : (rtl
                          ? CupertinoIcons.chevron_right
                          : CupertinoIcons.chevron_left),
                size: 40,
                semanticLabel: close ? 'Close' : 'Back',
                onPressed: () => Navigator.maybePop(context),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child:
                    titleWidget ??
                    Text(
                      title ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.headline,
                    ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

/// Small uppercase section label.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing, this.inset = true});

  final String text;
  final Widget? trailing;

  /// Whether to add the page gutter; turn off inside padded lists.
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final side = inset ? Space.gutter : 0.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(side, Space.xl, side, Space.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(text.toUpperCase(), style: context.text.overline),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Pill-shaped segmented control with a sliding thumb.
class SegmentedPills extends StatelessWidget {
  const SegmentedPills({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: c.line),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth / labels.length;
          final rtl = Directionality.of(context) == TextDirection.rtl;
          final offset = width * index;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: Motion.base,
                curve: Motion.ease,
                left: rtl ? null : offset,
                right: rtl ? offset : null,
                top: 0,
                bottom: 0,
                width: width,
                child: Container(
                  decoration: BoxDecoration(
                    color: c.ink,
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: Pressable(
                        scale: 1,
                        onTap: () => onChanged(i),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: Motion.base,
                            style: context.text.label.copyWith(
                              color: i == index ? c.canvas : c.inkSoft,
                            ),
                            child: Text(labels[i]),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Small rounded tag.
class Tag extends StatelessWidget {
  const Tag({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.background,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = color ?? c.inkSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? c.ink.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: context.text.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A grouped settings-style list container.
class GroupedList extends StatelessWidget {
  const GroupedList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Space.gutter),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: c.line.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 56),
                child: Divider(color: c.line.withValues(alpha: 0.7)),
              ),
          ],
        ],
      ),
    );
  }
}

/// A row inside [GroupedList].
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.trailing,
    this.destructive = false,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final tint = destructive ? c.danger : (iconColor ?? c.ink);
    return Pressable(
      onTap: onTap,
      scale: 0.99,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 18, color: tint),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.text.bodyStrong.copyWith(
                      color: destructive ? c.danger : c.ink,
                    ),
                  ),
                  if (subtitle != null)
                    Text(subtitle!, style: context.text.caption),
                ],
              ),
            ),
            if (value != null)
              Text(value!, style: context.text.small.copyWith(color: c.muted)),
            if (trailing != null)
              trailing!
            else if (onTap != null && !destructive)
              Icon(
                rtl
                    ? CupertinoIcons.chevron_left
                    : CupertinoIcons.chevron_right,
                size: 16,
                color: c.muted,
              ),
          ],
        ),
      ),
    );
  }
}
