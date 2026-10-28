import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/prefs.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';

/// Which notes you already sent a hug for, kept on this device so the
/// button doesn't invite a second one.
class HugLog extends ChangeNotifier {
  HugLog._();

  /// Shared instance.
  static final HugLog instance = HugLog._();

  static const _key = 'huggedNotes';
  static const _max = 200;

  List<String> get _keys => (Prefs.getString(_key) ?? '')
      .split(',')
      .where((k) => k.isNotEmpty)
      .toList();

  bool hugged(Note note) => _keys.contains(note.key);

  void record(Note note) {
    final keys = [note.key, ..._keys.where((k) => k != note.key)].take(_max);
    Prefs.setString(_key, keys.join(','));
    notifyListeners();
  }
}

/// Short, kind messages to send in one tap.
const _presets = [
  'Thinking of you. You’ve got this. 🤍',
  'I’m here whenever you want to talk.',
  'Sending you the biggest hug today.',
];

/// Offers a few kind messages for [note]'s author; tapping one sends it
/// as a morning note, so it is waiting for them tomorrow.
Future<void> showHugSheet(BuildContext context, Note note) {
  return showNwuSheet<void>(context, builder: (_) => _HugSheet(note: note));
}

class _HugSheet extends StatefulWidget {
  const _HugSheet({required this.note});

  final Note note;

  @override
  State<_HugSheet> createState() => _HugSheetState();
}

class _HugSheetState extends State<_HugSheet> {
  String? _sending;

  Future<void> _send(String text, AppUser friend) async {
    if (_sending != null) return;
    final session = Session.instance;
    setState(() => _sending = text);
    try {
      await session.capsules.create(
        author: session.me,
        recipient: friend,
        text: text.tr,
        mood: Mood.love,
        unlockAt: nextMorning(DateTime.now()),
        kind: morningKind,
      );
      HugLog.instance.record(widget.note);
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      final navigator = Navigator.of(context);
      navigator.pop();
      showToast(
        navigator.context,
        'Your hug will be there tomorrow morning 🤍'.tr,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _sending = null);
        showToast(context, 'Something went wrong'.tr, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final note = widget.note;
    final friend = Session.instance.userOr(
      note.ownerId,
      name: note.ownerName,
      image: note.ownerImage,
    );
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
                  'Send {name} a hug'.tr.replaceAll('{name}', friend.firstName),
                  style: context.text.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(
            'Pick a message. It shows up on their Today tomorrow morning.'.tr,
            style: context.text.small,
          ),
          const SizedBox(height: Space.md),
          for (final text in _presets)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.xs),
              child: Pressable(
                onTap: () => _send(text, friend),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Space.md),
                  decoration: BoxDecoration(
                    color: c.accentSoft,
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(text.tr, style: context.text.label)),
                      if (_sending == text)
                        const CupertinoActivityIndicator()
                      else
                        Icon(
                          CupertinoIcons.paperplane,
                          size: 18,
                          color: c.accent,
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The soft button under a friend's blue circle note.
class HugButton extends StatelessWidget {
  const HugButton({super.key, required this.note});

  final Note note;

  /// Whether [note] deserves the button: a friend's circle note written
  /// in a blue mood, from someone you can send a capsule to.
  static bool shows(Note note) {
    final session = Session.instance;
    return !session.isGuest &&
        note.audience == Audience.circle &&
        note.mood == Mood.blue &&
        note.ownerId != session.uid &&
        session.circle.contains(note.ownerId);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListenableBuilder(
      listenable: HugLog.instance,
      builder: (context, _) {
        final done = HugLog.instance.hugged(note);
        return Pressable(
          onTap: done ? null : () => showHugSheet(context, note),
          semanticLabel: 'Send a hug'.tr,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: done ? c.surface : c.accentSoft,
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🤍', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  (done ? 'Hug sent' : 'Send a hug').tr,
                  style: context.text.caption.copyWith(
                    color: done ? c.inkSoft : c.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
