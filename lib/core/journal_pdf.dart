import 'dart:typed_data';

import 'package:intl/intl.dart' show Bidi;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models.dart';
import '../design/tokens.dart';
import 'format.dart';
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
    final clean = stripEmoji(text).trim();
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
              tag == null ? 'My notes'.tr : '#$tag',
              style: style(40),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 14),
            pw.Text(authorName, style: style(16, color: soft)),
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
