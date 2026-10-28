import '../data/models.dart';
import '../design/tokens.dart';
import 'format.dart';

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

  /// Whether anything was written today.
  bool get wroteToday => days.last.wrote;

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

    return WeekInsights(
      days: days,
      notesThisWeek: days.fold(0, (sum, d) => sum + d.moods.length),
      moodsThisWeek: countSince(today.subtract(const Duration(days: 6))),
      moodsThisMonth: countSince(today.subtract(const Duration(days: 29))),
      streak: streakFromDays(byDay.keys.toSet(), today),
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

/// A past note that resurfaces today because it was written on this day
/// of the month, [months] months ago.
class Memory {
  const Memory(this.note, this.months);

  final Note note;
  final int months;
}

/// Journal notes written on today's date 1, 3 or 6 months ago, or a
/// whole number of years ago. Nearest first.
List<Memory> memoriesFor(Iterable<Note> journal, DateTime now) {
  final memories = <Memory>[];
  for (final note in journal) {
    if (note.archived || note.text.isEmpty || note.time.day != now.day) {
      continue;
    }
    final months =
        (now.year - note.time.year) * 12 + now.month - note.time.month;
    if (months <= 0) continue;
    if (months == 1 || months == 3 || months == 6 || months % 12 == 0) {
      memories.add(Memory(note, months));
    }
  }
  return memories..sort((a, b) => a.months.compareTo(b.months));
}

DateTime _dayBefore(DateTime d) => DateTime(d.year, d.month, d.day - 1);

/// Days in a row with writing, counted back from [today] (an unwritten
/// today never ends it). One missed day is forgiven as a rest day, as
/// long as it is the only one missed in the past week; two missed days
/// in a row end the streak. [days] holds midnight dates.
int streakFromDays(Set<DateTime> days, DateTime today) {
  if (days.isEmpty) return 0;
  final earliest = days.reduce((a, b) => a.isBefore(b) ? a : b);
  var count = 0;
  DateTime? lastRest;
  for (
    var cursor = today;
    !cursor.isBefore(earliest);
    cursor = _dayBefore(cursor)
  ) {
    if (days.contains(cursor)) {
      count++;
    } else if (cursor != today) {
      final restAllowed =
          days.contains(_dayBefore(cursor)) &&
          (lastRest == null || lastRest.difference(cursor).inDays >= 7);
      if (!restAllowed) break;
      lastRest = cursor;
    }
  }
  return count;
}

/// The longest streak among [days] (time of day ignored), with the same
/// rest-day rule as [streakFromDays].
int longestStreak(Iterable<DateTime> days) {
  final unique = {for (final d in days) DateTime(d.year, d.month, d.day)};
  var best = 0;
  for (final end in unique) {
    final run = streakFromDays(unique, end);
    if (run > best) best = run;
  }
  return best;
}

/// One calendar month of someone's own writing.
class MonthInsights {
  const MonthInsights({
    required this.month,
    required this.byDay,
    required this.notes,
    required this.moods,
  });

  /// The first day of the month.
  final DateTime month;

  /// Notes written each day of the month, oldest first.
  final Map<DateTime, List<Note>> byDay;
  final int notes;

  /// Mood counts for the month (plain notes left out).
  final Map<Mood, int> moods;

  int get daysWritten => byDay.length;

  /// The most common mood this month, if any mood was chosen.
  Mood? get topMood {
    if (moods.isEmpty) return null;
    return (moods.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .first
        .key;
  }

  /// The mood that colours [day] on the calendar: the first real mood,
  /// else plain. Null when nothing was written.
  Mood? moodOf(DateTime day) {
    final written = byDay[DateTime(day.year, day.month, day.day)];
    if (written == null || written.isEmpty) return null;
    return written
        .map((n) => n.mood)
        .firstWhere((m) => m != Mood.plain, orElse: () => Mood.plain);
  }

  factory MonthInsights.from(Iterable<Note> all, DateTime month) {
    final first = DateTime(month.year, month.month);
    final byDay = <DateTime, List<Note>>{};
    final moods = <Mood, int>{};
    var count = 0;
    for (final note in all) {
      final t = note.time;
      if (t.year != first.year || t.month != first.month) continue;
      byDay.putIfAbsent(DateTime(t.year, t.month, t.day), () => []).add(note);
      count++;
      if (note.mood != Mood.plain) {
        moods[note.mood] = (moods[note.mood] ?? 0) + 1;
      }
    }
    for (final list in byDay.values) {
      list.sort((a, b) => a.time.compareTo(b.time));
    }
    return MonthInsights(
      month: first,
      byDay: byDay,
      notes: count,
      moods: moods,
    );
  }
}

/// A small, quiet achievement: reached or still ahead.
class Milestone {
  const Milestone({
    required this.emoji,
    required this.target,
    required this.isStreak,
    required this.reached,
  });

  final String emoji;

  /// Days in a row ([isStreak]) or total notes.
  final int target;
  final bool isStreak;
  final bool reached;
}

/// Streak and note-count milestones for [notes], in the order shown.
List<Milestone> milestonesFor(Iterable<Note> notes) {
  final longest = longestStreak(notes.map((n) => n.time));
  final total = notes.length;
  return [
    for (final days in const [3, 7, 14, 30, 100])
      Milestone(
        emoji: '🌱',
        target: days,
        isStreak: true,
        reached: longest >= days,
      ),
    for (final count in const [1, 10, 50, 100])
      Milestone(
        emoji: '✍️',
        target: count,
        isStreak: false,
        reached: total >= count,
      ),
  ];
}

/// Today's answers to the daily question from the people in a circle.
class CircleQuestion {
  const CircleQuestion({required this.answered, required this.others});

  /// Whether the signed-in user has answered it to their circle.
  final bool answered;

  /// Other people's answers, newest first.
  final List<Note> others;
}

/// Picks out today's circle answers from [circleNotes]. Answers from
/// others stay hidden until the user has answered themselves.
CircleQuestion circleQuestionFor(
  Iterable<Note> circleNotes,
  String uid,
  DateTime now,
) {
  final today = dayKey(now);
  final todays = circleNotes.where((n) => n.promptDay == today).toList()
    ..sort((a, b) => b.time.compareTo(a.time));
  return CircleQuestion(
    answered: todays.any((n) => n.ownerId == uid),
    others: todays.where((n) => n.ownerId != uid).toList(),
  );
}

/// Which 3-day stretch [now] falls in; a new past-self note is offered
/// once per stretch.
int pastSelfWindow(DateTime now) =>
    DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime.utc(2020)).inDays ~/
    3;

/// An older journal note to look back on with "do you still feel this
/// way?": at least 30 days old and more than a passing line. The same
/// note is offered all through a [pastSelfWindow].
Note? pastSelfNote(Iterable<Note> journal, DateTime now) {
  final cutoff = now.subtract(const Duration(days: 30));
  final candidates =
      journal
          .where(
            (n) =>
                !n.archived &&
                n.text.trim().length >= 20 &&
                n.time.isBefore(cutoff),
          )
          .toList()
        ..sort((a, b) => a.time.compareTo(b.time));
  if (candidates.isEmpty) return null;
  return candidates[pastSelfWindow(now) % candidates.length];
}

/// How grown a note's plant is, from a small sprout to full size over
/// its first three days.
double plantGrowth(DateTime written, DateTime now) {
  final days = now.difference(written).inHours / 24;
  if (days < 1) return 0.45;
  if (days < 3) return 0.75;
  return 1;
}

/// Notes of the last [days] days (plus today), oldest first: what the
/// garden grows.
List<Note> gardenNotes(Iterable<Note> notes, DateTime now, {int days = 30}) {
  final start = DateTime(now.year, now.month, now.day - (days - 1));
  return notes.where((n) => !n.archived && !n.time.isBefore(start)).toList()
    ..sort((a, b) => a.time.compareTo(b.time));
}
