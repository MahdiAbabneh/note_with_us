import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../../core/journal_pdf.dart';
import '../../core/l10n.dart';
import '../../core/tags.dart';
import '../../data/session.dart';
import '../../design/design.dart';

/// Asks which notes to include, then builds a PDF of them and opens the
/// share sheet. With [tag] only notes using that `#tag` are included.
Future<void> showExportSheet(BuildContext context, {String? tag}) {
  return showNwuSheet<void>(context, builder: (_) => _ExportSheet(tag: tag));
}

class _ExportSheet extends StatefulWidget {
  const _ExportSheet({this.tag});

  final String? tag;

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  ExportRange _range = ExportRange.everything;
  bool _working = false;

  static const _ranges = [
    (ExportRange.last30Days, 'Last 30 days'),
    (ExportRange.thisYear, 'This year'),
    (ExportRange.everything, 'Everything'),
  ];

  Future<void> _export() async {
    if (_working) return;
    final session = Session.instance;
    final tag = widget.tag;
    // The share sheet on an iPad needs to know where it came from.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    setState(() => _working = true);
    try {
      final now = DateTime.now();
      final all = await session.notes.allMine(session.uid);
      final notes = notesForExport(
        all.where((n) => tag == null || hasTag(n, tag)),
        _range,
        now,
      );
      if (notes.isEmpty) {
        if (mounted) {
          setState(() => _working = false);
          showToast(context, 'No notes to export for this choice.'.tr);
        }
        return;
      }
      final font = await rootBundle.load('assets/fonts/NotoNaskhArabic.ttf');
      final bytes = await buildJournalPdfInBackground(
        notes: notes,
        authorName: session.me.username,
        fontData: font.buffer.asUint8List(),
        now: now,
        tag: tag,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'note-with-us.pdf',
        bounds: origin,
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _working = false);
        showToast(context, 'Couldn’t create the PDF'.tr, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.md,
        Space.gutter,
        Space.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Export as PDF'.tr, style: context.text.title),
          const SizedBox(height: Space.xs),
          Text(
            widget.tag == null
                ? 'A book of everything you wrote, with the date and mood. It includes private, circle and public notes.'
                      .tr
                : 'Only notes tagged #{tag}.'.tr.replaceAll(
                    '{tag}',
                    widget.tag!,
                  ),
            style: context.text.small,
          ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final (range, label) in _ranges)
                Pressable(
                  onTap: () => setState(() => _range = range),
                  child: AnimatedContainer(
                    duration: Motion.base,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: _range == range ? c.accentSoft : c.surface,
                      borderRadius: BorderRadius.circular(Radii.pill),
                      border: Border.all(
                        color: _range == range ? c.accent : c.line,
                      ),
                    ),
                    child: Text(
                      label.tr,
                      style: context.text.label.copyWith(
                        color: _range == range ? c.accent : c.ink,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(
            'Emoji can’t be printed in the PDF, so they are left out.'.tr,
            style: context.text.caption,
          ),
          const SizedBox(height: Space.lg),
          NwuButton(
            label: 'Create PDF'.tr,
            icon: CupertinoIcons.doc_text,
            tone: ButtonTone.accent,
            loading: _working,
            onPressed: _export,
          ),
        ],
      ),
    );
  }
}
