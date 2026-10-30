import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' show Brightness;

import 'package:intl/date_symbol_data_local.dart' show initializeDateFormatting;
import 'package:intl/intl.dart' show Bidi, DateFormat;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models.dart';
import '../design/tokens.dart';
import 'format.dart';
import 'hijri.dart';
import 'insights.dart';
import 'l10n.dart';

/// Which notes go into an exported journal.
enum ExportRange { last30Days, thisYear, everything }

/// The notes of [range], oldest first; archived notes stay out.
List<Note> notesForExport(
  Iterable<Note> notes,
  ExportRange range,
  DateTime now,
) {
  final start = switch (range) {
    ExportRange.last30Days => DateTime(now.year, now.month, now.day - 29),
    ExportRange.thisYear => DateTime(now.year),
    ExportRange.everything => null,
  };
  return notes
      .where((n) => !n.archived && n.text.trim().isNotEmpty)
      .where((n) => start == null || !n.time.isBefore(start))
      .toList()
    ..sort((a, b) => a.time.compareTo(b.time));
}

/// The PDF font has no colour emoji, so they are left out rather than
/// printed as empty boxes.
String stripEmoji(String text) => text
    .replaceAll(
      RegExp(
        r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2300}-\u{23FF}'
        r'\u{2B00}-\u{2BFF}\u{FE0F}\u{200D}\u{20E3}]',
        unicode: true,
      ),
      '',
    )
    .replaceAll(RegExp(r'[ \t]{2,}'), ' ');

/// Text made safe for the PDF: emoji are dropped (the font has none) and
/// Arabic vowel marks are removed, because the PDF library's text layout
/// crashes on some of them (for example a hamza-alef followed by a damma).
/// Arabic is normally written without them, so little is lost.
String pdfText(String text) =>
    stripEmoji(text).replaceAll(RegExp('[\u064B-\u065F\u0670]'), '');

/// [buildJournalPdf] on a background isolate, so laying out thousands of
/// notes does not freeze the app. The isolate starts with no language or
/// date data, so both are set up first.
Future<Uint8List> buildJournalPdfInBackground({
  required List<Note> notes,
  required String authorName,
  required Uint8List fontData,
  required DateTime now,
  String? tag,
}) {
  final arabic = L10n.arabic;
  return Isolate.run(() async {
    L10n.arabic = arabic;
    await initializeDateFormatting();
    return buildJournalPdf(
      notes: notes,
      authorName: authorName,
      fontData: fontData,
      now: now,
      tag: tag,
    );
  });
}

/// A keepsake PDF of [notes] (oldest first): a cover, then the notes
/// grouped by month. [fontData] is a TrueType font with Latin and Arabic
/// glyphs; Arabic is shaped and laid out right to left per note.
Future<Uint8List> buildJournalPdf({
  required List<Note> notes,
  required String authorName,
  required Uint8List fontData,
  required DateTime now,
  String? tag,
}) async {
  final font = pw.Font.ttf(ByteData.sublistView(fontData));
  final arabic = L10n.arabic;
  const ink = PdfColor.fromInt(0xFF1F1B16);
  const soft = PdfColor.fromInt(0xFF6F675D);
  const accent = PdfColor.fromInt(0xFFF2513F);
  const line = PdfColor.fromInt(0xFFE3DDD3);

  pw.TextStyle style(
    double size, {
    PdfColor color = ink,
    double height = 1.45,
  }) => pw.TextStyle(font: font, fontSize: size, color: color, height: height);

  pw.TextDirection directionOf(String text) =>
      Bidi.detectRtlDirectionality(text)
      ? pw.TextDirection.rtl
      : pw.TextDirection.ltr;

  pw.Widget body(String text) {
    final clean = pdfText(text).trim();
    final dir = directionOf(clean);
    final rtl = dir == pw.TextDirection.rtl;
    final paragraph = pw.Text(
      clean,
      textDirection: dir,
      textAlign: rtl ? pw.TextAlign.right : pw.TextAlign.left,
      style: style(12),
      // Lets a very long note continue on the next page.
      overflow: pw.TextOverflow.span,
    );
    // A short note is only as wide as its text, so it is pushed to its
    // own edge (right for Arabic); long notes already fill the width.
    return clean.length > 1200
        ? paragraph
        : pw.Align(
            alignment: rtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
            child: paragraph,
          );
  }

  final uiDirection = arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;
  final align = arabic
      ? pw.CrossAxisAlignment.end
      : pw.CrossAxisAlignment.start;
  final doc = pw.Document(title: 'My notes'.tr, author: authorName);

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      textDirection: uiDirection,
      margin: const pw.EdgeInsets.all(56),
      build: (context) => pw.Center(
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text('Note With Us', style: style(12, color: accent)),
            pw.SizedBox(height: 24),
            pw.Text(
              tag == null ? 'My notes'.tr : '#${pdfText(tag)}',
              style: style(40),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 14),
            pw.Text(pdfText(authorName), style: style(16, color: soft)),
            pw.SizedBox(height: 28),
            pw.Container(width: 60, height: 2, color: accent),
            pw.SizedBox(height: 28),
            if (notes.isNotEmpty)
              pw.Text(
                '${fullDate(notes.first.time)}  —  ${fullDate(notes.last.time)}',
                style: style(12, color: soft),
              ),
            pw.SizedBox(height: 6),
            pw.Text(
              (notes.length == 1 ? '1 note' : '{n} notes').tr.replaceAll(
                '{n}',
                '${notes.length}',
              ),
              style: style(12, color: soft),
            ),
          ],
        ),
      ),
    ),
  );

  if (notes.isNotEmpty) {
    String? month;
    final children = <pw.Widget>[];
    for (final note in notes) {
      final label = monthYear(note.time);
      if (label != month) {
        month = label;
        children.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 18, bottom: 10),
            child: pw.Column(
              crossAxisAlignment: align,
              children: [
                pw.Text(label, style: style(20, color: accent)),
                pw.SizedBox(height: 4),
                pw.Container(height: 1, color: line),
              ],
            ),
          ),
        );
      }
      final mood = note.mood == Mood.plain ? '' : '  ·  ${note.mood.label.tr}';
      children
        ..add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6, bottom: 3),
            child: pw.Text(
              '${fullDate(note.time)}  ·  ${clockTime(note.time)}$mood',
              style: style(9.5, color: soft),
            ),
          ),
        )
        ..add(body(note.text))
        ..add(pw.SizedBox(height: 12));
    }
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: uiDirection,
        margin: const pw.EdgeInsets.fromLTRB(56, 48, 56, 48),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text(
            '${context.pageNumber - 1} / ${context.pagesCount - 1}',
            style: style(9, color: soft),
          ),
        ),
        build: (context) => children,
      ),
    );
  }
  return doc.save();
}

PdfColor _pdfColor(int argb) => PdfColor.fromInt(argb);

/// A one-page mood report for a month of notes: how many days and notes,
/// the moods as bars, and a day-by-day calendar coloured by mood. It is
/// made to be shown to someone you trust, such as a doctor or a therapist,
/// so it holds no note text.
Future<Uint8List> buildMoodReportPdf({
  required MonthInsights month,
  required String authorName,
  required Uint8List fontData,
  required DateTime now,
  bool hijri = false,
}) async {
  final font = pw.Font.ttf(ByteData.sublistView(fontData));
  final arabic = L10n.arabic;
  final colors = NwuColors.of(Brightness.light, Accent.coral);
  PdfColor ink(Mood m) => _pdfColor(colors.moodInk(m).toARGB32());
  PdfColor tint(Mood m) => _pdfColor(colors.moodTint(m).toARGB32());
  const text = PdfColor.fromInt(0xFF1F1B16);
  const soft = PdfColor.fromInt(0xFF6F675D);
  const accent = PdfColor.fromInt(0xFFF2513F);
  const line = PdfColor.fromInt(0xFFE3DDD3);

  pw.TextStyle style(double size, {PdfColor color = text}) =>
      pw.TextStyle(font: font, fontSize: size, color: color, height: 1.35);

  final direction = arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr;
  final first = month.month;
  final daysInMonth = DateTime(first.year, first.month + 1, 0).day;
  final moods = month.moods.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final plain = month.notes - month.moods.values.fold(0, (a, b) => a + b);
  final top = month.topMood;
  final streak = longestStreak(month.byDay.keys);

  pw.Widget stat(String value, String label) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(12),
      margin: const pw.EdgeInsets.symmetric(horizontal: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: line),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(value, style: style(20)),
          pw.SizedBox(height: 2),
          pw.Text(label, style: style(9, color: soft)),
        ],
      ),
    ),
  );

  pw.Widget bar(Mood mood, int count, int max) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      children: [
        pw.SizedBox(width: 90, child: pw.Text(mood.label.tr, style: style(11))),
        pw.Container(
          width: 260 * count / max,
          height: 12,
          decoration: pw.BoxDecoration(
            color: ink(mood),
            borderRadius: pw.BorderRadius.circular(6),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text('$count', style: style(11, color: soft)),
      ],
    ),
  );

  // Calendar: weeks start on Sunday, or Saturday in Arabic.
  final weekStart = arabic ? 6 : 0;
  final leading = (first.weekday % 7 - weekStart + 7) % 7;
  final cells = <pw.Widget>[
    for (var i = 0; i < leading; i++) pw.SizedBox(width: 56, height: 40),
    for (var d = 1; d <= daysInMonth; d++)
      () {
        final day = DateTime(first.year, first.month, d);
        final mood = month.moodOf(day);
        final hijriDay = hijri
            ? formatHijri(day, withYear: false).split(' ').first
            : null;
        return pw.Container(
          width: 56,
          height: 40,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: mood == null ? null : tint(mood),
            border: pw.Border.all(color: line, width: 0.5),
          ),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text('$d', style: style(11)),
              if (mood != null && mood != Mood.plain)
                pw.Text(mood.label.tr, style: style(7, color: soft))
              else if (hijriDay != null)
                pw.Text(hijriDay, style: style(7, color: soft)),
            ],
          ),
        );
      }(),
  ];

  final weekdayNames = [
    for (var i = 0; i < 7; i++)
      DateFormat.E(
        arabic ? 'ar' : 'en',
      ).format(DateTime(2000, 1, 2 + (weekStart + i) % 7)),
  ];

  final doc = pw.Document(title: 'Mood report'.tr, author: authorName);
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      textDirection: direction,
      margin: const pw.EdgeInsets.all(44),
      build: (context) => pw.Column(
        crossAxisAlignment: arabic
            ? pw.CrossAxisAlignment.end
            : pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Note With Us', style: style(10, color: accent)),
          pw.SizedBox(height: 6),
          pw.Text('Mood report'.tr, style: style(28)),
          pw.SizedBox(height: 4),
          pw.Text(monthYear(first), style: style(16, color: soft)),
          if (hijri)
            pw.Text(
              hijriRangeOf(
                first,
                DateTime(first.year, first.month, daysInMonth),
              ),
              style: style(10, color: soft),
            ),
          pw.Text(pdfText(authorName), style: style(11, color: soft)),
          pw.SizedBox(height: 18),
          pw.Row(
            children: [
              stat('${month.daysWritten}/$daysInMonth', 'Days written'.tr),
              stat('${month.notes}', 'Notes'.tr),
              stat(top == null ? '—' : top.label.tr, 'Most felt'.tr),
              stat('$streak', 'Longest streak'.tr),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('MOODS'.tr, style: style(9, color: soft)),
          pw.SizedBox(height: 6),
          if (moods.isEmpty)
            pw.Text(
              'No moods were chosen this month.'.tr,
              style: style(11, color: soft),
            )
          else ...[
            for (final e in moods) bar(e.key, e.value, moods.first.value),
            if (plain > 0)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text(
                  '{n} notes without a mood'.tr.replaceAll('{n}', '$plain'),
                  style: style(9, color: soft),
                ),
              ),
          ],
          pw.SizedBox(height: 20),
          pw.Text('DAY BY DAY'.tr, style: style(9, color: soft)),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              for (final name in weekdayNames)
                pw.SizedBox(
                  width: 56,
                  child: pw.Center(
                    child: pw.Text(name, style: style(9, color: soft)),
                  ),
                ),
            ],
          ),
          // Seven cells to a row; the page direction decides which side the
          // week starts on.
          for (var i = 0; i < cells.length; i += 7)
            pw.Row(
              children: [
                ...cells.skip(i).take(7),
                for (var k = cells.length - i; k < 7; k++)
                  pw.SizedBox(width: 56, height: 40),
              ],
            ),
          pw.Spacer(),
          pw.Text(
            'Made from the writer’s own notes and chosen moods. It is a personal record, not a medical assessment.'
                .tr,
            style: style(8, color: soft),
          ),
          pw.Text(
            '${'Created on'.tr} ${fullDate(now)}',
            style: style(8, color: soft),
          ),
        ],
      ),
    ),
  );
  return doc.save();
}
