import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import 'format.dart';
import 'l10n.dart';
import 'settings.dart';

/// A date in the Hijri (Islamic) calendar.
class HijriDate {
  const HijriDate(this.year, this.month, this.day);

  final int year;

  /// 1 = Muharram … 9 = Ramadan … 12 = Dhu al-Hijjah.
  final int month;
  final int day;

  @override
  bool operator ==(Object other) =>
      other is HijriDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => '$year-$month-$day';
}

const _monthsEn = [
  'Muharram',
  'Safar',
  'Rabi’ al-Awwal',
  'Rabi’ al-Thani',
  'Jumada al-Awwal',
  'Jumada al-Thani',
  'Rajab',
  'Sha’ban',
  'Ramadan',
  'Shawwal',
  'Dhu al-Qi’dah',
  'Dhu al-Hijjah',
];

const _monthsAr = [
  'محرم',
  'صفر',
  'ربيع الأول',
  'ربيع الآخر',
  'جمادى الأولى',
  'جمادى الآخرة',
  'رجب',
  'شعبان',
  'رمضان',
  'شوال',
  'ذو القعدة',
  'ذو الحجة',
];

/// The Hijri date of [date] (Umm al-Qura calendar) moved by [offset] days;
/// the offset defaults to the user's setting.
HijriDate hijriOf(DateTime date, {int? offset}) {
  final days = offset ?? AppSettings.instance.hijriOffset;
  final shifted = DateTime(date.year, date.month, date.day + days);
  final h = HijriCalendar.fromDate(shifted);
  return HijriDate(h.hYear, h.hMonth, h.hDay);
}

/// The Gregorian day on which the Hijri date [year]-[month]-[day] falls
/// (the inverse of [hijriOf] for the same [offset]).
DateTime gregorianOf(int year, int month, int day, {int? offset}) {
  final days = offset ?? AppSettings.instance.hijriOffset;
  final g = HijriCalendar().hijriToGregorian(year, month, day);
  return DateTime(g.year, g.month, g.day - days);
}

/// Name of Hijri month [month] (1…12) in the app language.
String hijriMonthName(int month) =>
    (L10n.arabic ? _monthsAr : _monthsEn)[(month - 1).clamp(0, 11)];

String _digits(int n) => L10n.arabic ? NumberFormat('0', 'ar').format(n) : '$n';

/// "6 Rabi’ al-Thani 1448 AH" / "٦ ربيع الآخر ١٤٤٨ هـ".
String formatHijri(DateTime date, {bool withYear = true}) {
  final h = hijriOf(date);
  final base = '${_digits(h.day)} ${hijriMonthName(h.month)}';
  if (!withYear) return base;
  return '$base ${_digits(h.year)} ${L10n.arabic ? 'هـ' : 'AH'}';
}

/// The usual full date, followed by the Hijri date when that is on.
String fullDateWithHijri(DateTime date) => AppSettings.instance.hijri
    ? '${fullDate(date)}  ·  ${formatHijri(date)}'
    : fullDate(date);

/// Hijri year of [date].
int hijriYearOf(DateTime date) => hijriOf(date).year;

/// The Hijri month(s) a Gregorian month spans, e.g. "Rabi’ al-Thani –
/// Jumada al-Awwal 1448 AH".
String hijriRangeOf(DateTime firstDay, DateTime lastDay) {
  final a = hijriOf(firstDay);
  final b = hijriOf(lastDay);
  final suffix = L10n.arabic ? 'هـ' : 'AH';
  if (a.year == b.year && a.month == b.month) {
    return '${hijriMonthName(a.month)} ${_digits(a.year)} $suffix';
  }
  if (a.year == b.year) {
    return '${hijriMonthName(a.month)} – ${hijriMonthName(b.month)} '
        '${_digits(a.year)} $suffix';
  }
  return '${hijriMonthName(a.month)} ${_digits(a.year)} – '
      '${hijriMonthName(b.month)} ${_digits(b.year)} $suffix';
}
