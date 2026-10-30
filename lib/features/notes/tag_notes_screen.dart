import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/l10n.dart';
import '../../core/tags.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import 'note_card.dart';

/// Everything you wrote with a given `#tag`: private, circle and public.
class TagNotesScreen extends StatefulWidget {
  const TagNotesScreen({super.key, required this.tag});

  /// The tag without its `#`.
  final String tag;

  @override
  State<TagNotesScreen> createState() => _TagNotesScreenState();
}

class _TagNotesScreenState extends State<TagNotesScreen> {
  final _session = Session.instance;
  late Stream<List<Note>> _notes = _session.notes.mine(_session.uid);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(title: '#${widget.tag}'),
      body: StreamBuilder<List<Note>>(
        stream: _notes,
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorState(
              onRetry: () =>
                  setState(() => _notes = _session.notes.mine(_session.uid)),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CupertinoActivityIndicator());
          }
          final notes = snap.data!
              .where((n) => !n.archived && hasTag(n, widget.tag))
              .toList();
          if (notes.isEmpty) {
            return EmptyState(
              emoji: '🏷️',
              title: 'No notes with this tag'.tr,
              message: 'Add #{tag} to a note and it shows up here.'.tr
                  .replaceAll('{tag}', widget.tag),
            );
          }
          return ListView(
            padding: EdgeInsets.fromLTRB(
              Space.gutter,
              Space.sm,
              Space.gutter,
              MediaQuery.of(context).padding.bottom + Space.xxl,
            ),
            children: [
              Text(
                (notes.length == 1 ? '1 note' : '{n} notes').tr.replaceAll(
                  '{n}',
                  '${notes.length}',
                ),
                style: context.text.caption,
              ),
              const SizedBox(height: Space.sm),
              for (final (i, note) in notes.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: NoteCard(note: note)
                      .animate(delay: (i.clamp(0, 6) * 40).ms)
                      .fadeIn()
                      .slideY(begin: 0.05),
                ),
            ],
          );
        },
      ),
    );
  }
}
