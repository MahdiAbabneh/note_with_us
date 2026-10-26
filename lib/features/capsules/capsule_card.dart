import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import 'capsule_open_screen.dart';

/// A capsule drawn as a sealed envelope.
class CapsuleCard extends StatelessWidget {
  const CapsuleCard({super.key, required this.capsule});

  final Capsule capsule;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final session = Session.instance;
    final incoming = capsule.recipientId == session.uid;
    final ready = capsule.isUnlocked;
    final canRead = ready && incoming;

    final who = capsule.isToSelf
        ? 'To future you'.tr
        : incoming
        ? 'From {name}'.tr.replaceAll('{name}', capsule.ownerName)
        : 'To {name}'.tr.replaceAll('{name}', capsule.recipientName);

    return Pressable(
      onTap: () {
        if (canRead) {
          openCapsule(context, capsule);
        } else {
          showToast(context, countdown(capsule.unlockAt));
        }
      },
      onLongPress: () => _showActions(context),
      child: Container(
        padding: const EdgeInsets.all(Space.lg),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.moodTint(capsule.mood),
          borderRadius: BorderRadius.circular(Radii.lg),
          border: capsule.mood == Mood.plain
              ? Border.all(color: c.line.withValues(alpha: 0.7))
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: CustomPaint(painter: _FlapPainter(c.ink))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Seal(ready: ready, opened: capsule.opened),
                    const SizedBox(width: Space.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(who, style: t.headline),
                          const SizedBox(height: 2),
                          Text(
                            'Sealed {date}'.tr.replaceAll(
                              '{date}',
                              fullDate(capsule.createdAt),
                            ),
                            style: t.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.lg),
                if (capsule.opened && incoming)
                  ContentText(
                    capsule.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: t.noteBody,
                  )
                else
                  Row(
                    children: [
                      Icon(
                        ready
                            ? CupertinoIcons.envelope_open
                            : CupertinoIcons.lock,
                        size: 16,
                        color: ready ? c.accent : c.inkSoft,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          canRead
                              ? 'Ready — tap to open'.tr
                              : ready
                              ? 'Delivered'.tr
                              : '${countdown(capsule.unlockAt)} · ${fullDate(capsule.unlockAt)}',
                          style: t.label.copyWith(
                            color: ready ? c.accent : c.inkSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    showActionSheet(
      context,
      actions: [
        SheetAction(
          icon: CupertinoIcons.trash,
          label: 'Delete capsule'.tr,
          destructive: true,
          onTap: () async {
            final ok = await confirm(
              context,
              title: 'Delete this capsule?'.tr,
              message: 'This can’t be undone.'.tr,
              confirmLabel: 'Delete'.tr,
              destructive: true,
            );
            if (!ok) return;
            try {
              await Session.instance.capsules.delete(capsule);
              if (context.mounted) showToast(context, 'Capsule deleted'.tr);
            } catch (_) {
              if (context.mounted) {
                showToast(context, 'Something went wrong'.tr, error: true);
              }
            }
          },
        ),
      ],
    );
  }
}

class _Seal extends StatelessWidget {
  const _Seal({required this.ready, required this.opened});

  final bool ready;
  final bool opened;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final seal = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: opened ? c.surface : c.accent,
        border: Border.all(color: c.accent.withValues(alpha: 0.5), width: 3),
      ),
      child: Icon(
        opened
            ? CupertinoIcons.envelope_open
            : (ready ? CupertinoIcons.sparkles : CupertinoIcons.hourglass),
        color: opened ? c.accent : c.onAccent,
        size: 22,
      ),
    );
    if (!ready || opened) return seal;
    return seal
        .animate(onPlay: (ctl) => ctl.repeat(reverse: true))
        .scaleXY(end: 1.08, duration: 900.ms, curve: Curves.easeInOut);
  }
}

/// Draws a faint envelope flap across the card.
class _FlapPainter extends CustomPainter {
  _FlapPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..moveTo(-Space.lg, -Space.lg)
      ..lineTo(size.width / 2, size.height * 0.42)
      ..lineTo(size.width + Space.lg, -Space.lg);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_FlapPainter old) => old.color != color;
}
