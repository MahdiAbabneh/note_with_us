import 'dart:math';

import 'package:flutter/cupertino.dart';

import '../../core/format.dart';
import '../../core/insights.dart';
import '../../core/l10n.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';

/// When someone picks the Blue mood, offers something kind to read: a note
/// they kept for hard days, a morning note a friend sent, or an older
/// happy note. Shows nothing if there is nothing to offer, and never
/// blocks: it just returns when the sheet closes.
Future<void> showComfortSheet(BuildContext context) async {
  final session = Session.instance;
  final random = Random();
  late final List<Note> journal;
  late final List<Capsule> capsules;
  try {
    final results = await Future.wait([
      session.notes.journal(session.uid, limit: 200).first,
      session.capsules.received(session.uid).first,
    ]).timeout(const Duration(seconds: 3));
    journal = results[0] as List<Note>;
    capsules = results[1] as List<Capsule>;
  } catch (_) {
    return;
  }
  final now = DateTime.now();
  final first = pickComfort(journal, capsules, session.uid, now, random);
  if (first == null || !context.mounted) return;
  await showNwuSheet<void>(
    context,
    builder: (_) => _ComfortSheet(
      first: first,
      another: (current) => pickComfort(
        journal,
        capsules,
        session.uid,
        now,
        random,
        except: current,
      ),
    ),
  );
}

class _ComfortSheet extends StatefulWidget {
  const _ComfortSheet({required this.first, required this.another});

  final ComfortItem first;
  final ComfortItem? Function(ComfortItem current) another;

  @override
  State<_ComfortSheet> createState() => _ComfortSheetState();
}

class _ComfortSheetState extends State<_ComfortSheet> {
  late ComfortItem _item = widget.first;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final friend = _item.fromName;
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
          Text(
            'A little something for a hard day'.tr,
            style: context.text.title,
          ),
          const SizedBox(height: Space.xs),
          Text(
            'You’re not alone in this. Here is something to hold on to.'.tr,
            style: context.text.small,
          ),
          const SizedBox(height: Space.md),
          Flexible(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Space.md),
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(Radii.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend == null
                          ? '🤍  ${'From you, {date}'.tr.replaceAll('{date}', fullDate(_item.time))}'
                          : '☀️  ${'From {name}'.tr.replaceAll('{name}', friend)}',
                      style: context.text.caption.copyWith(color: c.inkSoft),
                    ),
                    const SizedBox(height: Space.xs),
                    ContentText(
                      _item.text,
                      style: context.text.noteBody.copyWith(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          Row(
            children: [
              Expanded(
                child: NwuButton(
                  label: 'Another one'.tr,
                  tone: ButtonTone.outline,
                  onPressed: () {
                    final next = widget.another(_item);
                    if (next != null) setState(() => _item = next);
                  },
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: NwuButton(
                  label: 'Thank you'.tr,
                  tone: ButtonTone.accent,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
