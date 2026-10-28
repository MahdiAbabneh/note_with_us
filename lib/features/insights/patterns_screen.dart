import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/l10n.dart';
import '../../core/patterns.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import '../compose/compose_screen.dart';

/// What your own notes say about you, worked out on the phone: how you
/// tend to feel on each weekday, when you write, and the words you use.
class PatternsScreen extends StatefulWidget {
  const PatternsScreen({super.key});

  @override
  State<PatternsScreen> createState() => _PatternsScreenState();
}

class _PatternsScreenState extends State<PatternsScreen> {
  final _session = Session.instance;
  late Stream<List<Note>> _notes = _session.notes.mine(_session.uid);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(title: 'Your patterns'.tr),
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
          final patterns = Patterns.from(snap.data!, DateTime.now());
          if (!patterns.enough) {
            return EmptyState(
              emoji: '🔍',
              title: 'Patterns need a few more notes'.tr,
              message:
                  '{n} of {total} notes so far. Keep writing and they will appear.'
                      .tr
                      .replaceAll('{n}', '${patterns.notes}')
                      .replaceAll('{total}', '${Patterns.minNotes}'),
              actionLabel: 'Write a note'.tr,
              onAction: () =>
                  openComposer(context, target: ComposeTarget.private),
            );
          }
          return ListView(
            padding: EdgeInsets.fromLTRB(
              Space.gutter,
              Space.sm,
              Space.gutter,
              MediaQuery.of(context).padding.bottom + Space.xxl,
            ),
            children:
                [
                      _WeekdayCard(patterns: patterns),
                      const SizedBox(height: Space.md),
                      _DayPartCard(patterns: patterns),
                      if (patterns.topWords.isNotEmpty) ...[
                        const SizedBox(height: Space.md),
                        _WordsCard(words: patterns.topWords),
                      ],
                      if (patterns.lately != null &&
                          patterns.before != null) ...[
                        const SizedBox(height: Space.md),
                        _LatelyCard(patterns: patterns),
                      ],
                      const SizedBox(height: Space.lg),
                      Text(
                        'Worked out on your phone from your own notes. Nothing is sent anywhere.'
                            .tr,
                        style: context.text.caption,
                        textAlign: TextAlign.center,
                      ),
                    ]
                    .animate(interval: 70.ms)
                    .fadeIn(duration: Motion.slow)
                    .slideY(begin: 0.04),
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: c.line.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: context.text.overline),
          const SizedBox(height: Space.sm),
          child,
        ],
      ),
    );
  }
}

String _weekdayName(int weekday) => DateFormat.EEEE(
  L10n.arabic ? 'ar' : 'en',
).format(DateTime(2024, 1, weekday));

class _WeekdayCard extends StatelessWidget {
  const _WeekdayCard({required this.patterns});

  final Patterns patterns;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final byDay = {for (final w in patterns.weekdays) w.weekday: w};
    final standouts = patterns.standouts;
    return _Card(
      title: 'How you feel through the week'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var d = 1; d <= 7; d++)
                Column(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: byDay[d] == null
                            ? null
                            : c.moodTint(byDay[d]!.mood),
                        border: byDay[d] == null
                            ? Border.all(color: c.line, width: 1.5)
                            : null,
                      ),
                      child: Text(
                        byDay[d]?.mood.emoji ?? '',
                        style: const TextStyle(fontSize: 18, height: 1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.E(
                        L10n.arabic ? 'ar' : 'en',
                      ).format(DateTime(2024, 1, d)),
                      style: context.text.caption,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          if (standouts.isEmpty)
            Text(
              'No weekday stands out yet.'.tr,
              style: context.text.body.copyWith(color: c.inkSoft),
            )
          else
            for (final w in standouts)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'You tend to feel {mood} on {day}.'.tr
                      .replaceAll(
                        '{mood}',
                        '${w.mood.emoji} ${w.mood.label.tr}',
                      )
                      .replaceAll('{day}', _weekdayName(w.weekday)),
                  style: context.text.body,
                ),
              ),
        ],
      ),
    );
  }
}

class _DayPartCard extends StatelessWidget {
  const _DayPartCard({required this.patterns});

  final Patterns patterns;

  static String _label(DayPart part) => switch (part) {
    DayPart.morning => 'Morning',
    DayPart.afternoon => 'Afternoon',
    DayPart.evening => 'Evening',
    DayPart.night => 'Night',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final max = patterns.dayParts.values.fold(1, (a, b) => a > b ? a : b);
    final best = patterns.busiestPart;
    return _Card(
      title: 'When you write'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final part in DayPart.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(_label(part).tr, style: context.text.label),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) => Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0,
                            end: (patterns.dayParts[part] ?? 0) / max,
                          ),
                          duration: Motion.slow,
                          curve: Motion.ease,
                          builder: (context, f, _) => Container(
                            height: 12,
                            width: (box.maxWidth * f).clamp(6, box.maxWidth),
                            decoration: BoxDecoration(
                              color: part == best ? c.accent : c.line,
                              borderRadius: BorderRadius.circular(Radii.pill),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${patterns.dayParts[part] ?? 0}',
                      textAlign: TextAlign.end,
                      style: context.text.caption.copyWith(color: c.ink),
                    ),
                  ),
                ],
              ),
            ),
          if (best != null) ...[
            const SizedBox(height: Space.xs),
            Text(
              'You write most in the {part}.'.tr.replaceAll(
                '{part}',
                _label(best).tr.toLowerCase(),
              ),
              style: context.text.body,
            ),
          ],
        ],
      ),
    );
  }
}

class _WordsCard extends StatelessWidget {
  const _WordsCard({required this.words});

  final List<MapEntry<String, int>> words;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = words.first.value;
    return _Card(
      title: 'Words you reach for'.tr,
      child: Wrap(
        spacing: Space.xs,
        runSpacing: Space.xs,
        children: [
          for (final MapEntry(key: word, value: count) in words)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: c.accentSoft.withValues(alpha: 0.5 + 0.5 * count / top),
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              child: Text(
                '$word · $count',
                style: context.text.label.copyWith(
                  fontSize: 13 + 4 * count / top,
                  color: c.ink,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LatelyCard extends StatelessWidget {
  const _LatelyCard({required this.patterns});

  final Patterns patterns;

  @override
  Widget build(BuildContext context) {
    final lately = patterns.lately!;
    final before = patterns.before!;
    final text = lately == before
        ? 'Lately you have felt {mood} again, as in the month before.'
        : 'Lately you have felt more {mood}. Before that it was {before}.';
    return _Card(
      title: 'Lately'.tr,
      child: Text(
        text.tr
            .replaceAll('{mood}', '${lately.emoji} ${lately.label.tr}')
            .replaceAll('{before}', '${before.emoji} ${before.label.tr}'),
        style: context.text.body,
      ),
    );
  }
}
