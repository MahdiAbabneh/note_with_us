import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/format.dart';
import '../../core/insights.dart';
import '../../core/l10n.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import '../compose/compose_screen.dart';

/// Every note you write grows a plant, coloured by how you felt. A month
/// of writing becomes a garden of your feelings. Built on the phone from
/// your own notes; nothing is shared.
class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  final _session = Session.instance;
  late Stream<List<Note>> _notes = _session.notes.mine(_session.uid);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(title: 'Your garden'.tr),
      body: StreamBuilder<List<Note>>(
        stream: _notes,
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorState(
              onRetry: () =>
                  setState(() => _notes = _session.notes.mine(_session.uid)),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CupertinoActivityIndicator());
          }
          final now = DateTime.now();
          final plants = gardenNotes(snap.data!, now);
          if (plants.isEmpty) {
            return EmptyState(
              emoji: '🌱',
              title: 'Your garden is waiting'.tr,
              message:
                  'Write a note and your first plant will start to grow.'.tr,
              actionLabel: 'Write a note'.tr,
              onAction: () =>
                  openComposer(context, target: ComposeTarget.private),
            );
          }
          final counts = <Mood, int>{};
          for (final note in plants) {
            counts[note.mood] = (counts[note.mood] ?? 0) + 1;
          }
          return ListView(
            padding: EdgeInsets.fromLTRB(
              Space.gutter,
              Space.sm,
              Space.gutter,
              MediaQuery.of(context).padding.bottom + Space.xxl,
            ),
            children: [
              Text(
                (plants.length == 1
                        ? '1 plant in the last 30 days'
                        : '{n} plants in the last 30 days')
                    .tr
                    .replaceAll('{n}', '${plants.length}'),
                style: context.text.display,
              ),
              const SizedBox(height: Space.xs),
              Text(
                'New plants start small and grow over three days.'.tr,
                style: context.text.body.copyWith(
                  color: context.colors.inkSoft,
                ),
              ),
              const SizedBox(height: Space.lg),
              _Bed(plants: plants, now: now),
              const SizedBox(height: Space.xl),
              _Legend(counts: counts),
            ],
          );
        },
      ),
    );
  }
}

/// The garden bed: all plants in the order they were written.
class _Bed extends StatelessWidget {
  const _Bed({required this.plants, required this.now});

  final List<Note> plants;
  final DateTime now;

  static const _perRow = 5;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, box) {
        final cell = box.maxWidth / _perRow;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: Space.sm),
          decoration: BoxDecoration(
            color: c.raised,
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(color: c.line.withValues(alpha: 0.7)),
          ),
          child: Wrap(
            children: [
              for (final (i, note) in plants.indexed)
                Pressable(
                      scale: 0.92,
                      semanticLabel:
                          '${fullDate(note.time)}, ${note.mood.label.tr}',
                      onTap: () => showToast(
                        context,
                        '${note.mood == Mood.plain ? '🌱' : note.mood.emoji}  ${fullDate(note.time)}',
                      ),
                      child: SizedBox(
                        width: cell - 0.01,
                        height: cell * 1.2,
                        child: CustomPaint(
                          painter: PlantPainter(
                            mood: note.mood,
                            growth: plantGrowth(note.time, now),
                            seed: note.id.hashCode,
                            petal: c.moodInk(note.mood),
                            stem: c.success,
                            center: c.inkSoft,
                            soil: c.line,
                          ),
                        ),
                      ),
                    )
                    .animate(delay: (math.min(i, 30) * 35).ms)
                    .scale(
                      begin: const Offset(0.4, 0.4),
                      alignment: Alignment.bottomCenter,
                      curve: Motion.pop,
                      duration: Motion.slow,
                    )
                    .fadeIn(),
            ],
          ),
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.counts});

  final Map<Mood, int> counts;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Wrap(
      spacing: Space.xs,
      runSpacing: Space.xs,
      children: [
        for (final MapEntry(key: mood, value: count) in entries)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.sm,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: mood == Mood.plain ? c.surface : c.moodTint(mood),
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
            child: Text(
              '${mood == Mood.plain ? '🌱' : mood.emoji}  ${mood.label.tr} · $count',
              style: context.text.caption.copyWith(
                color: c.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

/// A single plant. The flower is chosen by mood; the size by [growth].
class PlantPainter extends CustomPainter {
  PlantPainter({
    required this.mood,
    required this.growth,
    required this.seed,
    required this.petal,
    required this.stem,
    required this.center,
    required this.soil,
  });

  final Mood mood;

  /// 0.45 (sprout) … 1 (full size).
  final double growth;

  /// Varies the lean of the stem so a garden doesn't look stamped.
  final int seed;
  final Color petal;
  final Color stem;
  final Color center;
  final Color soil;

  // Petal count, whether petals are pointed, and leaf pairs per mood.
  (int, bool, int) get _style => switch (mood) {
    Mood.joy => (10, false, 1),
    Mood.love => (5, false, 1),
    Mood.dreamy => (6, true, 1),
    Mood.fired => (8, true, 1),
    Mood.blue => (4, false, 1),
    Mood.calm => (0, false, 3),
    Mood.plain => (0, false, 1),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final (petals, pointed, leafPairs) = _style;
    final base = Offset(w / 2, h * 0.94);

    // Soil mound.
    canvas.drawOval(
      Rect.fromCenter(center: base, width: w * 0.5, height: h * 0.07),
      Paint()..color = soil,
    );

    final lean = ((seed.abs() % 7) - 3) * w * 0.012;
    final droop = mood == Mood.blue ? w * 0.12 * growth : 0.0;
    final stemHeight = h * 0.66 * growth;
    final top = Offset(w / 2 + lean + droop, base.dy - stemHeight);
    final control = Offset(w / 2 - lean, base.dy - stemHeight * 0.55);

    canvas.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(control.dx, control.dy, top.dx, top.dy),
      Paint()
        ..color = stem
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045
        ..strokeCap = StrokeCap.round,
    );

    // Leaves along the stem, alternating sides.
    final leaf = Paint()..color = stem;
    for (var i = 0; i < leafPairs; i++) {
      final t = leafPairs == 1 ? 0.45 : 0.25 + 0.5 * i / (leafPairs - 1);
      final at = Offset.lerp(base, top, t)!;
      for (final side in const [-1.0, 1.0]) {
        canvas
          ..save()
          ..translate(at.dx, at.dy)
          ..rotate(side * 0.75)
          ..drawOval(
            Rect.fromLTWH(
              side > 0 ? 0 : -w * 0.26 * growth,
              -w * 0.05 * growth,
              w * 0.26 * growth,
              w * 0.1 * growth,
            ),
            leaf,
          )
          ..restore();
      }
    }

    // A plain note, or a young plant, shows only a bud.
    if (petals == 0 || growth < 0.7) {
      if (petals > 0) {
        canvas.drawCircle(top, w * 0.07, Paint()..color = petal);
      } else if (mood == Mood.calm) {
        canvas.drawCircle(top, w * 0.05, Paint()..color = leaf.color);
      }
      return;
    }

    final radius = w * 0.17;
    final paint = Paint()..color = petal;
    for (var i = 0; i < petals; i++) {
      final angle = 2 * math.pi * i / petals;
      canvas
        ..save()
        ..translate(top.dx, top.dy)
        ..rotate(angle);
      if (pointed) {
        canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(radius * 0.45, -radius * 0.5, 0, -radius * 1.25)
            ..quadraticBezierTo(-radius * 0.45, -radius * 0.5, 0, 0),
          paint,
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(0, -radius * 0.7),
            width: radius * (petals > 6 ? 0.55 : 0.9),
            height: radius * 1.1,
          ),
          paint,
        );
      }
      canvas.restore();
    }
    canvas.drawCircle(top, radius * 0.38, Paint()..color = center);
  }

  @override
  bool shouldRepaint(PlantPainter old) =>
      old.mood != mood ||
      old.growth != growth ||
      old.seed != seed ||
      old.petal != petal ||
      old.stem != stem;
}
