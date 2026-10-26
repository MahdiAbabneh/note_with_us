import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/insights.dart';
import '../../core/l10n.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import '../compose/compose_screen.dart';

/// A calm look back at the last week: which days you wrote, how you felt,
/// and your moods over the month. Computed on the phone from your notes.
class YourWeekScreen extends StatefulWidget {
  const YourWeekScreen({super.key});

  @override
  State<YourWeekScreen> createState() => _YourWeekScreenState();
}

class _YourWeekScreenState extends State<YourWeekScreen> {
  final _session = Session.instance;
  late Stream<List<Note>> _notes = _session.notes.mine(_session.uid);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(title: 'Your week'.tr),
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
          final insights = WeekInsights.from(snap.data!, DateTime.now());
          if (insights.totalNotes == 0) {
            return EmptyState(
              emoji: '🌱',
              title: 'Your week starts here'.tr,
              message: 'Write a note and your week will take shape.'.tr,
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
                      _Headline(insights: insights),
                      const SizedBox(height: Space.xl),
                      WeekStrip(days: insights.days, large: true),
                      const SizedBox(height: Space.xl),
                      _Stats(insights: insights),
                      const SizedBox(height: Space.xl),
                      _MoodMix(counts: insights.moodsThisMonth),
                    ]
                    .animate(interval: 60.ms)
                    .fadeIn(duration: Motion.slow)
                    .slideY(begin: 0.04),
          );
        },
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.insights});

  final WeekInsights insights;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final days = insights.daysWritten;
    final title = switch (days) {
      0 => 'A fresh week'.tr,
      1 => 'You wrote on 1 day this week'.tr,
      7 => 'You wrote every day this week'.tr,
      _ => 'You wrote on {n} of the last 7 days'.tr.replaceAll('{n}', '$days'),
    };
    // Gentle by design: celebrate a rhythm, never mention a broken one.
    final subtitle = insights.streak >= 2
        ? '🌱 ${'{n} days in a row. Nice rhythm.'.tr.replaceAll('{n}', '${insights.streak}')}'
        : days == 0
        ? 'Write whenever it feels right.'.tr
        : 'Every note counts, big or small.'.tr;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.text.display),
        const SizedBox(height: Space.xs),
        Text(subtitle, style: context.text.body.copyWith(color: c.inkSoft)),
      ],
    );
  }
}

/// Seven day columns; a filled circle in the day's mood colour when you
/// wrote, an empty ring when you didn't.
class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, required this.days, this.large = false});

  final List<DayEntry> days;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final locale = L10n.arabic ? 'ar' : 'en';
    final size = large ? 40.0 : 14.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final (i, day) in days.indexed)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: day.wrote ? _dayColor(c, day) : null,
                  border: day.wrote
                      ? null
                      : Border.all(color: c.line, width: large ? 2 : 1.5),
                ),
                child: large && day.wrote
                    ? Text(
                        _dayEmoji(day),
                        style: const TextStyle(fontSize: 18, height: 1),
                      )
                    : null,
              ),
              if (large) ...[
                const SizedBox(height: Space.xs),
                Text(
                  DateFormat.E(locale).format(day.date),
                  style: context.text.caption.copyWith(
                    color: i == days.length - 1 ? c.ink : c.muted,
                    fontWeight: i == days.length - 1
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  static Mood _main(DayEntry day) =>
      day.moods.firstWhere((m) => m != Mood.plain, orElse: () => Mood.plain);

  static Color _dayColor(NwuColors c, DayEntry day) {
    final mood = _main(day);
    return mood == Mood.plain ? c.accentSoft : c.moodTint(mood);
  }

  static String _dayEmoji(DayEntry day) {
    final mood = _main(day);
    return mood == Mood.plain ? '✍️' : mood.emoji;
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.insights});

  final WeekInsights insights;

  @override
  Widget build(BuildContext context) {
    final favorite = insights.favoriteMood;
    // Equal-height tiles even when one label wraps to two lines.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatTile(
              value: '${insights.notesThisWeek}',
              label: 'Notes this week'.tr,
            ),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: _StatTile(
              value: favorite?.emoji ?? '—',
              label: favorite == null
                  ? 'No mood yet'.tr
                  : '${'Top mood'.tr} · ${favorite.label.tr}',
            ),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: _StatTile(
              value: '${insights.totalNotes}',
              label: 'Notes in total'.tr,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.line.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: context.text.title),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.caption,
          ),
        ],
      ),
    );
  }
}

/// Moods over the last 30 days as soft horizontal bars.
class _MoodMix extends StatelessWidget {
  const _MoodMix({required this.counts});

  final Map<Mood, int> counts;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = entries.isEmpty ? 1 : entries.first.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MOODS THIS MONTH'.tr, style: context.text.overline),
        const SizedBox(height: Space.sm),
        if (entries.isEmpty)
          Text(
            'Pick a mood when you write to see your month here.'.tr,
            style: context.text.small,
          )
        else
          for (final MapEntry(key: mood, value: count) in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      '${mood.emoji}  ${mood.label.tr}',
                      style: context.text.label,
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, box) => Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: count / max),
                          duration: Motion.slow,
                          curve: Motion.ease,
                          builder: (context, f, _) => Container(
                            height: 12,
                            width: (box.maxWidth * f).clamp(12, box.maxWidth),
                            decoration: BoxDecoration(
                              color: c.moodInk(mood),
                              borderRadius: BorderRadius.circular(Radii.pill),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '$count',
                      textAlign: TextAlign.end,
                      style: context.text.caption.copyWith(color: c.ink),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
