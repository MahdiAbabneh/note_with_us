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

    test(
      'memories surface 1, 3, 6 months and whole years back on this date',
      () {
        final month = note(DateTime(2026, 9, 27, 9), Mood.calm);
        final threeMonths = note(DateTime(2026, 7, 27, 9), Mood.joy);
        final twoMonths = note(DateTime(2026, 8, 27, 9), Mood.joy);
        final year = note(DateTime(2025, 10, 27, 9), Mood.love);
        final otherDay = note(DateTime(2026, 9, 26, 9), Mood.calm);
        final today = note(DateTime(2026, 10, 27, 8), Mood.calm);
        final archived = note(
          DateTime(2026, 4, 27, 9),
          Mood.calm,
          archived: true,
        );
        final memories = memoriesFor([
          year,
          month,
          twoMonths,
          threeMonths,
          otherDay,
          today,
          archived,
        ], now);
        expect(memories.map((m) => m.months), [1, 3, 12]);
        expect(memories.first.note, same(month));
      },
    );

    test('longest streak finds the best run, not the current one', () {
      expect(longestStreak(const []), 0);
      expect(
        longestStreak([
          DateTime(2026, 10, 1, 9),
          DateTime(2026, 10, 1, 21),
          DateTime(2026, 10, 2),
          DateTime(2026, 10, 3),
          DateTime(2026, 10, 10),
          DateTime(2026, 10, 11),
        ]),
        3,
      );
    });

    test('a month groups notes by day and ignores other months', () {
      final notes = [
        note(DateTime(2026, 10, 2, 9), Mood.plain),
        note(DateTime(2026, 10, 2, 18), Mood.calm),
        note(DateTime(2026, 10, 20, 9), Mood.calm),
        note(DateTime(2026, 9, 30, 9), Mood.joy),
      ];
      final october = MonthInsights.from(notes, DateTime(2026, 10, 15));
      expect(october.notes, 3);
      expect(october.daysWritten, 2);
      expect(october.topMood, Mood.calm);
      // A day with a real mood takes that mood over a plain note.
      expect(october.moodOf(DateTime(2026, 10, 2)), Mood.calm);
      expect(october.moodOf(DateTime(2026, 10, 3)), isNull);
      expect(MonthInsights.from(const [], now).topMood, isNull);
    });

    test('milestones are reached by streak length and note count', () {
      final notes = [
        for (var d = 1; d <= 7; d++) note(DateTime(2026, 10, d, 9), Mood.calm),
      ];
      final reached = {
        for (final m in milestonesFor(notes))
          if (m.reached) '${m.isStreak ? 'streak' : 'notes'}-${m.target}',
      };
      expect(reached, {'streak-3', 'streak-7', 'notes-1'});
      expect(milestonesFor(const []).any((m) => m.reached), isFalse);
    });

    test('knows whether anything was written today', () {
      expect(
        WeekInsights.from([
          note(DateTime(2026, 10, 27, 9), Mood.calm),
        ], now).wroteToday,
        isTrue,
      );
      expect(
        WeekInsights.from([
          note(DateTime(2026, 10, 26, 9), Mood.calm),
        ], now).wroteToday,
        isFalse,
      );
    });

    test('circle answers stay hidden until you have answered', () {
      Note answer(String owner, DateTime time, {String day = '2026-10-27'}) =>
          Note(
            id: '$owner-${time.millisecondsSinceEpoch}',
            audience: Audience.circle,
            text: 'answer',
            images: const [],
            time: time,
            ownerId: owner,
            ownerName: owner,
            ownerImage: '',
            promptDay: day,
          );
      final friend = answer('sam', DateTime(2026, 10, 27, 9));
      final friend2 = answer('lee', DateTime(2026, 10, 27, 11));
      final yesterday = answer(
        'sam',
        DateTime(2026, 10, 26, 9),
        day: '2026-10-26',
      );
      final mine = answer('me', DateTime(2026, 10, 27, 10));

      final before = circleQuestionFor([friend, friend2, yesterday], 'me', now);
      expect(before.answered, isFalse);
      expect(before.others.length, 2);

      final after = circleQuestionFor(
        [friend, mine, friend2, yesterday],
        'me',
        now,
      );
      expect(after.answered, isTrue);
      expect(after.others, [friend2, friend]);
      expect(dayKey(DateTime(2026, 3, 5)), '2026-03-05');
    });

    test('a morning note lands on the next 8:00 that is an hour away', () {
      expect(
        nextMorning(DateTime(2026, 10, 27, 22)),
        DateTime(2026, 10, 28, 8),
      );
      expect(nextMorning(DateTime(2026, 10, 27, 5)), DateTime(2026, 10, 27, 8));
      expect(
        nextMorning(DateTime(2026, 10, 27, 7, 30)),
        DateTime(2026, 10, 28, 8),
      );
      expect(nextMorning(DateTime(2026, 12, 31, 23)), DateTime(2027, 1, 1, 8));
    });

    test('a morning note stays a surprise until it arrives', () {
      Capsule capsule({String kind = morningKind, String owner = 'sam'}) =>
          Capsule(
            id: 'c',
            ownerId: owner,
            ownerName: owner,
            ownerImage: '',
            recipientId: 'me',
            recipientName: 'Me',
            text: '',
            mood: Mood.joy,
            createdAt: DateTime.now(),
            unlockAt: DateTime.now().add(const Duration(hours: 5)),
            opened: false,
            kind: kind,
          );
      expect(capsule().isSurpriseFor('me'), isTrue);
      expect(capsule().isSurpriseFor('sam'), isFalse);
      expect(capsule(kind: '').isSurpriseFor('me'), isFalse);
      expect(capsule(owner: 'me').isSurpriseFor('me'), isFalse);
    });

    test('past-you note is old enough, long enough and steady for 3 days', () {
      final old = note(DateTime(2026, 8, 1), Mood.blue);
      final longEnough = Note(
        id: 'long',
        audience: Audience.private,
        text: 'I wish things felt less heavy lately.',
        images: const [],
        time: DateTime(2026, 8, 1),
        ownerId: 'me',
        ownerName: 'Me',
        ownerImage: '',
      );
      final recent = Note(
        id: 'recent',
        audience: Audience.private,
        text: 'I wish things felt less heavy lately.',
        images: const [],
        time: DateTime(2026, 10, 20),
        ownerId: 'me',
        ownerName: 'Me',
        ownerImage: '',
      );
      // `note()` has the 4-letter text "note": too short to reflect on.
      expect(pastSelfNote([old, recent], now), isNull);
      expect(pastSelfNote([old, longEnough, recent], now), same(longEnough));
      final window = pastSelfWindow(now);
      expect(pastSelfWindow(now.add(const Duration(days: 3))), window + 1);
      expect(pastSelfNote(const [], now), isNull);
    });

    test('plants grow over three days; the garden holds the last 30 days', () {
      expect(plantGrowth(now.subtract(const Duration(hours: 3)), now), 0.45);
      expect(plantGrowth(now.subtract(const Duration(days: 2)), now), 0.75);
      expect(plantGrowth(now.subtract(const Duration(days: 9)), now), 1);

      final today = note(DateTime(2026, 10, 27, 8), Mood.joy);
      final edge = note(DateTime(2026, 9, 28, 8), Mood.calm);
      final tooOld = note(DateTime(2026, 9, 27, 8), Mood.calm);
      final garden = gardenNotes([today, tooOld, edge], now);
      expect(garden, [edge, today]);
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
