import 'package:flutter_test/flutter_test.dart';
import 'package:mahdeko/core/l10n.dart';
import 'package:mahdeko/data/official.dart';
import 'package:mahdeko/data/sample_notes.dart';

void main() {
  tearDown(() => L10n.arabic = false);

  test('example notes are marked, public and in the app language', () {
    L10n.arabic = false;
    final en = sampleNotes();
    expect(en, isNotEmpty);
    expect(en.every((n) => n.example), isTrue);
    expect(en.every((n) => n.ownerId.startsWith('example:')), isTrue);
    // Nothing a real person could have reacted to or replied on.
    expect(en.every((n) => n.reactions.isEmpty && n.commentCount == 0), isTrue);
    expect(en.first.ownerName, 'Omar');

    L10n.arabic = true;
    final ar = sampleNotes();
    expect(ar.first.ownerName, 'عمر');
    expect(ar.first.text, isNot(en.first.text));
  });

  test('no one is official unless listed in the app', () {
    expect(isOfficial('someone'), isFalse);
    expect(isOfficial(''), isFalse);
  });
}
