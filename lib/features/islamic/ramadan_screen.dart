import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/format.dart';
import '../../core/hijri.dart';
import '../../core/islamic.dart';
import '../../core/l10n.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import '../compose/compose_screen.dart';

/// "Your Ramadan": how this month went, from your own notes. Built on the
/// phone; nothing is shared.
class RamadanScreen extends StatefulWidget {
  const RamadanScreen({super.key});

  @override
  State<RamadanScreen> createState() => _RamadanScreenState();
}

class _RamadanScreenState extends State<RamadanScreen> {
  final _session = Session.instance;
  late Stream<List<Note>> _notes = _session.notes.mine(_session.uid);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final year = ramadanYearFor(now);
    final (start, end) = ramadanRange(year);
    return Scaffold(
      appBar: TopBar(title: 'Your Ramadan'.tr),
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
          final stats = RamadanStats.from(snap.data!, start, end, now);
          final byDay = {
            for (final n in snap.data!.where((n) => !n.archived))
              DateTime(n.time.year, n.time.month, n.time.day),
          };
          final c = context.colors;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              Space.gutter,
              Space.sm,
              Space.gutter,
              MediaQuery.of(context).padding.bottom + Space.xxl,
            ),
            children: [
              Text(
                'Ramadan {year}'.tr.replaceAll('{year}', '$year'),
                style: context.text.display,
              ),
              const SizedBox(height: Space.xs),
              Text(
                '${fullDate(start)} — ${fullDate(end)}',
                style: context.text.body.copyWith(color: c.inkSoft),
              ),
              const SizedBox(height: Space.lg),
              if (stats.notes == 0)
                _Empty(
                  started: stats.elapsedDays > 0,
                  onWrite: () =>
                      openComposer(context, target: ComposeTarget.private),
                )
              else ...[
                _Tiles(stats: stats),
                const SizedBox(height: Space.xl),
                Text('DAY BY DAY'.tr, style: context.text.overline),
                const SizedBox(height: Space.sm),
                _DayGrid(
                  start: start,
                  total: stats.totalDays,
                  elapsed: stats.elapsedDays,
                  written: byDay,
                ),
                if (stats.topMood != null) ...[
                  const SizedBox(height: Space.xl),
                  Text(
                    '${'Most felt'.tr}: ${stats.topMood!.emoji} ${stats.topMood!.label.tr}',
                    style: context.text.label,
                  ),
                ],
                if (stats.topTags.isNotEmpty) ...[
                  const SizedBox(height: Space.lg),
                  Wrap(
                    spacing: Space.xs,
                    runSpacing: Space.xs,
                    children: [
                      for (final tag in stats.topTags)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: c.accentSoft,
                            borderRadius: BorderRadius.circular(Radii.pill),
                          ),
                          child: Text(
                            '#$tag',
                            style: context.text.caption.copyWith(
                              color: c.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: Space.xl),
                Text(
                  (stats.elapsedDays < stats.totalDays
                          ? 'Keep writing. Every day counts.'
                          : 'Ramadan Mubarak. Taqabbal Allahu minna wa minkum.')
                      .tr,
                  style: context.text.body.copyWith(color: c.inkSoft),
                ),
              ],
            ].animate(interval: 60.ms).fadeIn(duration: Motion.slow).slideY(begin: 0.04),
          );
        },
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.started, required this.onWrite});

  final bool started;
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        (started
                ? 'You have not written this Ramadan yet.'
                : 'Ramadan has not started yet.')
            .tr,
        style: context.text.body,
      ),
      const SizedBox(height: Space.md),
      if (started)
        NwuButton(
          label: 'Write a note'.tr,
          tone: ButtonTone.accent,
          expand: false,
          onPressed: onWrite,
        ),
    ],
  );
}

class _Tiles extends StatelessWidget {
  const _Tiles({required this.stats});

  final RamadanStats stats;

  @override
  Widget build(BuildContext context) {
    Widget tile(String value, String label) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: context.colors.raised,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: context.colors.line.withValues(alpha: 0.7)),
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
      ),
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tile('${stats.notes}', 'Notes'.tr),
          const SizedBox(width: Space.sm),
          tile('${stats.daysWritten}/${stats.elapsedDays}', 'Days written'.tr),
          const SizedBox(width: Space.sm),
          tile('${stats.longestStreak}', 'Longest streak'.tr),
        ],
      ),
    );
  }
}

/// One circle per day of Ramadan: filled if you wrote, an outline if not,
/// and faint for days still to come.
class _DayGrid extends StatelessWidget {
  const _DayGrid({
    required this.start,
    required this.total,
    required this.elapsed,
    required this.written,
  });

  final DateTime start;
  final int total;
  final int elapsed;
  final Set<DateTime> written;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < total; i++)
          Builder(
            builder: (context) {
              final day = DateTime(start.year, start.month, start.day + i);
              final wrote = written.contains(day);
              final future = i >= elapsed;
              return Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: wrote ? c.accent : null,
                  border: wrote
                      ? null
                      : Border.all(
                          color: future
                              ? c.line.withValues(alpha: 0.5)
                              : c.line,
                          width: 1.5,
                        ),
                ),
                child: Text(
                  L10n.arabic ? hijriOf(day).day.toString() : '${i + 1}',
                  style: context.text.caption.copyWith(
                    color: wrote
                        ? c.onAccent
                        : (future ? c.muted.withValues(alpha: 0.6) : c.inkSoft),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
