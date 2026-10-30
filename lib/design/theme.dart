import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Builds the app theme for a brightness, accent and language.
ThemeData buildTheme({
  required Brightness brightness,
  required Accent accent,
  required bool arabic,
  Backdrop backdrop = Backdrop.linen,
  NoteFont noteFont = NoteFont.classic,
  NotePaper notePaper = NotePaper.plain,
}) {
  final c = NwuColors.of(brightness, accent, backdrop);
  final text = _buildText(c, arabic, noteFont);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: c.accent,
        brightness: brightness,
      ).copyWith(
        primary: c.accent,
        onPrimary: c.onAccent,
        surface: c.surface,
        onSurface: c.ink,
        error: c.danger,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.canvas,
    canvasColor: c.canvas,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textTheme: TextTheme(
      bodyMedium: text.body,
      bodyLarge: text.body,
      titleMedium: text.bodyStrong,
      labelLarge: text.label,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.accent,
      selectionColor: c.accent.withValues(alpha: 0.25),
      selectionHandleColor: c.accent,
    ),
    cupertinoOverrideTheme: CupertinoThemeData(primaryColor: c.accent),
    dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      modalBackgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      },
    ),
    extensions: [c, text, NwuPaper(notePaper)],
  );
}

/// The text style of a note body in [font] for the language.
TextStyle noteBodyStyle(
  NoteFont font, {
  required bool arabic,
  required Color color,
}) {
  return switch ((font, arabic)) {
    (NoteFont.classic, true) => GoogleFonts.ibmPlexSansArabic(
      fontSize: 17,
      height: 1.7,
      color: color,
    ),
    (NoteFont.classic, false) => GoogleFonts.fraunces(
      fontSize: 18,
      height: 1.45,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.1,
      color: color,
    ),
    (NoteFont.book, true) => GoogleFonts.amiri(
      fontSize: 20,
      height: 1.8,
      color: color,
    ),
    (NoteFont.book, false) => GoogleFonts.lora(
      fontSize: 17,
      height: 1.55,
      color: color,
    ),
    (NoteFont.clean, true) => GoogleFonts.tajawal(
      fontSize: 17,
      height: 1.7,
      color: color,
    ),
    (NoteFont.clean, false) => GoogleFonts.dmSans(
      fontSize: 16.5,
      height: 1.5,
      color: color,
    ),
    (NoteFont.handwritten, true) => GoogleFonts.arefRuqaa(
      fontSize: 18,
      height: 1.8,
      color: color,
    ),
    (NoteFont.handwritten, false) => GoogleFonts.caveat(
      fontSize: 22,
      height: 1.35,
      color: color,
    ),
  };
}

NwuText _buildText(NwuColors c, bool arabic, NoteFont noteFont) {
  TextStyle display(double size, FontWeight weight, double spacing) => arabic
      ? GoogleFonts.notoNaskhArabic(
          fontSize: size * 0.92,
          fontWeight: FontWeight.w700,
          height: 1.35,
          color: c.ink,
        )
      : GoogleFonts.fraunces(
          fontSize: size,
          fontWeight: weight,
          height: 1.08,
          letterSpacing: spacing,
          color: c.ink,
        );

  TextStyle ui(
    double size,
    FontWeight weight, {
    double height = 1.45,
    double spacing = 0,
    Color? color,
  }) => arabic
      ? GoogleFonts.ibmPlexSansArabic(
          fontSize: size,
          fontWeight: weight,
          height: height + 0.1,
          color: color ?? c.ink,
        )
      : GoogleFonts.instrumentSans(
          fontSize: size,
          fontWeight: weight,
          height: height,
          letterSpacing: spacing,
          color: color ?? c.ink,
        );

  return NwuText(
    hero: display(42, FontWeight.w600, -1.4),
    display: display(32, FontWeight.w600, -0.9),
    title: display(24, FontWeight.w600, -0.5),
    headline: ui(18, FontWeight.w600, height: 1.3, spacing: -0.2),
    noteBody: noteBodyStyle(noteFont, arabic: arabic, color: c.ink),
    body: ui(16, FontWeight.w400),
    bodyStrong: ui(16, FontWeight.w600),
    small: ui(14, FontWeight.w400, color: c.inkSoft),
    label: ui(14, FontWeight.w600, height: 1.2, spacing: 0.1),
    overline: ui(
      12,
      FontWeight.w700,
      height: 1.2,
      spacing: arabic ? 0 : 1.4,
      color: c.muted,
    ),
    caption: ui(12.5, FontWeight.w500, height: 1.3, color: c.muted),
  );
}
