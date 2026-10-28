import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/format.dart';
import '../../core/insights.dart';
import '../../core/l10n.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';

/// A jar that fills with a bead for each thing you are grateful for. Add
/// three a day; at the end of the month read them all.
class GratitudeScreen extends StatefulWidget {
  const GratitudeScreen({super.key});

  @override
  State<GratitudeScreen> createState() => _GratitudeScreenState();
}

class _GratitudeScreenState extends State<GratitudeScreen> {
  final _session = Session.instance;
  late Stream<List<Note>> _notes = _session.notes.journal(
    _session.uid,
    limit: 400,
  );
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  bool get _isCurrentMonth =>
      _month == DateTime(DateTime.now().year, DateTime.now().month);

  void _shift(int months) {
    final next = DateTime(_month.year, _month.month + months);
    if (next.isAfter(DateTime(DateTime.now().year, DateTime.now().month))) {
      return;
    }
    setState(() => _month = next);
  }

  Future<void> _add() async {
    final saved = await showNwuSheet<bool>(
      context,
      builder: (_) => const _AddSheet(),
    );
    if (saved == true && mounted) {
      showToast(context, 'Added to your jar 🫙'.tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: TopBar(
        title: 'Gratitude jar'.tr,
        actions: [
          CircleIconButton(
            icon: CupertinoIcons.add,
            size: 40,
            semanticLabel: 'Add to the jar'.tr,
            onPressed: _add,
          ),
        ],
      ),
      body: StreamBuilder<List<Note>>(
        stream: _notes,
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorState(
              onRetry: () => setState(
                () => _notes = _session.notes.journal(_session.uid, limit: 400),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CupertinoActivityIndicator());
          }
          final items = gratitudeItems(snap.data!, month: _month);
          final rtl = Directionality.of(context) == TextDirection.rtl;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              Space.gutter,
              Space.sm,
              Space.gutter,
              MediaQuery.of(context).padding.bottom + Space.xxl,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(monthYear(_month), style: context.text.display),
                  ),
                  CircleIconButton(
                    icon: rtl
                        ? CupertinoIcons.chevron_right
                        : CupertinoIcons.chevron_left,
                    size: 40,
                    semanticLabel: 'Previous month'.tr,
                    onPressed: () => _shift(-1),
                  ),
                  const SizedBox(width: Space.xs),
                  CircleIconButton(
                    icon: rtl
                        ? CupertinoIcons.chevron_left
                        : CupertinoIcons.chevron_right,
                    size: 40,
                    semanticLabel: 'Next month'.tr,
                    onPressed: _isCurrentMonth ? null : () => _shift(1),
                  ),
                ],
              ),
              const SizedBox(height: Space.xs),
              Text(
                (items.length == 1
                        ? '1 thing you are grateful for'
                        : '{n} things you are grateful for')
                    .tr
                    .replaceAll('{n}', '${items.length}'),
                style: context.text.body.copyWith(color: c.inkSoft),
              ),
              const SizedBox(height: Space.lg),
              Center(child: JarView(beads: items.length)),
              const SizedBox(height: Space.lg),
              if (_isCurrentMonth)
                NwuButton(
                  label: 'Add today’s gratitude'.tr,
                  icon: CupertinoIcons.heart,
                  tone: ButtonTone.accent,
                  onPressed: _add,
                ),
              if (items.isEmpty) ...[
                const SizedBox(height: Space.lg),
                Text(
                  'Nothing in the jar this month yet.'.tr,
                  style: context.text.body.copyWith(color: c.inkSoft),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                const SizedBox(height: Space.xl),
                Text('READ YOUR JAR'.tr, style: context.text.overline),
                const SizedBox(height: Space.sm),
                for (final (i, item) in items.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.xs),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.md,
                        vertical: Space.sm,
                      ),
                      decoration: BoxDecoration(
                        color: c.raised,
                        borderRadius: BorderRadius.circular(Radii.md),
                        border: Border.all(
                          color: c.line.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: beadColor(c, items.length - 1 - i),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: Space.sm),
                          Expanded(
                            child: ContentText(
                              item.text,
                              style: context.text.body,
                            ),
                          ),
                          const SizedBox(width: Space.xs),
                          Text(
                            relativeTime(item.time),
                            style: context.text.caption,
                          ),
                        ],
                      ),
                    ).animate(delay: (i.clamp(0, 10) * 30).ms).fadeIn(),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// The colour of the [index]-th bead: the mood colours in turn.
Color beadColor(NwuColors c, int index) {
  const moods = [
    Mood.joy,
    Mood.love,
    Mood.calm,
    Mood.dreamy,
    Mood.fired,
    Mood.blue,
  ];
  return c.moodInk(moods[index % moods.length]);
}

/// A glass jar with [beads] coloured beads settled at the bottom.
class JarView extends StatelessWidget {
  const JarView({super.key, required this.beads});

  final int beads;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: 240,
      height: 280,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: beads.toDouble()),
        duration: Motion.slow * 2,
        curve: Curves.easeOutCubic,
        builder: (context, shown, _) => CustomPaint(
          painter: JarPainter(
            shownBeads: shown,
            glass: c.line,
            lid: c.accent,
            colors: [for (var i = 0; i < 120; i++) beadColor(c, i)],
          ),
        ),
      ),
    );
  }
}

class JarPainter extends CustomPainter {
  JarPainter({
    required this.shownBeads,
    required this.glass,
    required this.lid,
    required this.colors,
  });

  /// How many beads to draw; fractional while filling up.
  final double shownBeads;
  final Color glass;
  final Color lid;
  final List<Color> colors;

  static const _beadRadius = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.14, w * 0.84, h * 0.84),
      const Radius.circular(28),
    );

    // Beads settle from the bottom in rows, slightly jittered; spots that
    // fall outside the rounded glass are skipped.
    final inner = body.deflate(8);
    // A little slack so the jitter never drops a spot in the middle of a row.
    final area = body.deflate(8 + _beadRadius - 4);
    final cols = (inner.width / (_beadRadius * 2)).floor();
    final count = shownBeads.floor().clamp(0, 120);
    var placed = 0;
    for (var slot = 0; placed < count && slot < cols * 40; slot++) {
      final row = slot ~/ cols;
      final col = slot % cols;
      final stagger = row.isOdd ? _beadRadius : 0.0;
      final random = math.Random(slot * 7919);
      final x =
          inner.left +
          _beadRadius +
          col * _beadRadius * 2 +
          stagger +
          (random.nextDouble() - 0.5) * 3;
      final y =
          inner.bottom -
          _beadRadius -
          row * _beadRadius * 1.75 +
          (random.nextDouble() - 0.5) * 3;
      final center = Offset(x, y);
      if (!area.contains(center)) continue;
      canvas.drawCircle(
        center,
        _beadRadius - 0.5,
        Paint()..color = colors[placed % colors.length],
      );
      canvas.drawCircle(
        Offset(x - 3, y - 3),
        2.2,
        Paint()..color = const Color(0x66FFFFFF),
      );
      placed++;
    }

    // Glass and lid.
    canvas.drawRRect(
      body,
      Paint()
        ..color = glass
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.2, h * 0.02, w * 0.6, h * 0.1),
        const Radius.circular(10),
      ),
      Paint()..color = lid,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.14, h * 0.115, w * 0.72, h * 0.04),
        const Radius.circular(8),
      ),
      Paint()..color = glass,
    );
  }

  @override
  bool shouldRepaint(JarPainter old) =>
      old.shownBeads != shownBeads || old.glass != glass || old.lid != lid;
}

/// Three fields for the day's gratitude.
class _AddSheet extends StatefulWidget {
  const _AddSheet();

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final _session = Session.instance;
  final _fields = List.generate(3, (_) => TextEditingController());
  bool _saving = false;

  @override
  void dispose() {
    for (final f in _fields) {
      f.dispose();
    }
    super.dispose();
  }

  List<String> get _lines => [
    for (final f in _fields)
      if (f.text.trim().isNotEmpty) f.text.trim().replaceAll('\n', ' '),
  ];

  Future<void> _save() async {
    final lines = _lines;
    if (lines.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await _session.notes.create(
        author: _session.me,
        audience: Audience.private,
        text: lines.join('\n'),
        mood: Mood.love,
        prompt: 'Gratitude jar'.tr,
        kind: gratitudeKind,
      );
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showToast(context, 'Something went wrong'.tr, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.md,
        Space.gutter,
        Space.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What are you grateful for today?'.tr,
            style: context.text.title,
          ),
          const SizedBox(height: Space.xs),
          Text(
            'Up to three things, big or small. Each one becomes a bead.'.tr,
            style: context.text.small,
          ),
          const SizedBox(height: Space.md),
          for (final (i, field) in _fields.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: NwuField(
                controller: field,
                hint: '${i + 1}.  ${'I am grateful for…'.tr}',
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          const SizedBox(height: Space.xs),
          ListenableBuilder(
            listenable: Listenable.merge(_fields),
            builder: (context, _) => NwuButton(
              label: 'Drop in the jar'.tr,
              tone: ButtonTone.accent,
              loading: _saving,
              onPressed: _lines.isEmpty ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}
