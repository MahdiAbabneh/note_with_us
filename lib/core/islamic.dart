import '../data/models.dart';
import '../design/tokens.dart';
import 'hijri.dart';
import 'insights.dart' as insights;
import 'l10n.dart';
import 'tags.dart';

/// Muslim occasions the app knows about.
enum IslamicOccasion {
  ramadan,
  eidAlFitr,
  arafahDay,
  eidAlAdha,
  islamicNewYear,
}

extension IslamicOccasionInfo on IslamicOccasion {
  /// Hijri (month, day) the occasion starts on.
  (int, int) get start => switch (this) {
    IslamicOccasion.ramadan => (9, 1),
    IslamicOccasion.eidAlFitr => (10, 1),
    IslamicOccasion.arafahDay => (12, 9),
    IslamicOccasion.eidAlAdha => (12, 10),
    IslamicOccasion.islamicNewYear => (1, 1),
  };

  String get label => switch (this) {
    IslamicOccasion.ramadan => 'Ramadan'.tr,
    IslamicOccasion.eidAlFitr => 'Eid al-Fitr'.tr,
    IslamicOccasion.arafahDay => 'Day of Arafah'.tr,
    IslamicOccasion.eidAlAdha => 'Eid al-Adha'.tr,
    IslamicOccasion.islamicNewYear => 'Islamic New Year'.tr,
  };
}

/// The occasion [date] falls in: all of Ramadan, three days of Eid
/// al-Fitr (1–3 Shawwal), Arafah (9 Dhu al-Hijjah), Eid al-Adha (10–12
/// Dhu al-Hijjah) and 1 Muharram. [offset] is the Hijri day adjustment;
/// it defaults to the user's setting.
IslamicOccasion? occasionOn(DateTime date, {int? offset}) {
  final h = hijriOf(date, offset: offset);
  if (h.month == 9) return IslamicOccasion.ramadan;
  if (h.month == 10 && h.day <= 3) return IslamicOccasion.eidAlFitr;
  if (h.month == 12 && h.day == 9) return IslamicOccasion.arafahDay;
  if (h.month == 12 && h.day >= 10 && h.day <= 12) {
    return IslamicOccasion.eidAlAdha;
  }
  if (h.month == 1 && h.day == 1) return IslamicOccasion.islamicNewYear;
  return null;
}

/// 1…30 during Ramadan, otherwise null.
int? ramadanDay(DateTime date, {int? offset}) {
  final h = hijriOf(date, offset: offset);
  return h.month == 9 ? h.day : null;
}

/// Whether [date] is in the ten days after Eid al-Fitr, when "Your
/// Ramadan" is still worth a look.
bool isAfterRamadan(DateTime date, {int? offset}) {
  final h = hijriOf(date, offset: offset);
  return h.month == 10 && h.day > 3 && h.day <= 12;
}

/// The next start of [occasion] (at 8:00) that is at least a day after
/// [from], so a capsule has time to be sealed.
DateTime nextOccasionStart(
  IslamicOccasion occasion,
  DateTime from, {
  int? offset,
}) {
  final (month, day) = occasion.start;
  final year = hijriOf(from, offset: offset).year;
  for (var y = year; y <= year + 2; y++) {
    final g = gregorianOf(y, month, day, offset: offset);
    final at = DateTime(g.year, g.month, g.day, 8);
    if (at.isAfter(from.add(const Duration(days: 1)))) return at;
  }
  return from.add(const Duration(days: 365));
}

/// First and last day of Ramadan in Hijri [year] (midnight dates).
(DateTime, DateTime) ramadanRange(int year, {int? offset}) {
  final first = gregorianOf(year, 9, 1, offset: offset);
  final firstOfShawwal = gregorianOf(year, 10, 1, offset: offset);
  return (
    first,
    DateTime(firstOfShawwal.year, firstOfShawwal.month, firstOfShawwal.day - 1),
  );
}

/// The Hijri year of the Ramadan that [date] is in or has just left.
int ramadanYearFor(DateTime date, {int? offset}) =>
    hijriOf(date, offset: offset).year;

/// Greeting text for an Eid note or capsule.
String eidGreeting(IslamicOccasion occasion) =>
    occasion == IslamicOccasion.eidAlAdha
    ? 'Eid Mubarak! Wishing you a blessed Eid al-Adha.'.tr
    : 'Eid Mubarak! Taqabbal Allahu minna wa minkum.'.tr;

/// A Ramadan prompt for each of its 30 days, as (English, Arabic).
const List<(String, String)> ramadanPrompts = [
  (
    'What do you hope this Ramadan brings you?',
    'ماذا تتمنى أن يمنحك هذا رمضان؟',
  ),
  ('What are you grateful for today?', 'ما الذي تشكر الله عليه اليوم؟'),
  ('Who do you want to make dua for tonight?', 'لمن تريد أن تدعو الليلة؟'),
  (
    'What small good deed did you do today?',
    'ما العمل الطيب الصغير الذي قمت به اليوم؟',
  ),
  (
    'Who did you break your fast with, and what did you talk about?',
    'مع من أفطرت اليوم، وعمّ تحدثتم؟',
  ),
  (
    'What is a habit you want to build this month?',
    'ما العادة التي تريد بناءها هذا الشهر؟',
  ),
  (
    'Describe a Ramadan memory that makes you smile.',
    'صف ذكرى رمضانية تجعلك تبتسم.',
  ),
  (
    'Who do you want to forgive, or ask forgiveness from?',
    'من تريد أن تسامحه أو تطلب منه السماح؟',
  ),
  (
    'How did the quiet moments of today feel?',
    'كيف كانت لحظات الهدوء في يومك؟',
  ),
  ('What is something you want to let go of?', 'ما الذي تريد أن تتخلى عنه؟'),
  ('What is a blessing you usually overlook?', 'ما نعمة تغفل عنها عادة؟'),
  ('Who in your life deserves a thank-you?', 'من في حياتك يستحق كلمة شكر؟'),
  ('What helped you stay patient today?', 'ما الذي ساعدك على الصبر اليوم؟'),
  (
    'Write about a meal that reminds you of home.',
    'اكتب عن وجبة تذكّرك بالبيت.',
  ),
  (
    'What are you learning about yourself this month?',
    'ماذا تتعلم عن نفسك هذا الشهر؟',
  ),
  (
    'Who is far from you that you miss tonight?',
    'من هو بعيد عنك وتشتاق إليه الليلة؟',
  ),
  (
    'What act of kindness did someone do for you lately?',
    'ما اللطف الذي قدّمه لك أحدهم مؤخرًا؟',
  ),
  (
    'What is one thing you can give or share today?',
    'ما الذي تستطيع أن تعطيه أو تشاركه اليوم؟',
  ),
  (
    'What do you want to remember about this Ramadan?',
    'ماذا تريد أن تتذكر عن رمضان هذا العام؟',
  ),
  (
    'What are you asking for in your dua this week?',
    'ماذا تسأل في دعائك هذا الأسبوع؟',
  ),
  (
    'How have your mornings changed this month?',
    'كيف تغيّرت صباحاتك هذا الشهر؟',
  ),
  (
    'Write a short letter to yourself for after Ramadan.',
    'اكتب رسالة قصيرة لنفسك لما بعد رمضان.',
  ),
  ('What gives you hope right now?', 'ما الذي يمنحك الأمل الآن؟'),
  ('Who made your day easier today?', 'من خفّف عنك اليوم؟'),
  (
    'What is a lesson you want to carry on?',
    'ما الدرس الذي تريد أن تحمله معك؟',
  ),
  (
    'Which part of the day do you love most this month?',
    'أي وقت من اليوم تحبه أكثر هذا الشهر؟',
  ),
  (
    'What do you wish for the people you love?',
    'ماذا تتمنى للأشخاص الذين تحبهم؟',
  ),
  (
    'What has changed in you since the first day?',
    'ما الذي تغيّر فيك منذ أول يوم؟',
  ),
  ('What will you keep doing after Ramadan?', 'ما الذي ستواصله بعد رمضان؟'),
  (
    'Write down your final thanks for this month.',
    'اكتب شكرك الأخير لهذا الشهر.',
  ),
];

/// The prompt for Ramadan [day] (1…30) in the app language.
String ramadanPrompt(int day) {
  final (en, ar) =
      ramadanPrompts[(day - 1).clamp(0, ramadanPrompts.length - 1)];
  return L10n.arabic ? ar : en;
}

/// A look back at Ramadan from your own notes.
class RamadanStats {
  const RamadanStats({
    required this.totalDays,
    required this.elapsedDays,
    required this.notes,
    required this.daysWritten,
    required this.longestStreak,
    required this.topMood,
    required this.topTags,
  });

  /// 29 or 30.
  final int totalDays;

  /// Days of Ramadan that have started (up to today).
  final int elapsedDays;
  final int notes;
  final int daysWritten;
  final int longestStreak;
  final Mood? topMood;
  final List<String> topTags;

  /// Notes of [start]…[end] (inclusive, midnight dates) as of [now].
  factory RamadanStats.from(
    Iterable<Note> all,
    DateTime start,
    DateTime end,
    DateTime now,
  ) {
    final endExclusive = DateTime(end.year, end.month, end.day + 1);
    final inRange = [
      for (final n in all)
        if (!n.archived &&
            !n.time.isBefore(start) &&
            n.time.isBefore(endExclusive))
          n,
    ];
    final total = endExclusive.difference(start).inDays;
    final today = DateTime(now.year, now.month, now.day);
    final elapsed = today.isBefore(start)
        ? 0
        : (today.difference(start).inDays + 1).clamp(0, total);
    final days = {
      for (final n in inRange) DateTime(n.time.year, n.time.month, n.time.day),
    };
    final moods = <Mood, int>{};
    for (final n in inRange.where((n) => n.mood != Mood.plain)) {
      moods[n.mood] = (moods[n.mood] ?? 0) + 1;
    }
    final top = moods.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return RamadanStats(
      totalDays: total,
      elapsedDays: elapsed,
      notes: inRange.length,
      daysWritten: days.length,
      longestStreak: insights.longestStreak(days),
      topMood: top.isEmpty ? null : top.first.key,
      topTags: [for (final e in tagCounts(inRange).take(5)) e.key],
    );
  }
}
