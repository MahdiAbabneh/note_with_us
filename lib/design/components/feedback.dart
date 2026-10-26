import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/l10n.dart';
import '../tokens.dart';
import 'buttons.dart';
import 'pressable.dart';

OverlayEntry? _toastEntry;

/// Shows a short message as a floating pill at the top of the screen.
void showToast(BuildContext context, String message, {bool error = false}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  HapticFeedback.lightImpact();
  _toastEntry?.remove();
  final c = context.colors;
  final t = context.text;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      top: MediaQuery.of(ctx).padding.top + Space.xs,
      left: Space.gutter,
      right: Space.gutter,
      child: IgnorePointer(
        child: Center(
          child:
              Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.md,
                        vertical: Space.sm,
                      ),
                      decoration: BoxDecoration(
                        color: c.isDark ? c.raised : c.ink,
                        borderRadius: BorderRadius.circular(Radii.pill),
                        boxShadow: softShadow(c, strength: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            error
                                ? CupertinoIcons.exclamationmark_circle_fill
                                : CupertinoIcons.checkmark_circle_fill,
                            size: 20,
                            color: error ? c.danger : c.success,
                          ),
                          const SizedBox(width: Space.xs),
                          Flexible(
                            child: Text(
                              message,
                              style: t.label.copyWith(
                                color: c.isDark ? c.ink : c.canvas,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: Motion.base)
                  .slideY(begin: -0.6, curve: Motion.pop, duration: Motion.slow)
                  .then(delay: 2200.ms)
                  .fadeOut(duration: Motion.base)
                  .slideY(end: -0.4),
        ),
      ),
    ),
  );
  _toastEntry = entry;
  overlay.insert(entry);
  Future.delayed(const Duration(milliseconds: 2800), () {
    if (_toastEntry == entry) _toastEntry = null;
    if (entry.mounted) entry.remove();
  });
}

/// Opens a rounded bottom sheet in the app's style.
Future<T?> showNwuSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool scrollable = false,
}) {
  // Colours come from the theme (and `ctx` below) rather than being
  // captured here, so the sheet restyles if the theme changes while open.
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: Space.sm),
            Container(
              width: 38,
              height: 5,
              decoration: BoxDecoration(
                color: ctx.colors.line,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
            ),
            // Full width even when the content is narrow (e.g. a grid of
            // avatars); otherwise the sheet shrinks to fit it.
            Flexible(
              child: SizedBox(width: double.infinity, child: builder(ctx)),
            ),
          ],
        ),
      ),
    ),
  );
}

/// One row in an action sheet.
class SheetAction {
  const SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
}

/// Shows a list of actions; the sheet closes before the action runs.
Future<void> showActionSheet(
  BuildContext context, {
  String? title,
  required List<SheetAction> actions,
}) {
  return showNwuSheet<void>(
    context,
    builder: (ctx) {
      final c = ctx.colors;
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.md,
          Space.md,
          Space.md,
          Space.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.xs,
                  0,
                  Space.xs,
                  Space.sm,
                ),
                child: Text(title, style: ctx.text.overline),
              ),
            for (final action in actions)
              Pressable(
                onTap: () {
                  Navigator.pop(ctx);
                  action.onTap();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.xs,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        action.icon,
                        size: 22,
                        color: action.destructive ? c.danger : c.ink,
                      ),
                      const SizedBox(width: Space.md),
                      Text(
                        action.label,
                        style: ctx.text.bodyStrong.copyWith(
                          color: action.destructive ? c.danger : c.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

/// Asks the user to confirm; resolves to `true` when they agree.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showNwuSheet<bool>(
    context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.xl,
        Space.lg,
        Space.xl,
        Space.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ctx.text.title),
          const SizedBox(height: Space.xs),
          Text(message, style: ctx.text.small),
          const SizedBox(height: Space.xl),
          NwuButton(
            label: confirmLabel,
            tone: destructive ? ButtonTone.danger : ButtonTone.ink,
            onPressed: () => Navigator.pop(ctx, true),
          ),
          const SizedBox(height: Space.xs),
          NwuButton(
            label: 'Cancel'.tr,
            tone: ButtonTone.ghost,
            onPressed: () => Navigator.pop(ctx, false),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

/// Friendly placeholder for empty lists.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String emoji;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.xxl,
        vertical: Space.xxxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 38)),
              )
              .animate(onPlay: (ctl) => ctl.repeat(reverse: true))
              .moveY(
                begin: 0,
                end: -6,
                duration: 1800.ms,
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: Space.lg),
          Text(title, style: context.text.title, textAlign: TextAlign.center),
          const SizedBox(height: Space.xs),
          Text(message, style: context.text.small, textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: Space.lg),
            NwuButton(
              label: actionLabel!,
              onPressed: onAction,
              expand: false,
              compact: true,
              tone: ButtonTone.accent,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: Motion.slow).slideY(begin: 0.05);
  }
}

/// Shown when content fails to load, with a way to try again.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.onRetry, this.compact = false});

  final VoidCallback onRetry;

  /// A single row instead of a full centred block, for inline sections.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.gutter,
          vertical: Space.sm,
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.wifi_exclamationmark, size: 18, color: c.muted),
            const SizedBox(width: Space.xs),
            Expanded(
              child: Text('Couldn’t load this'.tr, style: context.text.small),
            ),
            NwuButton(
              label: 'Try again'.tr,
              tone: ButtonTone.outline,
              compact: true,
              expand: false,
              onPressed: onRetry,
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.xxl,
        vertical: Space.xxxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle),
            child: Icon(
              CupertinoIcons.wifi_exclamationmark,
              size: 30,
              color: c.muted,
            ),
          ),
          const SizedBox(height: Space.lg),
          Text(
            'Couldn’t load this'.tr,
            style: context.text.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.xs),
          Text(
            'Check your connection and try again.'.tr,
            style: context.text.small,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Space.lg),
          NwuButton(
            label: 'Try again'.tr,
            tone: ButtonTone.outline,
            compact: true,
            expand: false,
            icon: CupertinoIcons.refresh,
            onPressed: onRetry,
          ),
        ],
      ),
    ).animate().fadeIn(duration: Motion.base);
  }
}

/// Shimmering placeholder block shown while content loads.
class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.height = 16, this.width, this.radius = 8});

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: c.line.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(radius),
          ),
        )
        .animate(onPlay: (ctl) => ctl.repeat())
        .shimmer(duration: 1400.ms, color: c.raised.withValues(alpha: 0.6));
  }
}

/// Placeholder shaped like a note card.
class NoteSkeleton extends StatelessWidget {
  const NoteSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        Space.gutter,
        0,
        Space.gutter,
        Space.md,
      ),
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Skeleton(height: 40, width: 40, radius: 20),
              SizedBox(width: Space.sm),
              Skeleton(width: 120),
            ],
          ),
          SizedBox(height: Space.lg),
          Skeleton(),
          SizedBox(height: Space.xs),
          Skeleton(width: 220),
        ],
      ),
    );
  }
}
