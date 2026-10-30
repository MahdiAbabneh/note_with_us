import '../data/models.dart';
import 'l10n.dart';
import 'prefs.dart';

/// `#family`, `#عائلة`: a hash followed by letters, digits or underscores
/// (at least one letter), not glued to a word before it.
final _tagPattern = RegExp(
  r'(?<![\p{L}\p{N}\p{M}_#])#((?=[\p{N}\p{M}_]*\p{L})[\p{L}\p{N}\p{M}_]{1,30})',
  unicode: true,
);

/// A piece of a note: plain text, or a tag (with its leading `#`).
class TextPart {
  const TextPart(this.text, {this.tag});

  final String text;

  /// The tag without `#`, lower-cased; null for plain text.
  final String? tag;

  bool get isTag => tag != null;
}

/// Splits [text] into plain and tag parts, keeping every character.
List<TextPart> splitTags(String text) {
  final parts = <TextPart>[];
  var last = 0;
  for (final match in _tagPattern.allMatches(text)) {
    if (match.start > last) {
      parts.add(TextPart(text.substring(last, match.start)));
    }
    parts.add(TextPart(match.group(0)!, tag: match.group(1)!.toLowerCase()));
    last = match.end;
  }
  if (last < text.length) parts.add(TextPart(text.substring(last)));
  return parts;
}

/// The tags in [text], lower-cased, once each, in order of appearance.
List<String> extractTags(String text) => [
  ...{
    for (final match in _tagPattern.allMatches(text))
      match.group(1)!.toLowerCase(),
  },
];

/// How many of [notes] use each tag, most used first (ties alphabetical).
List<MapEntry<String, int>> tagCounts(Iterable<Note> notes) {
  final counts = <String, int>{};
  for (final note in notes) {
    for (final tag in extractTags(note.text)) {
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }
  return counts.entries.toList()..sort((a, b) {
    final byCount = b.value.compareTo(a.value);
    return byCount != 0 ? byCount : a.key.compareTo(b.key);
  });
}

/// Whether [note] uses [tag] (given without `#`, any case).
bool hasTag(Note note, String tag) =>
    extractTags(note.text).contains(tag.toLowerCase());

/// Tags the writer used lately, kept on this device so the composer can
/// offer them again with one tap.
abstract final class RecentTags {
  static const _key = 'recentTags';
  static const _max = 8;

  static List<String> get all => (Prefs.getString(_key) ?? '')
      .split(',')
      .where((t) => t.isNotEmpty)
      .toList();

  /// Remembers the tags in [text], newest first.
  static void record(String text) {
    final used = extractTags(text);
    if (used.isEmpty) return;
    final merged = [...used, ...all.where((t) => !used.contains(t))].take(_max);
    Prefs.setString(_key, merged.join(','));
  }
}

/// A few starter tags for someone with no history yet.
List<String> starterTags() => L10n.arabic
    ? const ['عائلة', 'عمل', 'امتنان', 'أهداف', 'صحة', 'أصدقاء']
    : const ['family', 'work', 'gratitude', 'goals', 'health', 'friends'];

/// What the composer offers: recent tags first, then starters, none that
/// [text] already has.
List<String> tagSuggestions(String text) {
  final used = extractTags(text);
  return [
    ...RecentTags.all,
    ...starterTags().where((t) => !RecentTags.all.contains(t)),
  ].where((t) => !used.contains(t)).take(8).toList();
}
