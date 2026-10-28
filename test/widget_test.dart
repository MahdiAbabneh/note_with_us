import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart' show Brightness, TextDirection;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mahdeko/core/birthdays.dart';
import 'package:mahdeko/core/format.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mahdeko/core/hijri.dart';
import 'package:mahdeko/core/insights.dart';
import 'package:mahdeko/core/islamic.dart';
import 'package:mahdeko/core/journal_pdf.dart';
import 'package:mahdeko/data/models.dart';
import 'package:mahdeko/design/tokens.dart';
import 'package:mahdeko/core/l10n.dart';
import 'package:mahdeko/core/l10n_ar.dart';
import 'package:mahdeko/core/patterns.dart';
import 'package:mahdeko/core/prefs.dart';
import 'package:mahdeko/features/freewrite/free_write_screen.dart';
import 'package:mahdeko/core/prompts.dart';
import 'package:mahdeko/core/tags.dart';
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

    test('one rest day a week keeps the streak; two in a row end it', () {
      final restDay = [
        note(DateTime(2026, 10, 27, 9), Mood.calm),
        note(DateTime(2026, 10, 25, 9), Mood.calm),
      ];
      // 26th is a rest day, so 27th and 25th both count.
      expect(WeekInsights.from(restDay, now).streak, 2);

      final twoMissed = [
        note(DateTime(2026, 10, 27, 9), Mood.calm),
        note(DateTime(2026, 10, 24, 9), Mood.calm),
      ];
      expect(WeekInsights.from(twoMissed, now).streak, 1);
      expect(WeekInsights.from(const [], now).streak, 0);
    });

    test('only one rest day is forgiven in any week', () {
      // Written: 27, 25, 23 with 26 and 24 missed inside one week.
      final days = {
        DateTime(2026, 10, 27),
        DateTime(2026, 10, 25),
        DateTime(2026, 10, 23),
      };
      expect(streakFromDays(days, DateTime(2026, 10, 27)), 2);
      // A rest day more than a week after the last one is forgiven again.
      final spaced = {
        DateTime(2026, 10, 27),
        DateTime(2026, 10, 25),
        for (var d = 18; d <= 24; d++) DateTime(2026, 10, d),
        for (var d = 10; d <= 16; d++) DateTime(2026, 10, d),
      };
      // Rest days on the 26th and the 17th, nine days apart.
      expect(streakFromDays(spaced, DateTime(2026, 10, 27)), 16);
      // An unwritten today never ends it.
      expect(
        streakFromDays({
          DateTime(2026, 10, 26),
          DateTime(2026, 10, 25),
        }, DateTime(2026, 10, 27)),
        2,
      );
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

    test('a notebook for two alternates turns and knows the other person', () {
      final notebook = SharedNotebook(
        id: 'n',
        ownerId: 'alice',
        title: 'Us',
        members: const ['alice', 'bob'],
        memberNames: const {'alice': 'Alice', 'bob': 'Bob'},
        createdAt: now,
      );
      expect(notebook.otherId('alice'), 'bob');
      expect(notebook.otherId('bob'), 'alice');
      // Nobody has written yet, so either person may start.
      expect(notebook.isMyTurn('alice'), isTrue);
      expect(notebook.isMyTurn('bob'), isTrue);
      final after = SharedNotebook(
        id: 'n',
        ownerId: 'alice',
        title: 'Us',
        members: const ['alice', 'bob'],
        memberNames: const {},
        createdAt: now,
        lastWriterId: 'alice',
        entryCount: 1,
      );
      expect(after.isMyTurn('alice'), isFalse);
      expect(after.isMyTurn('bob'), isTrue);
    });

    test('a circle capsule tracks who has written and when it opens', () {
      GroupCapsule capsule(Duration opensIn) => GroupCapsule(
        id: 'g',
        ownerId: 'alice',
        ownerName: 'Alice',
        title: 'New Year',
        createdAt: now,
        unlockAt: DateTime.now().add(opensIn),
        members: const ['alice', 'bob', 'carol'],
        written: const {'bob'},
      );
      expect(capsule(const Duration(days: 3)).isUnlocked, isFalse);
      expect(capsule(const Duration(days: -1)).isUnlocked, isTrue);
      expect(capsule(const Duration(days: 3)).hasWritten('bob'), isTrue);
      expect(capsule(const Duration(days: 3)).hasWritten('carol'), isFalse);
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

  group('tags', () {
    test('finds #tags in English and Arabic, once each, lower-cased', () {
      expect(extractTags('Dinner with #Family and #عائلة, #family again'), [
        'family',
        'عائلة',
      ]);
    });

    test('ignores lone hashes, numbers and tags glued to a word', () {
      expect(extractTags('# alone, #123, issue#4, ##double, a#b'), isEmpty);
      expect(extractTags('(#work) and "#goals".'), ['work', 'goals']);
    });

    test('splitTags keeps every character', () {
      const text = 'Hello #family, bye #work';
      final parts = splitTags(text);
      expect(parts.map((p) => p.text).join(), text);
      expect(parts.where((p) => p.isTag).map((p) => p.tag), ['family', 'work']);
    });

    test('counts tags across notes, most used first', () {
      Note n(String text) => Note(
        id: text,
        audience: Audience.private,
        text: text,
        images: const [],
        time: DateTime(2026, 10, 1),
        ownerId: 'me',
        ownerName: 'Me',
        ownerImage: '',
      );
      final counts = tagCounts([
        n('a #work'),
        n('b #family #work'),
        n('c #work #work'),
        n('d'),
      ]);
      expect(counts.map((e) => '${e.key}:${e.value}'), ['work:3', 'family:1']);
      expect(hasTag(n('x #Family'), 'FAMILY'), isTrue);
      expect(hasTag(n('x family'), 'family'), isFalse);
    });
  });

  group('hijri dates', () {
    test('converts known Umm al-Qura dates both ways', () {
      // Ramadan 1446 began on 1 March 2025, Eid al-Fitr on 30 March and
      // Eid al-Adha on 6 June.
      expect(
        hijriOf(DateTime(2025, 3, 1), offset: 0),
        const HijriDate(1446, 9, 1),
      );
      expect(
        hijriOf(DateTime(2025, 3, 30), offset: 0),
        const HijriDate(1446, 10, 1),
      );
      expect(
        hijriOf(DateTime(2025, 6, 6), offset: 0),
        const HijriDate(1446, 12, 10),
      );
      expect(gregorianOf(1446, 9, 1, offset: 0), DateTime(2025, 3, 1));
      expect(gregorianOf(1446, 12, 10, offset: 0), DateTime(2025, 6, 6));
    });

    test('the day adjustment moves dates and round-trips', () {
      // A country one day behind: 2 March is its 1 Ramadan.
      expect(
        hijriOf(DateTime(2025, 3, 2), offset: -1),
        const HijriDate(1446, 9, 1),
      );
      expect(gregorianOf(1446, 9, 1, offset: -1), DateTime(2025, 3, 2));
      for (final offset in [-2, -1, 0, 1, 2]) {
        final date = DateTime(2026, 7, 15);
        final h = hijriOf(date, offset: offset);
        expect(gregorianOf(h.year, h.month, h.day, offset: offset), date);
      }
    });

    test('month names come in both languages', () {
      L10n.arabic = false;
      expect(hijriMonthName(9), 'Ramadan');
      L10n.arabic = true;
      expect(hijriMonthName(9), 'رمضان');
      expect(hijriMonthName(12), 'ذو الحجة');
      L10n.arabic = false;
    });
  });

  group('islamic occasions', () {
    test('finds Ramadan, the Eids and the days after, by Hijri date', () {
      IslamicOccasion? on(int y, int m, int d) =>
          occasionOn(DateTime(y, m, d), offset: 0);
      // Ramadan 1446: 1 March to 29 March 2025; Eid al-Fitr 30 March.
      expect(on(2025, 2, 28), isNull);
      expect(on(2025, 3, 1), IslamicOccasion.ramadan);
      expect(on(2025, 3, 29), IslamicOccasion.ramadan);
      expect(on(2025, 3, 30), IslamicOccasion.eidAlFitr);
      expect(on(2025, 4, 1), IslamicOccasion.eidAlFitr);
      expect(on(2025, 4, 2), isNull);
      expect(isAfterRamadan(DateTime(2025, 4, 2), offset: 0), isTrue);
      expect(isAfterRamadan(DateTime(2025, 3, 31), offset: 0), isFalse);
      // Arafah 5 June, Eid al-Adha 6-8 June 2025.
      expect(on(2025, 6, 5), IslamicOccasion.arafahDay);
      expect(on(2025, 6, 6), IslamicOccasion.eidAlAdha);
      expect(on(2025, 6, 8), IslamicOccasion.eidAlAdha);
      expect(on(2025, 6, 9), isNull);
      expect(on(2025, 6, 26), IslamicOccasion.islamicNewYear);
      expect(ramadanDay(DateTime(2025, 3, 10), offset: 0), 10);
      expect(ramadanDay(DateTime(2025, 4, 10), offset: 0), isNull);
    });

    test('finds the next start of an occasion, a day or more away', () {
      final from = DateTime(2025, 4, 10, 12);
      expect(
        nextOccasionStart(IslamicOccasion.eidAlAdha, from, offset: 0),
        DateTime(2025, 6, 6, 8),
      );
      final next = nextOccasionStart(
        IslamicOccasion.eidAlFitr,
        from,
        offset: 0,
      );
      expect(next.isAfter(DateTime(2026, 3, 1)), isTrue);
      expect(next.isBefore(DateTime(2026, 4, 1)), isTrue);
      expect(next.hour, 8);
      // Too close to seal a capsule: it moves to the following year.
      final eve = DateTime(2025, 3, 30, 1);
      expect(
        nextOccasionStart(IslamicOccasion.eidAlFitr, eve, offset: 0).year,
        2026,
      );
    });

    test('Ramadan range and stats', () {
      final (start, end) = ramadanRange(1446, offset: 0);
      expect(start, DateTime(2025, 3, 1));
      expect(end, DateTime(2025, 3, 29));
      Note n(DateTime time, Mood mood, String text) => Note(
        id: '${time.millisecondsSinceEpoch}',
        audience: Audience.private,
        text: text,
        images: const [],
        time: time,
        ownerId: 'me',
        ownerName: 'Me',
        ownerImage: '',
        mood: mood,
      );
      final notes = [
        n(DateTime(2025, 2, 28, 9), Mood.joy, 'before'),
        n(DateTime(2025, 3, 1, 21), Mood.calm, 'start #ramadan'),
        n(DateTime(2025, 3, 2, 21), Mood.calm, 'day two #ramadan'),
        n(DateTime(2025, 3, 3, 21), Mood.joy, 'day three'),
        n(DateTime(2025, 3, 10, 21), Mood.calm, 'later'),
        n(DateTime(2025, 3, 30, 9), Mood.joy, 'eid'),
      ];
      final stats = RamadanStats.from(notes, start, end, DateTime(2025, 3, 12));
      expect(stats.totalDays, 29);
      expect(stats.elapsedDays, 12);
      expect(stats.notes, 4);
      expect(stats.daysWritten, 4);
      expect(stats.longestStreak, 3);
      expect(stats.topMood, Mood.calm);
      expect(stats.topTags, ['ramadan']);
      // After the month, every day has started.
      expect(
        RamadanStats.from(notes, start, end, DateTime(2025, 4, 5)).elapsedDays,
        29,
      );
    });

    test('every Ramadan day has a prompt in both languages', () {
      expect(ramadanPrompts.length, 30);
      for (final (en, ar) in ramadanPrompts) {
        expect(en.trim(), isNotEmpty);
        expect(ar.trim(), isNotEmpty);
      }
    });
  });

  group('friends birthdays', () {
    AppUser person(String name, String dob) =>
        AppUser(uid: name, username: name, dateOfBirth: dob);
    final now = DateTime(2026, 10, 27, 14);

    test('finds birthdays today and tomorrow, today first', () {
      final found = upcomingBirthdays([
        person('Tomorrow', '10/28/1990'),
        person('Today', '10/27/2001'),
        person('Later', '11/15/1999'),
        person('Yesterday', '10/26/1999'),
        person('NoDate', ''),
      ], now);
      expect(found.map((b) => '${b.user.username}:${b.daysAway}'), [
        'Today:0',
        'Tomorrow:1',
      ]);
    });

    test('wraps over the new year', () {
      final found = upcomingBirthdays([
        person('NewYear', '1/1/1990'),
      ], DateTime(2026, 12, 31, 9));
      expect(found.single.daysAway, 1);
    });

    test('reminds at 9:00 the day before, never in the past', () {
      // 28 Oct: this year's reminder (27 Oct, 9:00) has already passed.
      expect(
        reminderTimeFor(DateTime(1990, 10, 28), now),
        DateTime(2027, 10, 27, 9),
      );
      expect(
        reminderTimeFor(DateTime(1990, 11, 15), now),
        DateTime(2026, 11, 14, 9),
      );
      // Birthday today: next year's reminder.
      expect(
        reminderTimeFor(DateTime(1990, 10, 27), now),
        DateTime(2027, 10, 26, 9),
      );
      // 1 January, seen on the morning of 31 December.
      expect(
        reminderTimeFor(DateTime(1990, 1, 1), DateTime(2026, 12, 31, 8)),
        DateTime(2026, 12, 31, 9),
      );
    });
  });

  group('comfort box', () {
    final now = DateTime(2026, 10, 27, 20);
    Note note(
      String text,
      Mood mood,
      DateTime time, {
      bool comfort = false,
      bool archived = false,
    }) => Note(
      id: text,
      audience: Audience.private,
      text: text,
      images: const [],
      time: time,
      ownerId: 'me',
      ownerName: 'Me',
      ownerImage: '',
      mood: mood,
      comfort: comfort,
      archived: archived,
    );
    Capsule capsule({
      String kind = morningKind,
      bool opened = true,
      String owner = 'sam',
      String text = 'You are loved.',
    }) => Capsule(
      id: 'c$kind$owner$opened',
      ownerId: owner,
      ownerName: owner,
      ownerImage: '',
      recipientId: 'me',
      recipientName: 'Me',
      text: text,
      mood: Mood.joy,
      createdAt: now,
      unlockAt: now.subtract(const Duration(days: 1)),
      opened: opened,
      kind: kind,
    );

    test('kept notes and friends\' opened morning notes come first', () {
      final kept = note(
        'Kept for a hard day',
        Mood.joy,
        DateTime(2026, 5, 1),
        comfort: true,
      );
      final happy = note(
        'A happy day long ago, remembered.',
        Mood.joy,
        DateTime(2026, 1, 1),
      );
      final friend = capsule();
      final seen = <String>{};
      for (var seed = 0; seed < 30; seed++) {
        final item = pickComfort(
          [kept, happy],
          [friend],
          'me',
          now,
          Random(seed),
        )!;
        seen.add(item.text);
      }
      expect(seen, {'Kept for a hard day', 'You are loved.'});
    });

    test('ignores unopened, normal and own capsules and archived notes', () {
      final item = pickComfort(
        [
          note(
            'Archived comfort',
            Mood.joy,
            DateTime(2026, 5, 1),
            comfort: true,
            archived: true,
          ),
        ],
        [capsule(opened: false), capsule(kind: ''), capsule(owner: 'me')],
        'me',
        now,
        Random(1),
      );
      expect(item, isNull);
    });

    test('falls back to an older happy note, and offers another one', () {
      final a = note(
        'A happy day long ago, remembered A.',
        Mood.joy,
        DateTime(2026, 1, 1),
      );
      final b = note(
        'A happy day long ago, remembered B.',
        Mood.love,
        DateTime(2026, 2, 1),
      );
      final recent = note(
        'A happy day just now, remembered.',
        Mood.joy,
        DateTime(2026, 10, 26),
      );
      final blue = note(
        'A sad day long ago, remembered...',
        Mood.blue,
        DateTime(2026, 1, 1),
      );
      final first = pickComfort(
        [a, b, recent, blue],
        const [],
        'me',
        now,
        Random(3),
      )!;
      expect(first.text, anyOf(a.text, b.text));
      final next = pickComfort(
        [a, b, recent, blue],
        const [],
        'me',
        now,
        Random(3),
        except: first,
      )!;
      expect(next.text, isNot(first.text));
      expect(pickComfort(const [], const [], 'me', now, Random(1)), isNull);
    });
  });

  group('patterns', () {
    final now = DateTime(2026, 10, 28, 12);
    Note n(DateTime time, String text, Mood mood) => Note(
      id: '${time.millisecondsSinceEpoch}$text',
      audience: Audience.private,
      text: text,
      images: const [],
      time: time,
      ownerId: 'me',
      ownerName: 'Me',
      ownerImage: '',
      mood: mood,
    );

    test('parts of the day', () {
      expect(dayPartOf(DateTime(2026, 1, 1, 6)), DayPart.morning);
      expect(dayPartOf(DateTime(2026, 1, 1, 13)), DayPart.afternoon);
      expect(dayPartOf(DateTime(2026, 1, 1, 19)), DayPart.evening);
      expect(dayPartOf(DateTime(2026, 1, 1, 23)), DayPart.night);
      expect(dayPartOf(DateTime(2026, 1, 1, 2)), DayPart.night);
    });

    test('finds the usual mood of a weekday, only with enough notes', () {
      // Fridays are 2, 9, 16 October 2026; Mondays are 5 and 12.
      final notes = [
        n(DateTime(2026, 10, 2, 9), 'Friday one', Mood.calm),
        n(DateTime(2026, 10, 9, 9), 'Friday two', Mood.calm),
        n(DateTime(2026, 10, 16, 9), 'Friday three', Mood.joy),
        n(DateTime(2026, 10, 5, 9), 'Monday one', Mood.blue),
        n(DateTime(2026, 10, 12, 9), 'Monday two', Mood.blue),
      ];
      final p = Patterns.from(notes, now);
      expect(
        p.weekdays.map(
          (w) => '${w.weekday}:${w.mood.id}:${w.count}/${w.total}',
        ),
        ['5:calm:2/3'],
      );
      expect(p.standouts.single.weekday, DateTime.friday);
    });

    test('counts when you write and the words you reach for', () {
      final notes = [
        n(
          DateTime(2026, 10, 1, 22),
          'Coffee with my mother and #family. Coffee again.',
          Mood.calm,
        ),
        n(
          DateTime(2026, 10, 2, 23),
          'Long walk, coffee, and the sea',
          Mood.joy,
        ),
        n(DateTime(2026, 10, 3, 8), 'قهوة مع أمي، قهوة الصباح', Mood.love),
        n(DateTime(2026, 10, 4, 14), 'قهوة', Mood.plain),
      ];
      final p = Patterns.from(notes, now);
      expect(p.notes, 4);
      expect(p.busiestPart, DayPart.night);
      expect(p.dayParts[DayPart.morning], 1);
      final words = {for (final e in p.topWords) e.key: e.value};
      expect(words['coffee'], 3);
      expect(words['قهوة'], 3);
      // Tags, short and common words are left out.
      expect(words.containsKey('family'), isFalse);
      expect(words.containsKey('the'), isFalse);
      expect(words.containsKey('with'), isFalse);
      expect(p.enough, isFalse);
    });

    test('compares the last 30 days with the 30 before', () {
      final notes = [
        for (var d = 1; d <= 4; d++)
          n(DateTime(2026, 10, d + 10, 9), 'recent $d', Mood.joy),
        for (var d = 1; d <= 4; d++)
          n(DateTime(2026, 9, d + 5, 9), 'older $d', Mood.blue),
      ];
      final p = Patterns.from(notes, now);
      expect(p.lately, Mood.joy);
      expect(p.before, Mood.blue);
      expect(Patterns.from(const [], now).lately, isNull);
    });
  });

  group('free writing', () {
    TextEditingValue v(String text) => TextEditingValue(text: text);
    final formatter = ForwardOnlyFormatter();

    test('only lets text grow at the end', () {
      expect(
        formatter.formatEditUpdate(v('Hello'), v('Hello!')).text,
        'Hello!',
      );
      // Deleting is refused.
      expect(formatter.formatEditUpdate(v('Hello'), v('Hell')).text, 'Hello');
      // Editing the middle is refused.
      expect(formatter.formatEditUpdate(v('Hello'), v('Heyllo')).text, 'Hello');
      // So is pasting a lot at once, but a short autocorrect is fine.
      expect(
        formatter.formatEditUpdate(v('Hi '), v('Hi ${'x' * 40}')).text,
        'Hi ',
      );
      expect(
        formatter.formatEditUpdate(v('Hi '), v('Hi there')).text,
        'Hi there',
      );
    });

    test('counts words in English and Arabic', () {
      expect(wordCount(''), 0);
      expect(wordCount('One, two three!'), 3);
      expect(wordCount('كتبت اليوم عن  يومي'), 4);
      expect(wordCount('route 66 and #tags'), 4);
    });
  });

  group('pdf export', () {
    final now = DateTime(2026, 10, 28, 12);
    Note note(DateTime time, String text, {bool archived = false}) => Note(
      id: '${time.millisecondsSinceEpoch}',
      audience: Audience.private,
      text: text,
      images: const [],
      time: time,
      ownerId: 'me',
      ownerName: 'Me',
      ownerImage: '',
      archived: archived,
    );

    test('picks the notes of the range, oldest first, without archived', () {
      final recent = note(DateTime(2026, 10, 20), 'recent');
      final spring = note(DateTime(2026, 3, 1), 'spring');
      final lastYear = note(DateTime(2025, 12, 31), 'last year');
      final hidden = note(DateTime(2026, 10, 21), 'hidden', archived: true);
      final blank = note(DateTime(2026, 10, 22), '   ');
      final all = [recent, hidden, lastYear, blank, spring];
      expect(notesForExport(all, ExportRange.everything, now), [
        lastYear,
        spring,
        recent,
      ]);
      expect(notesForExport(all, ExportRange.thisYear, now), [spring, recent]);
      expect(notesForExport(all, ExportRange.last30Days, now), [recent]);
    });

    test('leaves emoji out because the PDF font cannot print them', () {
      expect(
        stripEmoji('Great day 😀❤️ with family 👨‍👩‍👧'),
        'Great day with family ',
      );
      expect(stripEmoji('اليوم جميل 🌿'), 'اليوم جميل ');
      expect(stripEmoji('Plain #tag text.'), 'Plain #tag text.');
    });

    test('keeps Arabic vowel marks from crashing the PDF layout', () async {
      await initializeDateFormatting();
      final font = File('assets/fonts/NotoNaskhArabic.ttf').readAsBytesSync();
      // A hamza-alef followed by a damma crashes the PDF library as is.
      expect(pdfText('أُعدّ يومًا جميلًا 😀'), 'أعد يوما جميلا ');
      L10n.arabic = true;
      final bytes = await buildJournalPdf(
        notes: [note(DateTime(2026, 10, 2, 22), 'أُعدّ الطعام، وكتابٌ جميل')],
        authorName: 'مُهدي',
        fontData: font,
        now: now,
      );
      L10n.arabic = false;
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('builds the monthly mood report in English and Arabic', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await initializeDateFormatting();
      final font = File('assets/fonts/NotoNaskhArabic.ttf').readAsBytesSync();
      final month = MonthInsights.from([
        note(DateTime(2026, 10, 2), 'a'),
        note(DateTime(2026, 10, 3), 'b'),
      ], DateTime(2026, 10, 15));
      for (final arabic in [false, true]) {
        L10n.arabic = arabic;
        final bytes = await buildMoodReportPdf(
          month: month,
          authorName: 'Mahdi',
          fontData: font,
          now: now,
        );
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      }
      L10n.arabic = false;
      // A month with nothing in it still produces a page.
      final empty = await buildMoodReportPdf(
        month: MonthInsights.from(const [], DateTime(2026, 10, 15)),
        authorName: 'Mahdi',
        fontData: font,
        now: now,
      );
      expect(String.fromCharCodes(empty.take(5)), '%PDF-');
    });

    test('builds a PDF in English and Arabic from the bundled font', () async {
      await initializeDateFormatting();
      final font = File('assets/fonts/NotoNaskhArabic.ttf').readAsBytesSync();
      final notes = [
        note(DateTime(2026, 9, 3, 9), 'First day back at work #work'),
        note(
          DateTime(2026, 10, 2, 22),
          'اليوم كان يومًا جميلًا مع العائلة #عائلة',
        ),
        note(
          DateTime(2026, 10, 10, 8),
          List.filled(400, 'long note').join(' '),
        ),
      ];
      for (final arabic in [false, true]) {
        L10n.arabic = arabic;
        final bytes = await buildJournalPdf(
          notes: notes,
          authorName: 'Mahdi',
          fontData: font,
          now: now,
        );
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        expect(bytes.length, greaterThan(5000));
      }
      L10n.arabic = false;
      // An empty export still produces a valid cover page.
      final empty = await buildJournalPdf(
        notes: const [],
        authorName: 'Mahdi',
        fontData: font,
        now: now,
      );
      expect(String.fromCharCodes(empty.take(5)), '%PDF-');
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
