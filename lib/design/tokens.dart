import 'package:flutter/material.dart';

/// Spacing scale used for every gap and padding in the app.
abstract final class Space {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Horizontal page gutter.
  static const double gutter = 20;
}

/// Corner radius scale.
abstract final class Radii {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double pill = 999;
}

/// Motion durations and curves, kept short so the UI feels responsive.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration base = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);
  static const Curve ease = Curves.easeOutCubic;
  static const Curve pop = Curves.easeOutBack;
}

/// Accent families the user can pick; the ids match the `theme` field
/// already stored on user documents.
enum Accent {
  coral('origin', 'Coral', Color(0xFFF2513F), Color(0xFFFF7566)),
  tangerine('orange', 'Tangerine', Color(0xFFF26B1D), Color(0xFFFF9150)),
  indigo('blue', 'Indigo', Color(0xFF4A56D8), Color(0xFF8C96FF)),
  rose('pink', 'Rose', Color(0xFFDB3F78), Color(0xFFFF6FA0));

  const Accent(this.id, this.label, this.light, this.dark);

  final String id;
  final String label;
  final Color light;
  final Color dark;

  static Accent fromId(String? id) =>
      values.firstWhere((a) => a.id == id, orElse: () => coral);
}

/// The app's background family.
enum Backdrop {
  /// Warm white, like good paper but not beige; soft charcoal at night.
  /// The default.
  linen('linen', 'Linen'),

  /// Cool, clean whites; blue-black at night.
  cloud('cloud', 'Cloud'),

  /// Soft green-whites with forest-green ink; deep green at night.
  mint('mint', 'Mint');

  const Backdrop(this.id, this.label);

  final String id;
  final String label;

  static Backdrop fromId(String? id) =>
      values.firstWhere((b) => b.id == id, orElse: () => linen);
}

/// The typeface notes are written and read in.
enum NoteFont {
  /// The app's own serif (Latin) and sans (Arabic). The default.
  classic('classic', 'Classic'),

  /// A bookish serif.
  book('book', 'Book'),

  /// A clean, modern sans.
  clean('clean', 'Clean'),

  /// A handwritten look.
  handwritten('handwritten', 'Handwritten');

  const NoteFont(this.id, this.label);

  final String id;
  final String label;

  static NoteFont fromId(String? id) =>
      values.firstWhere((f) => f.id == id, orElse: () => classic);
}

/// What a note's text sits on.
enum NotePaper {
  plain('plain', 'Plain'),

  /// Lines to write on.
  ruled('ruled', 'Ruled'),

  /// Squares.
  grid('grid', 'Grid'),

  /// A grid of dots.
  dots('dots', 'Dots'),

  /// A warm, aged tint.
  warm('warm', 'Warm');

  const NotePaper(this.id, this.label);

  final String id;
  final String label;

  static NotePaper fromId(String? id) =>
      values.firstWhere((p) => p.id == id, orElse: () => plain);
}

/// The chosen [NotePaper] as a theme extension, so changing it rebuilds
/// every note.
@immutable
class NwuPaper extends ThemeExtension<NwuPaper> {
  const NwuPaper(this.paper);

  final NotePaper paper;

  /// [base] (a note's colour), warmed for the warm paper.
  Color tint(Color base, {required bool dark}) => paper == NotePaper.warm
      ? Color.lerp(
          base,
          dark ? const Color(0xFF4A3B26) : const Color(0xFFF0DDB8),
          0.45,
        )!
      : base;

  @override
  NwuPaper copyWith({NotePaper? paper}) => NwuPaper(paper ?? this.paper);

  @override
  NwuPaper lerp(ThemeExtension<NwuPaper>? other, double t) =>
      other is NwuPaper && t > 0.5 ? other : this;

  @override
  bool operator ==(Object other) => other is NwuPaper && other.paper == paper;

  @override
  int get hashCode => paper.hashCode;
}

/// Note moods. Each one tints the note card so a feed reads like a
/// wall of soft colour rather than a list of identical boxes.
enum Mood {
  plain('plain', '📝', 'Plain'),
  calm('calm', '🌿', 'Calm'),
  joy('joy', '☀️', 'Happy'),
  love('love', '💗', 'Loved'),
  dreamy('dreamy', '🌙', 'Dreamy'),
  blue('blue', '🌧️', 'Blue'),
  fired('fired', '🔥', 'Fired up');

  const Mood(this.id, this.emoji, this.label);

  final String id;
  final String emoji;
  final String label;

  static Mood fromId(String? id) =>
      values.firstWhere((m) => m.id == id, orElse: () => plain);

  /// Mood whose tint colours a note's paper. Plain notes pick a stable
  /// tint from [seed] so the feed stays colourful.
  static Mood forPaper(Mood mood, String seed) {
    if (mood != plain) return mood;
    const palette = [calm, joy, love, dreamy, blue, fired];
    final hash = seed.codeUnits.fold(0, (h, u) => (h * 31 + u) & 0x7fffffff);
    return palette[hash % palette.length];
  }
}

/// Semantic colour tokens exposed through the theme.
@immutable
class NwuColors extends ThemeExtension<NwuColors> {
  const NwuColors({
    required this.canvas,
    required this.surface,
    required this.raised,
    required this.ink,
    required this.inkSoft,
    required this.muted,
    required this.line,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.danger,
    required this.success,
    required this.isDark,
  });

  final Color canvas;
  final Color surface;
  final Color raised;
  final Color ink;
  final Color inkSoft;
  final Color muted;
  final Color line;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color danger;
  final Color success;
  final bool isDark;

  /// Builds the palette for a brightness and accent.
  factory NwuColors.of(
    Brightness brightness,
    Accent accent, [
    Backdrop backdrop = Backdrop.linen,
  ]) {
    final dark = brightness == Brightness.dark;
    final accentColor = dark ? accent.dark : accent.light;
    // Neutrals per backdrop: [canvas, surface, raised, ink, inkSoft,
    // muted, line]. Cloud is cool white / blue-black; Mint is green-white
    // / deep forest.
    final n = switch ((backdrop, dark)) {
      (Backdrop.linen, false) => const [
        0xFFF8F6F2,
        0xFFFCFBF8,
        0xFFFFFFFF,
        0xFF1A1815,
        0xFF4A4640,
        0xFF8C877F,
        0xFFECE8E1,
      ],
      (Backdrop.linen, true) => const [
        0xFF131211,
        0xFF1A1918,
        0xFF22211F,
        0xFFF3F1EC,
        0xFFC9C5BD,
        0xFF8D8880,
        0xFF2D2B28,
      ],
      (Backdrop.cloud, false) => const [
        0xFFF5F6FA,
        0xFFFBFCFE,
        0xFFFFFFFF,
        0xFF14161B,
        0xFF474C59,
        0xFF8A90A0,
        0xFFE4E7EF,
      ],
      (Backdrop.cloud, true) => const [
        0xFF0D0F14,
        0xFF151821,
        0xFF1C202B,
        0xFFF2F4F8,
        0xFFC3C8D4,
        0xFF8088A0,
        0xFF2A2F3C,
      ],
      (Backdrop.mint, false) => const [
        0xFFEFF6F2,
        0xFFF7FBF9,
        0xFFFFFFFF,
        0xFF0F2A24,
        0xFF3D5A52,
        0xFF6F8A81,
        0xFFD8E6E0,
      ],
      (Backdrop.mint, true) => const [
        0xFF0A1412,
        0xFF101D1A,
        0xFF162622,
        0xFFEAF4F0,
        0xFFB7CCC4,
        0xFF7B948B,
        0xFF233631,
      ],
    }.map(Color.new).toList();
    return NwuColors(
      canvas: n[0],
      surface: n[1],
      raised: n[2],
      ink: n[3],
      inkSoft: n[4],
      muted: n[5],
      line: n[6],
      accent: accentColor,
      onAccent: Colors.white,
      accentSoft: Color.alphaBlend(
        accentColor.withValues(alpha: dark ? 0.18 : 0.12),
        n[1],
      ),
      danger: dark ? const Color(0xFFFF6B5E) : const Color(0xFFC8372D),
      success: dark ? const Color(0xFF6FCF97) : const Color(0xFF2E8B57),
      isDark: dark,
    );
  }

  /// Card background for a mood.
  Color moodTint(Mood mood) => switch (mood) {
    Mood.plain => raised,
    Mood.calm => isDark ? const Color(0xFF15302A) : const Color(0xFFDDF4EA),
    Mood.joy => isDark ? const Color(0xFF353019) : const Color(0xFFFFF2C9),
    Mood.love => isDark ? const Color(0xFF3A1E28) : const Color(0xFFFFE2E6),
    Mood.dreamy => isDark ? const Color(0xFF262347) : const Color(0xFFEDE7FF),
    Mood.blue => isDark ? const Color(0xFF172745) : const Color(0xFFE2EDFF),
    Mood.fired => isDark ? const Color(0xFF3A2419) : const Color(0xFFFFE6D8),
  };

  /// Paper colour for a note: its mood's tint, or, for a note without a
  /// mood, one of the same soft tints picked from [seed] so the feed stays
  /// colourful and a note always keeps its colour.
  Color paperTint(Mood mood, String seed) =>
      moodTint(Mood.forPaper(mood, seed));

  /// Saturated mood colour used for dots and selected states.
  Color moodInk(Mood mood) => switch (mood) {
    Mood.plain => muted,
    Mood.calm => const Color(0xFF239B73),
    Mood.joy => const Color(0xFFD29A06),
    Mood.love => const Color(0xFFE3456B),
    Mood.dreamy => const Color(0xFF7A5FE3),
    Mood.blue => const Color(0xFF3B7BE6),
    Mood.fired => const Color(0xFFF06A28),
  };

  @override
  NwuColors copyWith() => this;

  @override
  NwuColors lerp(ThemeExtension<NwuColors>? other, double t) {
    if (other is! NwuColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return NwuColors(
      canvas: mix(canvas, other.canvas),
      surface: mix(surface, other.surface),
      raised: mix(raised, other.raised),
      ink: mix(ink, other.ink),
      inkSoft: mix(inkSoft, other.inkSoft),
      muted: mix(muted, other.muted),
      line: mix(line, other.line),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      accentSoft: mix(accentSoft, other.accentSoft),
      danger: mix(danger, other.danger),
      success: mix(success, other.success),
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

/// Soft layered shadow used on floating surfaces.
List<BoxShadow> softShadow(NwuColors c, {double strength = 1}) => [
  BoxShadow(
    color: Colors.black.withValues(alpha: (c.isDark ? 0.35 : 0.06) * strength),
    blurRadius: 24,
    offset: const Offset(0, 10),
  ),
  BoxShadow(
    color: Colors.black.withValues(alpha: (c.isDark ? 0.25 : 0.04) * strength),
    blurRadius: 4,
    offset: const Offset(0, 1),
  ),
];

/// Convenience accessors.
extension NwuContext on BuildContext {
  NwuColors get colors => Theme.of(this).extension<NwuColors>()!;
  NwuText get text => Theme.of(this).extension<NwuText>()!;
  NwuPaper get paper =>
      Theme.of(this).extension<NwuPaper>() ?? const NwuPaper(NotePaper.plain);
}

/// Typography tokens. Display styles use a serif to give notes a
/// handwritten-journal warmth; UI chrome uses a clean grotesque.
@immutable
class NwuText extends ThemeExtension<NwuText> {
  const NwuText({
    required this.hero,
    required this.display,
    required this.title,
    required this.headline,
    required this.noteBody,
    required this.body,
    required this.bodyStrong,
    required this.small,
    required this.label,
    required this.overline,
    required this.caption,
  });

  final TextStyle hero;
  final TextStyle display;
  final TextStyle title;
  final TextStyle headline;
  final TextStyle noteBody;
  final TextStyle body;
  final TextStyle bodyStrong;
  final TextStyle small;
  final TextStyle label;
  final TextStyle overline;
  final TextStyle caption;

  @override
  NwuText copyWith() => this;

  @override
  NwuText lerp(ThemeExtension<NwuText>? other, double t) =>
      other is NwuText && t > 0.5 ? other : this;
}
