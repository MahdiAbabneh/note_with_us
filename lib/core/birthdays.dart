import '../data/models.dart';
import 'format.dart';

/// A circle member whose birthday is today or tomorrow.
class UpcomingBirthday {
  const UpcomingBirthday(this.user, this.daysAway);

  final AppUser user;

  /// 0 = today, 1 = tomorrow.
  final int daysAway;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// The next time [birth]'s day and month come around, today included
/// (as a midnight date).
DateTime nextBirthdayOnOrAfter(DateTime birth, DateTime now) {
  final today = _day(now);
  final thisYear = DateTime(now.year, birth.month, birth.day);
  return thisYear.isBefore(today)
      ? DateTime(now.year + 1, birth.month, birth.day)
      : thisYear;
}

/// People of [people] with a birthday today or tomorrow, today's first.
List<UpcomingBirthday> upcomingBirthdays(
  Iterable<AppUser> people,
  DateTime now,
) {
  final today = _day(now);
  final found = <UpcomingBirthday>[];
  for (final person in people) {
    final birth = parseBirthDate(person.dateOfBirth);
    if (birth == null) continue;
    final days = daysBetween(today, nextBirthdayOnOrAfter(birth, now));
    if (days <= 1) found.add(UpcomingBirthday(person, days));
  }
  return found..sort((a, b) {
    final byDay = a.daysAway.compareTo(b.daysAway);
    return byDay != 0 ? byDay : a.user.username.compareTo(b.user.username);
  });
}

/// When to remind about [person]'s next birthday: 9:00 the day before,
/// or null if that moment has already passed this year and the person
/// has no later one (it always has: next year).
DateTime reminderTimeFor(DateTime birth, DateTime now) {
  var birthday = nextBirthdayOnOrAfter(birth, now);
  var at = DateTime(birthday.year, birthday.month, birthday.day - 1, 9);
  if (!at.isAfter(now)) {
    birthday = DateTime(birthday.year + 1, birth.month, birth.day);
    at = DateTime(birthday.year, birthday.month, birthday.day - 1, 9);
  }
  return at;
}
