import '../data/models.dart';
import '../design/tokens.dart';

/// One calendar day in the weekly view.
class DayEntry {
  const DayEntry(this.date, this.moods);

  final DateTime date;

  /// Moods of the notes written that day, oldest first.
  final List<Mood> moods;

  bool get wrote => moods.isNotEmpty;
}

/// A gentle summary of someone's own writing: no scores, no losses.
class WeekInsights {
  const WeekInsights({
    required this.days,
    required this.notesThisWeek,
    required this.moodsThisWeek,
    required this.moodsThisMonth,
    required this.streak,
    required this.totalNotes,
  });

  /// The last 7 days, oldest first, ending today.
  final List<DayEntry> days;
  final int notesThisWeek;

  /// Mood counts for the last 7 and 30 days (plain notes left out).
  final Map<Mood, int> moodsThisWeek;
  final Map<Mood, int> moodsThisMonth;

  /// Days in a row with writing, ending today or yesterday (so an
  /// unwritten today never resets it).
  final int streak;
  final int totalNotes;

  int get daysWritten => days.where((d) => d.wrote).length;

  /// The most common mood this week, if any mood was chosen.
  Mood? get favoriteMood {
    if (moodsThisWeek.isEmpty) return null;
    return (moodsThisWeek.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .first
        .key;
  }

  /// Computes insights from [notes] the user wrote, relative to [now].
  factory WeekInsights.from(Iterable<Note> notes, DateTime now) {
    final today = _day(now);
    final byDay = <DateTime, List<Mood>>{};
    for (final note in notes) {
      byDay.putIfAbsent(_day(note.time), () => []).add(note.mood);
    }
    for (final moods in byDay.values) {
      moods.sort((a, b) => a.index.compareTo(b.index));
    }

    final days = [
      for (var i = 6; i >= 0; i--)
        DayEntry(
          today.subtract(Duration(days: i)),
          byDay[today.subtract(Duration(days: i))] ?? const [],
        ),
    ];

    Map<Mood, int> countSince(DateTime start) {
      final counts = <Mood, int>{};
      for (final MapEntry(key: day, value: moods) in byDay.entries) {
        if (day.isBefore(start) || day.isAfter(today)) continue;
        for (final mood in moods.where((m) => m != Mood.plain)) {
          counts[mood] = (counts[mood] ?? 0) + 1;
        }
      }
      return counts;
    }

    var streak = 0;
    var cursor = byDay.containsKey(today)
        ? today
        : today.subtract(const Duration(days: 1));
    while (byDay.containsKey(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return WeekInsights(
      days: days,
      notesThisWeek: days.fold(0, (sum, d) => sum + d.moods.length),
      moodsThisWeek: countSince(today.subtract(const Duration(days: 6))),
      moodsThisMonth: countSince(today.subtract(const Duration(days: 29))),
      streak: streak,
      totalNotes: notes.length,
    );
  }

  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);
}

/// A past journal note to resurface today, the same one all day.
Note? noteOfTheDay(Iterable<Note> journal, DateTime now) {
  final cutoff = now.subtract(const Duration(days: 7));
  final candidates =
      journal
          .where(
            (n) => !n.archived && n.text.isNotEmpty && n.time.isBefore(cutoff),
          )
          .toList()
        ..sort((a, b) => a.time.compareTo(b.time));
  if (candidates.isEmpty) return null;
  final seed = now.year * 1000 + now.difference(DateTime(now.year)).inDays;
  return candidates[seed % candidates.length];
}
