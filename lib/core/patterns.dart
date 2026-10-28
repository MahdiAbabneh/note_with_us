import '../data/models.dart';
import '../design/tokens.dart';
import 'tags.dart';

/// When in the day a note was written.
enum DayPart { morning, afternoon, evening, night }

DayPart dayPartOf(DateTime time) {
  final h = time.hour;
  if (h >= 5 && h < 12) return DayPart.morning;
  if (h >= 12 && h < 17) return DayPart.afternoon;
  if (h >= 17 && h < 21) return DayPart.evening;
  return DayPart.night;
}

/// How someone tends to feel on one weekday.
class WeekdayMood {
  const WeekdayMood(this.weekday, this.mood, this.count, this.total);

  /// `DateTime.weekday`: Monday = 1 … Sunday = 7.
  final int weekday;
  final Mood mood;

  /// Notes with that mood on this weekday, out of [total] with a mood.
  final int count;
  final int total;

  double get share => count / total;
}

/// Words that say little on their own, in English and Arabic.
const _stopWords = {
  'the',
  'and',
  'was',
  'for',
  'with',
  'that',
  'this',
  'have',
  'but',
  'not',
  'you',
  'are',
  'from',
  'had',
  'they',
  'his',
  'her',
  'our',
  'out',
  'all',
  'can',
  'just',
  'got',
  'get',
  'its',
  'been',
  'were',
  'what',
  'when',
  'will',
  'would',
  'there',
  'their',
  'than',
  'then',
  'them',
  'into',
  'about',
  'very',
  'really',
  'today',
  'also',
  'some',
  'too',
  'she',
  'him',
  'who',
  'how',
  'why',
  'did',
  'does',
  'don',
  'didn',
  'isn',
  'wasn',
  'because',
  'much',
  'more',
  'في',
  'من',
  'على',
  'إلى',
  'عن',
  'مع',
  'هذا',
  'هذه',
  'ذلك',
  'التي',
  'الذي',
  'كان',
  'كانت',
  'لكن',
  'ثم',
  'أن',
  'إن',
  'لا',
  'ما',
  'هو',
  'هي',
  'أنا',
  'نحن',
  'كل',
  'قد',
  'لم',
  'لن',
  'به',
  'بها',
  'له',
  'لها',
  'أو',
  'أي',
  'هل',
  'بعد',
  'قبل',
  'حتى',
  'عند',
  'كنت',
  'يكون',
  'اليوم',
  'جدا',
  'جدًا',
  'أيضا',
  'أيضًا',
  'مثل',
  'التى',
  'تلك',
  'هناك',
  'هنا',
  'لقد',
  'أني',
  'إني',
};

final _wordPattern = RegExp(r'[\p{L}\p{M}]+', unicode: true);
final _diacritics = RegExp('[ً-ٰٟ]');

/// What your own notes say about you: when you write, how you feel on
/// which days, and the words you reach for. Worked out on the phone.
class Patterns {
  const Patterns({
    required this.notes,
    required this.weekdays,
    required this.dayParts,
    required this.topWords,
    this.lately,
    this.before,
  });

  /// Notes looked at (archived and empty ones are left out).
  final int notes;

  /// The usual mood of each weekday that has enough notes with a mood.
  final List<WeekdayMood> weekdays;
  final Map<DayPart, int> dayParts;

  /// Most used words, with counts.
  final List<MapEntry<String, int>> topWords;

  /// Main mood of the last 30 days and of the 30 before, when each has
  /// enough notes with a mood.
  final Mood? lately;
  final Mood? before;

  /// Enough notes for patterns to mean something.
  static const minNotes = 10;
  bool get enough => notes >= minNotes;

  /// The part of the day with the most notes.
  DayPart? get busiestPart {
    final best = dayParts.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return best.isEmpty ? null : best.first.key;
  }

  /// The weekdays that stand out most, strongest first (at most two).
  List<WeekdayMood> get standouts {
    final sorted = [...weekdays]
      ..sort((a, b) {
        final byShare = b.share.compareTo(a.share);
        return byShare != 0 ? byShare : b.total.compareTo(a.total);
      });
    return sorted.where((w) => w.share >= 0.4).take(2).toList();
  }

  factory Patterns.from(Iterable<Note> all, DateTime now) {
    final notes = [
      for (final n in all)
        if (!n.archived && n.text.trim().isNotEmpty) n,
    ];

    // Mood by weekday.
    final byWeekday = <int, Map<Mood, int>>{};
    for (final n in notes.where((n) => n.mood != Mood.plain)) {
      final moods = byWeekday.putIfAbsent(n.time.weekday, () => {});
      moods[n.mood] = (moods[n.mood] ?? 0) + 1;
    }
    final weekdays = <WeekdayMood>[];
    for (final MapEntry(key: day, value: moods) in byWeekday.entries) {
      final total = moods.values.fold(0, (a, b) => a + b);
      if (total < 3) continue;
      final top = moods.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      weekdays.add(WeekdayMood(day, top.first.key, top.first.value, total));
    }
    weekdays.sort((a, b) => a.weekday.compareTo(b.weekday));

    // When in the day.
    final parts = {for (final p in DayPart.values) p: 0};
    for (final n in notes) {
      final part = dayPartOf(n.time);
      parts[part] = parts[part]! + 1;
    }

    // Words, leaving out tags, short and common words.
    final counts = <String, int>{};
    for (final n in notes) {
      for (final part in splitTags(n.text).where((p) => !p.isTag)) {
        for (final m in _wordPattern.allMatches(part.text)) {
          final word = m.group(0)!.toLowerCase().replaceAll(_diacritics, '');
          if (word.length < 3 || _stopWords.contains(word)) continue;
          counts[word] = (counts[word] ?? 0) + 1;
        }
      }
    }
    final words = counts.entries.where((e) => e.value >= 2).toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });

    // Lately versus before.
    Mood? mainMood(DateTime from, DateTime to) {
      final moods = <Mood, int>{};
      for (final n in notes) {
        if (n.mood == Mood.plain ||
            n.time.isBefore(from) ||
            !n.time.isBefore(to)) {
          continue;
        }
        moods[n.mood] = (moods[n.mood] ?? 0) + 1;
      }
      if (moods.values.fold(0, (a, b) => a + b) < 3) return null;
      return (moods.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .first
          .key;
    }

    final today = DateTime(now.year, now.month, now.day + 1);
    final lately = mainMood(
      DateTime(today.year, today.month, today.day - 30),
      today,
    );
    final before = mainMood(
      DateTime(today.year, today.month, today.day - 60),
      DateTime(today.year, today.month, today.day - 30),
    );

    return Patterns(
      notes: notes.length,
      weekdays: weekdays,
      dayParts: parts,
      topWords: words.take(8).toList(),
      lately: lately,
      before: before,
    );
  }
}
