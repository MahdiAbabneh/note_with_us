import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';

/// Plays the reveal and shows the letter.
void openCapsule(BuildContext context, Capsule capsule) {
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black54,
      transitionDuration: Motion.slow,
      pageBuilder: (_, _, _) => CapsuleOpenScreen(capsule: capsule),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// The opened capsule, revealed with a seal-breaking animation.
class CapsuleOpenScreen extends StatefulWidget {
  const CapsuleOpenScreen({super.key, required this.capsule});

  final Capsule capsule;

  @override
  State<CapsuleOpenScreen> createState() => _CapsuleOpenScreenState();
}

class _CapsuleOpenScreenState extends State<CapsuleOpenScreen> {
  bool _revealed = false;
  late final Future<String> _text = Session.instance.capsules.readText(
    widget.capsule,
  );

  @override
  void initState() {
    super.initState();
    final capsule = widget.capsule;
    if (!capsule.opened && capsule.recipientId == Session.instance.uid) {
      _text.then((text) => Session.instance.capsules.markOpened(capsule, text));
    }
  }

  void _reveal() {
    HapticFeedback.heavyImpact();
    setState(() => _revealed = true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final capsule = widget.capsule;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: AnimatedSwitcher(
                duration: Motion.slow,
                switchInCurve: Motion.ease,
                child: _revealed
                    ? _Letter(capsule: capsule, text: _text)
                    : _SealedEnvelope(onOpen: _reveal),
              ),
            ),
            PositionedDirectional(
              top: Space.md,
              end: Space.md,
              child: CircleIconButton(
                icon: CupertinoIcons.xmark,
                color: c.raised,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SealedEnvelope extends StatelessWidget {
  const _SealedEnvelope({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onOpen,
      child: Column(
        key: const ValueKey('sealed'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.accent,
                  boxShadow: [
                    BoxShadow(
                      color: c.accent.withValues(alpha: 0.6),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  CupertinoIcons.sparkles,
                  size: 48,
                  color: c.onAccent,
                ),
              )
              .animate(onPlay: (ctl) => ctl.repeat(reverse: true))
              .scaleXY(end: 1.06, duration: 1100.ms, curve: Curves.easeInOut)
              .animate()
              .scale(
                begin: const Offset(0.4, 0.4),
                curve: Motion.pop,
                duration: 600.ms,
              ),
          const SizedBox(height: Space.xl),
          Text(
            'Tap to break the seal'.tr,
            style: context.text.headline.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _Letter extends StatelessWidget {
  const _Letter({required this.capsule, required this.text});

  final Capsule capsule;
  final Future<String> text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final from = capsule.isToSelf ? 'You'.tr : capsule.ownerName;
    return Container(
          key: const ValueKey('letter'),
          margin: const EdgeInsets.all(Space.gutter),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: c.moodTint(capsule.mood) == c.raised
                ? c.surface
                : c.moodTint(capsule.mood),
            borderRadius: BorderRadius.circular(Radii.xl),
            boxShadow: softShadow(c, strength: 3),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Space.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Written {date}'.tr.replaceAll(
                    '{date}',
                    fullDate(capsule.createdAt),
                  ),
                  style: t.overline,
                ),
                const SizedBox(height: Space.md),
                FutureBuilder<String>(
                  future: text,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Text(
                        'This capsule can’t be opened yet.'.tr,
                        style: t.body.copyWith(color: c.inkSoft),
                      );
                    }
                    if (!snap.hasData) {
                      return const Column(
                        children: [
                          Skeleton(),
                          SizedBox(height: Space.xs),
                          Skeleton(width: 200),
                        ],
                      );
                    }
                    return ContentText(
                      snap.data!,
                      style: t.noteBody.copyWith(fontSize: 22),
                    ).animate().fadeIn(delay: 250.ms, duration: 700.ms);
                  },
                ),
                const SizedBox(height: Space.xl),
                Row(
                  children: [
                    Avatar(
                      url: capsule.ownerImage,
                      name: capsule.ownerName,
                      size: 32,
                    ),
                    const SizedBox(width: Space.sm),
                    Text('— $from', style: t.title.copyWith(fontSize: 20)),
                    const Spacer(),
                    Text(
                      capsule.mood.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
        .animate()
        .slideY(begin: 0.25, curve: Motion.pop, duration: 600.ms)
        .fadeIn();
  }
}
