import 'package:flutter/cupertino.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';

/// Writes a short surprise note that lands on [friend]'s Today the next
/// morning. It is a sealed capsule underneath, so nobody can read it
/// early.
Future<void> showMorningNoteSheet(BuildContext context, AppUser friend) {
  return showNwuSheet<void>(
    context,
    builder: (_) => _MorningNoteForm(friend: friend),
  );
}

class _MorningNoteForm extends StatefulWidget {
  const _MorningNoteForm({required this.friend});

  final AppUser friend;

  @override
  State<_MorningNoteForm> createState() => _MorningNoteFormState();
}

class _MorningNoteFormState extends State<_MorningNoteForm> {
  static const _maxLength = 160;

  final _text = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;
    final session = Session.instance;
    setState(() => _sending = true);
    try {
      await session.capsules.create(
        author: session.me,
        recipient: widget.friend,
        text: text,
        mood: Mood.joy,
        unlockAt: nextMorning(DateTime.now()),
        kind: morningKind,
      );
      if (!mounted) return;
      final navigator = Navigator.of(context);
      navigator.pop();
      showToast(navigator.context, 'Morning note scheduled ☀️'.tr);
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
        showToast(context, 'Something went wrong'.tr, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final friend = widget.friend;
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
          Row(
            children: [
              Avatar(url: friend.image, name: friend.username, size: 40),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  'A morning note for {name}'.tr.replaceAll(
                    '{name}',
                    friend.firstName,
                  ),
                  style: context.text.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(
            'It shows up on their Today tomorrow morning, as a surprise.'.tr,
            style: context.text.small,
          ),
          const SizedBox(height: Space.md),
          NwuField(
            controller: _text,
            hint: 'Say something kind…'.tr,
            maxLines: 3,
            maxLength: _maxLength,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: Space.sm),
          ListenableBuilder(
            listenable: _text,
            builder: (context, _) => NwuButton(
              label: 'Send for tomorrow morning'.tr,
              icon: CupertinoIcons.sun_max,
              tone: ButtonTone.accent,
              loading: _sending,
              onPressed: _text.text.trim().isEmpty ? null : _send,
            ),
          ),
        ],
      ),
    );
  }
}
