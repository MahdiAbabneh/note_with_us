import 'package:flutter/widgets.dart' show Brightness, TextDirection;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mahdeko/core/format.dart';
import 'package:mahdeko/core/insights.dart';
import 'package:mahdeko/data/models.dart';
import 'package:mahdeko/design/tokens.dart';
import 'package:mahdeko/core/l10n.dart';
import 'package:mahdeko/core/l10n_ar.dart';
import 'package:mahdeko/core/prefs.dart';
import 'package:mahdeko/core/prompts.dart';
import 'package:mahdeko/design/components/content_text.dart';

void main() {
  group('birth dates', () {
    test('parses the month/day/year format new accounts store', () {
      expect(parseBirthDate('10/26/2000'), DateTime(2000, 10, 26));
    });

    test('parses day/month/year when the first part is above 12', () {
      expect(parseBirthDate('26/10/2000'), DateTime(2000, 10, 26));
    });

    test('rejects malformed values', () {
      expect(parseBirthDate(''), isNull);
      expect(parseBirthDate('2000-10-26'), isNull);
    });

    test('round-trips through formatBirthDate', () {
      final date = DateTime(1999, 3, 7);
      expect(parseBirthDate(formatBirthDate(date)), date);
    });
  });

  test('nextBirthday picks the coming birthday, at least a day away', () {
    final birth = DateTime(1998, 3, 14);
    expect(nextBirthday(birth, DateTime(2026, 1, 1)), DateTime(2026, 3, 14, 9));
    expect(
      nextBirthday(birth, DateTime(2026, 3, 14, 8)),
      DateTime(2027, 3, 14, 9),
    );
    expect(
      nextBirthday(birth, DateTime(2026, 12, 1)),
      DateTime(2027, 3, 14, 9),
    );
  });

  test('ageFrom counts whole years', () {
    final now = DateTime.now();
    expect(ageFrom(DateTime(now.year - 20, now.month, now.day)), 20);
    expect(ageFrom(DateTime(now.year - 20, now.month, now.day + 1)), 19);
  });

  group('capsule countdown', () {
    final now = DateTime.now();

    test('a capsule sealed for one year reads as a year, not 364 days', () {
      final unlock = now.add(const Duration(days: 365, minutes: -5));
      expect(countdown(unlock), 'Opens in 1 year');
    });

    test('counts whole days and says tomorrow for one day', () {
      expect(
        countdown(now.add(const Duration(days: 12, hours: 3))),
        'Opens in 13 days',
      );
      expect(
        countdown(now.add(const Duration(hours: 23, minutes: 59))),
        'Opens in 23 hours',
      );
      expect(
        countdown(now.add(const Duration(days: 1, minutes: 10))),
        'Opens in 2 days',
      );
    });

    test('past dates are ready to open', () {
      expect(
        countdown(now.subtract(const Duration(minutes: 1))),
        'Ready to open',
      );
    });
  });

  group('weekly insights', () {
    final now = DateTime(2026, 10, 27, 20);
    Note note(DateTime time, Mood mood, {bool archived = false}) => Note(
      id: '${time.millisecondsSinceEpoch}',
      audience: Audience.private,
      text: 'note',
      images: const [],
      time: time,
      ownerId: 'me',
      ownerName: 'Me',
      ownerImage: '',
      mood: mood,
      archived: archived,
    );

    test('counts days, moods and a streak that ignores an unwritten today', () {
      final notes = [
        note(DateTime(2026, 10, 26, 9), Mood.calm),
        note(DateTime(2026, 10, 25, 9), Mood.joy),
        note(DateTime(2026, 10, 25, 21), Mood.calm),
        note(DateTime(2026, 10, 24, 9), Mood.plain),
        note(DateTime(2026, 10, 15, 9), Mood.blue),
      ];
      final week = WeekInsights.from(notes, now);
      expect(week.days.length, 7);
      expect(week.days.last.date, DateTime(2026, 10, 27));
      expect(week.daysWritten, 3);
      expect(week.notesThisWeek, 4);
      expect(week.streak, 3);
      expect(week.favoriteMood, Mood.calm);
      expect(week.moodsThisMonth[Mood.blue], 1);
      expect(week.moodsThisWeek.containsKey(Mood.plain), isFalse);
    });

    test('a gap ends the streak; no notes means no streak', () {
      final notes = [
        note(DateTime(2026, 10, 27, 9), Mood.calm),
        note(DateTime(2026, 10, 25, 9), Mood.calm),
      ];
      expect(WeekInsights.from(notes, now).streak, 1);
      expect(WeekInsights.from(const [], now).streak, 0);
    });

    test('note of the day skips recent and archived notes', () {
      expect(
        noteOfTheDay([note(DateTime(2026, 10, 26), Mood.calm)], now),
        isNull,
      );
      expect(
        noteOfTheDay([
          note(DateTime(2026, 1, 2), Mood.calm, archived: true),
        ], now),
        isNull,
      );
      final old = note(DateTime(2026, 1, 2), Mood.joy);
      expect(noteOfTheDay([old], now), same(old));
    });
  });

  test('notes without a mood still get a steady soft colour', () {
    final c = NwuColors.of(Brightness.light, Accent.values.first);
    expect(c.paperTint(Mood.love, 'any'), c.moodTint(Mood.love));
    expect(c.paperTint(Mood.plain, 'abc'), c.paperTint(Mood.plain, 'abc'));
    final tints = {
      for (final id in ['a', 'b', 'c', 'd', 'e', 'f', 'g'])
        c.paperTint(Mood.plain, id),
    };
    expect(tints.contains(c.raised), isFalse);
    expect(tints.length, greaterThan(1));
  });

  test('user text keeps its own direction', () {
    expect(
      contentDirection('Test note. Private journal check.'),
      TextDirection.ltr,
    );
    expect(contentDirection('مرحبا بالجميع'), TextDirection.rtl);
  });

  test('only answering today\'s prompt marks it answered', () async {
    SharedPreferences.setMockInitialValues({});
    await Prefs.init();
    final state = PromptState.instance;
    expect(state.answeredToday, isFalse);
    state.noteAnswered('Some other question');
    expect(state.answeredToday, isFalse);
    state.noteAnswered(state.today);
    expect(state.answeredToday, isTrue);
    expect(state.hiddenToday, isFalse);
    state.hideForToday();
    expect(state.hiddenToday, isTrue);
  });

  test('every daily prompt has an Arabic version', () {
    L10n.arabic = false;
    final english = promptFor(DateTime(2026, 1, 1));
    L10n.arabic = true;
    final arabic = promptFor(DateTime(2026, 1, 1));
    L10n.arabic = false;
    expect(arabic, isNot(english));
  });

  test('Arabic strings have no empty translations', () {
    expect(arabicStrings.values.where((v) => v.trim().isEmpty), isEmpty);
  });
}
