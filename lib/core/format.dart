import 'package:intl/intl.dart';

import 'l10n.dart';

String get _locale => L10n.arabic ? 'ar' : 'en';

/// Short relative time for feed items: "now", "5m", "3h", "2d", "12 Oct".
String relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'now'.tr;
  if (diff.inHours < 1) return '{n}m'.tr.replaceAll('{n}', '${diff.inMinutes}');
  if (diff.inDays < 1) return '{n}h'.tr.replaceAll('{n}', '${diff.inHours}');
  if (diff.inDays < 7) return '{n}d'.tr.replaceAll('{n}', '${diff.inDays}');
  final sameYear = time.year == DateTime.now().year;
  return DateFormat(sameYear ? 'd MMM' : 'd MMM y', _locale).format(time);
}

/// "26 October 2027".
String fullDate(DateTime time) => DateFormat('d MMMM y', _locale).format(time);

/// "October 2026".
String monthYear(DateTime time) => DateFormat('MMMM y', _locale).format(time);

/// "2026-10-27": a language-independent key for a calendar day.
String dayKey(DateTime time) =>
    '${time.year}-${time.month.toString().padLeft(2, '0')}-'
    '${time.day.toString().padLeft(2, '0')}';

/// The coming 8:00 in the morning that is at least an hour away, so a
/// "morning note" sent late at night arrives the next day.
DateTime nextMorning(DateTime now) {
  final today = DateTime(now.year, now.month, now.day, 8);
  return today.difference(now) >= const Duration(hours: 1)
      ? today
      : DateTime(now.year, now.month, now.day + 1, 8);
}

/// "9:41".
String clockTime(DateTime time) => DateFormat('H:mm', _locale).format(time);

/// Human countdown until a capsule unlocks.
String countdown(DateTime unlockAt) {
  final diff = unlockAt.difference(DateTime.now());
  if (diff.isNegative) return 'Ready to open'.tr;
  // Round up to whole days: a capsule set "1 year" ahead is a few
  // minutes short of 365 days by the time it's displayed.
  final days = (diff.inMinutes / Duration.minutesPerDay).ceil();
  if (days >= 365) {
    final years = (days / 365).floor();
    return (years == 1 ? 'Opens in 1 year' : 'Opens in {n} years').tr
        .replaceAll('{n}', '$years');
  }
  if (diff.inDays >= 1) {
    return (days == 1 ? 'Opens tomorrow' : 'Opens in {n} days').tr.replaceAll(
      '{n}',
      '$days',
    );
  }
  if (diff.inHours >= 1) {
    return 'Opens in {n} hours'.tr.replaceAll('{n}', '${diff.inHours}');
  }
  return 'Opens in {n} minutes'.tr.replaceAll(
    '{n}',
    '${diff.inMinutes.clamp(1, 59)}',
  );
}

/// Parses dates of birth stored as "M/d/yyyy" or "d/M/yyyy".
DateTime? parseBirthDate(String? raw) {
  final parts = raw?.split('/');
  if (parts == null || parts.length != 3) return null;
  final a = int.tryParse(parts[0]);
  final b = int.tryParse(parts[1]);
  final y = int.tryParse(parts[2]);
  if (a == null || b == null || y == null) return null;
  return a > 12 ? DateTime(y, b, a) : DateTime(y, a, b);
}

/// The next birthday after [now] (at 9 in the morning), at least a day
/// away so a capsule always has time to be sealed.
DateTime nextBirthday(DateTime birth, DateTime now) {
  var next = DateTime(now.year, birth.month, birth.day, 9);
  if (next.isBefore(now.add(const Duration(days: 1)))) {
    next = DateTime(now.year + 1, birth.month, birth.day, 9);
  }
  return next;
}

/// Formats a date of birth the way existing user documents store it.
String formatBirthDate(DateTime date) =>
    '${date.month}/${date.day}/${date.year}';

/// Whole years between [birth] and today.
int? ageFrom(DateTime? birth) {
  if (birth == null) return null;
  final now = DateTime.now();
  var age = now.year - birth.year;
  if (now.month < birth.month ||
      (now.month == birth.month && now.day < birth.day)) {
    age--;
  }
  return age;
}
