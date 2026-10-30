import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:printing/printing.dart';

import '../../core/format.dart';
import '../../core/hijri.dart';
import '../../core/insights.dart';
import '../../core/journal_pdf.dart';
import '../../core/l10n.dart';
import '../../core/settings.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import '../compose/compose_screen.dart';
import '../notes/note_card.dart';

/// A month at a glance: the days you wrote glow in that day's mood. Tap a
/// day to read what you wrote. Computed on the phone from your own notes.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _session = Session.instance;
  late Stream<List<Note>> _notes = _session.notes.mine(_session.uid);

  late DateTime _month = _firstOfMonth(DateTime.now());
  late DateTime _selected = _dayOf(DateTime.now());

  static DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month);
  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  /// The newest notes seen, so the report button can use them.
  List<Note> _latest = const [];
  bool _exporting = false;

  Future<void> _exportReport(BuildContext buttonContext) async {
    if (_exporting) return;
    final month = MonthInsights.from(_latest.where((n) => !n.archived), _month);
    if (month.notes == 0) {
      showToast(context, 'Nothing written this month yet.'.tr);
      return;
    }
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    setState(() => _exporting = true);
    try {
      final font = await rootBundle.load('assets/fonts/NotoNaskhArabic.ttf');
      final bytes = await buildMoodReportPdf(
        month: month,
        authorName: _session.me.username,
        fontData: font.buffer.asUint8List(),
        now: DateTime.now(),
        hijri: AppSettings.instance.hijri,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'mood-report-${_month.year}-${_month.month}.pdf',
        bounds: origin,
      );
    } catch (_) {
      if (mounted) {
        showToast(context, 'Couldn’t create the PDF'.tr, error: true);
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  bool get _isCurrentMonth => _month == _firstOfMonth(DateTime.now());

  void _shift(int months) {
    final next = DateTime(_month.year, _month.month + months);
    if (next.isAfter(_firstOfMonth(DateTime.now()))) return;
    setState(() {
      _month = next;
      // Land on today in the current month, else the 1st.
      _selected = next == _firstOfMonth(DateTime.now())
          ? _dayOf(DateTime.now())
          : next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(
        title: 'Calendar'.tr,
        actions: [
          Builder(
            builder: (buttonContext) => CircleIconButton(
              icon: CupertinoIcons.doc_text,
              size: 40,
              semanticLabel: 'Export mood report'.tr,
              onPressed: _exporting ? null : () => _exportReport(buttonContext),
            ),
          ),
        ],
      ),
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
          _latest = snap.data!;
          final month = MonthInsights.from(
            snap.data!.where((n) => !n.archived),
            _month,
          );
          final dayNotes = month.byDay[_selected] ?? const <Note>[];
          return ListView(
            padding: EdgeInsets.fromLTRB(
              Space.gutter,
              Space.sm,
              Space.gutter,
              MediaQuery.of(context).padding.bottom + Space.xxl,
            ),
            children: [
              _MonthHeader(
                month: _month,
                canGoForward: !_isCurrentMonth,
                onPrevious: () => _shift(-1),
                onNext: () => _shift(1),
              ),
              const SizedBox(height: Space.md),
              _MonthSummary(insights: month),
              const SizedBox(height: Space.lg),
              _MonthGrid(
                insights: month,
                selected: _selected,
                onSelect: (day) => setState(() => _selected = day),
              ),
              const SizedBox(height: Space.xl),
              Text(
                fullDateWithHijri(_selected).toUpperCase(),
                style: context.text.overline,
              ),
              const SizedBox(height: Space.sm),
              if (dayNotes.isEmpty)
                _EmptyDay(
                  day: _selected,
                  onWrite: () =>
                      openComposer(context, target: ComposeTarget.private),
                )
              else
                for (final note in dayNotes.reversed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.sm),
                    child: NoteCard(note: note),
                  ),
            ].animate(interval: 40.ms).fadeIn(duration: Motion.base),
          );
        },
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(monthYear(month), style: context.text.display),
              if (AppSettings.instance.hijri)
                Text(
                  hijriRangeOf(month, DateTime(month.year, month.month + 1, 0)),
                  style: context.text.caption,
                ),
            ],
          ),
        ),
        CircleIconButton(
          icon: rtl
              ? CupertinoIcons.chevron_right
              : CupertinoIcons.chevron_left,
          size: 40,
          semanticLabel: 'Previous month'.tr,
          onPressed: onPrevious,
        ),
        const SizedBox(width: Space.xs),
        CircleIconButton(
          icon: rtl
              ? CupertinoIcons.chevron_left
              : CupertinoIcons.chevron_right,
          size: 40,
          iconColor: canGoForward ? null : c.muted,
          semanticLabel: 'Next month'.tr,
          onPressed: canGoForward ? onNext : null,
        ),
      ],
    );
  }
}

/// "5 days · 8 notes · Top mood 😌": a quiet monthly recap.
class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.insights});

  final MonthInsights insights;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (insights.notes == 0) {
      return Text(
        'Nothing written this month yet.'.tr,
        style: context.text.body.copyWith(color: c.inkSoft),
      );
    }
    final top = insights.topMood;
    final parts = [
      (insights.daysWritten == 1 ? '1 day' : '{n} days').tr.replaceAll(
        '{n}',
        '${insights.daysWritten}',
      ),
      (insights.notes == 1 ? '1 note' : '{n} notes').tr.replaceAll(
        '{n}',
        '${insights.notes}',
      ),
      if (top != null) '${top.emoji} ${top.label.tr}',
    ];
    return Text(
      parts.join('  ·  '),
      style: context.text.body.copyWith(color: c.inkSoft),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.insights,
    required this.selected,
    required this.onSelect,
  });

  final MonthInsights insights;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final locale = L10n.arabic ? 'ar' : 'en';
    final month = insights.month;
    final today = DateTime.now();
    // 0 = Sunday … 6 = Saturday, from the active locale.
    final firstDay = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // DateTime.weekday: Monday = 1 … Sunday = 7; map Sunday to 0.
    final leading = (month.weekday % 7 - firstDay + 7) % 7;
    final cells = leading + daysInMonth;
    final rows = (cells / 7).ceil();

    // 2 Jan 2000 was a Sunday.
    final weekdayNames = [
      for (var i = 0; i < 7; i++)
        DateFormat.E(locale).format(DateTime(2000, 1, 2 + (firstDay + i) % 7)),
    ];

    return Column(
      children: [
        Row(
          children: [
            for (final name in weekdayNames)
              Expanded(
                child: Center(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.caption.copyWith(color: c.muted),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: Space.xs),
        for (var row = 0; row < rows; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: _dayCell(
                      context,
                      row * 7 + col - leading + 1,
                      daysInMonth,
                      today,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _dayCell(
    BuildContext context,
    int dayNumber,
    int daysInMonth,
    DateTime today,
  ) {
    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return const SizedBox(height: 44);
    }
    final c = context.colors;
    final month = insights.month;
    final day = DateTime(month.year, month.month, dayNumber);
    final mood = insights.moodOf(day);
    final isToday = day == DateTime(today.year, today.month, today.day);
    final isFuture = day.isAfter(today);
    final isSelected = day == selected;
    final fill = mood == null
        ? null
        : mood == Mood.plain
        ? c.accentSoft
        : c.moodTint(mood);
    return Pressable(
      scale: 0.9,
      semanticLabel: fullDate(day),
      onTap: isFuture ? null : () => onSelect(day),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: isSelected
              ? Border.all(color: c.accent, width: 2)
              : isToday
              ? Border.all(color: c.line, width: 1.5)
              : null,
        ),
        child: mood != null && mood != Mood.plain
            ? Text(mood.emoji, style: const TextStyle(fontSize: 18, height: 1))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$dayNumber',
                    style: context.text.label.copyWith(
                      color: isFuture
                          ? c.muted.withValues(alpha: 0.5)
                          : mood == null
                          ? c.inkSoft
                          : c.ink,
                    ),
                  ),
                  if (AppSettings.instance.hijri)
                    Text(
                      formatHijri(day, withYear: false).split(' ').first,
                      style: TextStyle(
                        fontSize: 9,
                        height: 1,
                        color: c.muted.withValues(alpha: isFuture ? 0.4 : 0.9),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.day, required this.onWrite});

  final DateTime day;
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final now = DateTime.now();
    final isToday = day == DateTime(now.year, now.month, now.day);
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
          Text(
            isToday ? 'Nothing yet today.'.tr : 'No notes on this day.'.tr,
            style: context.text.body.copyWith(color: c.inkSoft),
          ),
          if (isToday) ...[
            const SizedBox(height: Space.sm),
            NwuButton(
              label: 'Write a note'.tr,
              tone: ButtonTone.accent,
              compact: true,
              expand: false,
              onPressed: onWrite,
            ),
          ],
        ],
      ),
    );
  }
}
