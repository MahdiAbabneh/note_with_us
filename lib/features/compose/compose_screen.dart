import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/drafts.dart';
import '../../core/format.dart';
import '../../core/islamic.dart';
import '../../core/settings.dart';
import '../../core/insights.dart';
import '../../core/prompts.dart';
import '../../core/tags.dart';
import '../../core/l10n.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import '../auth/join_sheet.dart';
import '../comfort/comfort_sheet.dart';
import '../freewrite/free_write_screen.dart';
import '../notes/note_card.dart';

/// Where a new piece of writing goes.
enum ComposeTarget { private, circle, everyone, capsule }

/// Opens the composer as a full-screen modal.
Future<void> openComposer(
  BuildContext context, {
  String prompt = '',
  ComposeTarget? target,
  AppUser? recipient,
  Mood? mood,
  String text = '',
}) async {
  // Every way into the composer goes through here, so guests are asked
  // to join once, in one place.
  if (needsAccount(context, 'Join to write your first note'.tr)) return;
  await Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => ComposeScreen(
        prompt: prompt,
        initialTarget: target,
        recipient: recipient,
        initialMood: mood,
        initialText: text,
      ),
    ),
  );
}

/// Write a note or seal a time capsule.
class ComposeScreen extends StatefulWidget {
  const ComposeScreen({
    super.key,
    this.prompt = '',
    this.initialTarget,
    this.recipient,
    this.initialMood,
    this.initialText = '',
  });

  final String prompt;
  final ComposeTarget? initialTarget;
  final AppUser? recipient;
  final Mood? initialMood;

  /// Text to start with, e.g. a greeting or a tag.
  final String initialText;

  /// Opening the composer with no preset continues the saved draft.
  bool get continuesDraft =>
      prompt.isEmpty &&
      initialTarget == null &&
      recipient == null &&
      initialMood == null &&
      initialText.isEmpty;

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _session = Session.instance;
  final _text = TextEditingController();
  // Never default to a public post: with no circle yet, start private.
  late ComposeTarget _target =
      widget.initialTarget ??
      (_session.circle.isEmpty ? ComposeTarget.private : ComposeTarget.circle);
  late String _prompt = widget.prompt;
  late Mood _mood = widget.initialMood ?? Mood.plain;
  late AppUser _recipient = widget.recipient ?? _session.me;
  DateTime _unlockAt = DateTime.now().add(const Duration(days: 30));
  bool _posting = false;
  bool _posted = false;

  bool get _isCapsule => _target == ComposeTarget.capsule;
  bool get _canPost => _text.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final draft = widget.continuesDraft ? DraftStore.instance.current : null;
    if (draft != null) {
      _text.text = draft.text;
      _mood = Mood.fromId(draft.mood);
      _prompt = draft.prompt;
      _target = ComposeTarget.values.firstWhere(
        (t) => t.name == draft.target,
        orElse: () => _target,
      );
    } else if (widget.initialText.isNotEmpty) {
      _text.value = TextEditingValue(
        text: widget.initialText,
        selection: TextSelection.collapsed(offset: widget.initialText.length),
      );
    }
    _text.addListener(() {
      setState(() {});
      _saveDraft();
    });
  }

  void _saveDraft() {
    if (_posted) return;
    if (_text.text.trim().isEmpty) {
      DraftStore.instance.clear();
      return;
    }
    DraftStore.instance.save(
      Draft(
        text: _text.text,
        mood: _mood.id,
        target: _target.name,
        prompt: _prompt,
      ),
    );
  }

  /// Suggests a question when the writer doesn't know where to start.
  void _shufflePrompt() {
    HapticFeedback.selectionClick();
    setState(() => _prompt = randomPrompt(except: _prompt));
    _saveDraft();
  }

  void _setTarget(ComposeTarget target) {
    setState(() => _target = target);
    _saveDraft();
  }

  /// Fills a capsule with a starting letter, date and feeling; the writer
  /// can change any of it.
  void _applyTemplate(_CapsuleTemplate template) {
    HapticFeedback.selectionClick();
    setState(() {
      _recipient = _session.me;
      _unlockAt = template.unlockAt(DateTime.now());
      _mood = template.mood;
    });
    final body = template.text();
    _text.value = TextEditingValue(
      text: body,
      selection: TextSelection.collapsed(offset: body.length),
    );
  }

  /// Free writing is its own screen; if it saved a note this one is done.
  Future<void> _freeWrite() async {
    final saved = await Navigator.of(context).push<bool>(
      CupertinoPageRoute<bool>(builder: (_) => const FreeWriteScreen()),
    );
    if (saved == true && mounted) {
      _posted = true;
      DraftStore.instance.clear();
      Navigator.pop(context);
    }
  }

  /// Puts `#tag ` where the cursor is (or at the end).
  void _insertTag(String tag) {
    HapticFeedback.selectionClick();
    final value = _text.value;
    final at = value.selection.isValid
        ? value.selection.end
        : value.text.length;
    final before = value.text.substring(0, at);
    final after = value.text.substring(at);
    final gap = before.isEmpty || before.endsWith(' ') || before.endsWith('\n')
        ? ''
        : ' ';
    final insert = '$gap#$tag ';
    _text.value = TextEditingValue(
      text: '$before$insert$after',
      selection: TextSelection.collapsed(offset: before.length + insert.length),
    );
  }

  bool _comfortOffered = false;

  void _setMood(Mood mood) {
    setState(() => _mood = mood);
    if (mood == Mood.blue && !_comfortOffered && !_isCapsule) {
      _comfortOffered = true;
      showComfortSheet(context);
    }
    _saveDraft();
  }

  void _showPreview() {
    final me = _session.me;
    final note = Note(
      id: '',
      audience: switch (_target) {
        ComposeTarget.private => Audience.private,
        ComposeTarget.circle => Audience.circle,
        _ => Audience.everyone,
      },
      text: _text.text.trim(),
      images: const [],
      time: DateTime.now(),
      ownerId: me.uid,
      ownerName: me.username,
      ownerImage: me.image,
      mood: _mood,
      prompt: _prompt,
    );
    showNwuSheet<void>(
      context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          Space.md,
          Space.gutter,
          Space.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preview'.tr, style: ctx.text.title),
            const SizedBox(height: Space.xs),
            Text('This is how your note will look.'.tr, style: ctx.text.small),
            const SizedBox(height: Space.lg),
            Flexible(
              child: SingleChildScrollView(
                child: NoteCard(note: note, preview: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// Replaces the "Note posted" toast with the streak when it is 2 or
  /// more days. Best effort: a slow or failed read leaves the plain toast.
  Future<void> _celebrateStreak(BuildContext context, String uid) async {
    final streak = await _currentStreak(uid);
    if (streak >= 2 && context.mounted) {
      showToast(context, _postedMessage(streak));
    }
  }

  /// Days in a row including the note just posted (0 if unknown).
  Future<int> _currentStreak(String uid) async {
    try {
      final notes = await Session.instance.notes
          .mine(uid)
          .first
          .timeout(const Duration(seconds: 2));
      return WeekInsights.from(notes, DateTime.now()).streak;
    } catch (_) {
      return 0;
    }
  }

  String _postedMessage(int streak) {
    if (streak < 2) return 'Note posted'.tr;
    final days = '{n} days in a row'.tr.replaceAll('{n}', '$streak');
    return '${const {3, 7, 14, 30, 100}.contains(streak) ? '🎉' : '🌱'} $days';
  }

  Future<void> _post() async {
    if (!_canPost || _posting) return;
    // Public posts are the one irreversible-feeling choice; ask first so a
    // private thought is never shared with everyone by accident.
    if (_target == ComposeTarget.everyone) {
      final ok = await confirm(
        context,
        title: 'Share with everyone?'.tr,
        message:
            'Anyone on Note With Us will be able to see and react to this note.'
                .tr,
        confirmLabel: 'Share publicly'.tr,
      );
      if (!ok || !mounted) return;
    }
    setState(() => _posting = true);
    final me = _session.me;
    try {
      if (_isCapsule) {
        await _session.capsules.create(
          author: me,
          recipient: _recipient,
          text: _text.text.trim(),
          mood: _mood,
          unlockAt: _unlockAt,
        );
      } else {
        await _session.notes.create(
          author: me,
          audience: switch (_target) {
            ComposeTarget.private => Audience.private,
            ComposeTarget.circle => Audience.circle,
            _ => Audience.everyone,
          },
          text: _text.text.trim(),
          mood: _mood,
          prompt: _prompt,
          // A circle answer to today's question lets friends answer the
          // same one together, in whichever language they use.
          promptDay:
              _target == ComposeTarget.circle &&
                  _prompt == PromptState.instance.today
              ? dayKey(DateTime.now())
              : '',
          circle: _session.circle.toList(),
        );
      }
      if (!mounted) return;
      _posted = true;
      DraftStore.instance.clear();
      RecentTags.record(_text.text);
      if (!_isCapsule) PromptState.instance.noteAnswered(_prompt);
      HapticFeedback.mediumImpact();
      final navigator = Navigator.of(context);
      navigator.pop();
      showToast(
        navigator.context,
        _isCapsule ? 'Capsule sealed ⏳'.tr : 'Note posted'.tr,
      );
      // The composer is already closed; the streak shows up a moment later
      // if there is one, so a slow connection never holds the screen.
      if (!_isCapsule) unawaited(_celebrateStreak(navigator.context, me.uid));
    } catch (_) {
      if (mounted) showToast(context, 'Something went wrong'.tr, error: true);
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_posted && _text.text.trim().isNotEmpty) {
          showToast(context, 'Draft saved'.tr);
        }
      },
      child: Scaffold(
        backgroundColor: c.moodTint(_mood) == c.raised
            ? c.canvas
            : c.moodTint(_mood),
        appBar: TopBar(
          close: true,
          title: _isCapsule ? 'New capsule'.tr : 'New note'.tr,
          actions: [
            if (!_isCapsule && _canPost) ...[
              CircleIconButton(
                icon: CupertinoIcons.eye,
                size: 40,
                semanticLabel: 'Preview'.tr,
                onPressed: _showPreview,
              ),
              const SizedBox(width: Space.xs),
            ],
            NwuButton(
              label: _isCapsule ? 'Seal'.tr : 'Post'.tr,
              tone: ButtonTone.accent,
              compact: true,
              expand: false,
              loading: _posting,
              onPressed: _canPost ? _post : null,
            ),
          ],
        ),
        body: Column(
          children: [
            _TargetPicker(value: _target, onChanged: _setTarget),
            _TargetHint(target: _target),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: Space.xl),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  if (_isCapsule)
                    _CapsuleOptions(
                      recipient: _recipient,
                      unlockAt: _unlockAt,
                      onRecipient: (u) => setState(() => _recipient = u),
                      onUnlockAt: (d) => setState(() => _unlockAt = d),
                    ),
                  if (_isCapsule && _text.text.isEmpty)
                    _CapsuleTemplates(onPick: _applyTemplate),
                  if (_prompt.isNotEmpty && !_isCapsule)
                    _PromptChip(
                      prompt: _prompt,
                      onShuffle: _shufflePrompt,
                      onRemove: () => setState(() => _prompt = ''),
                    )
                  else if (!_isCapsule && _text.text.isEmpty)
                    _IdeaButton(onTap: _shufflePrompt, onFreeWrite: _freeWrite),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.gutter,
                    ),
                    child: PaperBackdrop(
                      lineHeight: lineHeightOf(
                        context.text.noteBody.copyWith(fontSize: 21),
                      ),
                      child: TextField(
                        controller: _text,
                        textDirection: inputDirection(context, _text.text),
                        autofocus: true,
                        minLines: 6,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        style: context.text.noteBody.copyWith(fontSize: 21),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: _isCapsule
                              ? 'Dear future you…'.tr
                              : (_prompt.isNotEmpty
                                    ? 'Write your answer…'.tr
                                    : 'What’s on your mind?'.tr),
                          hintStyle: context.text.noteBody.copyWith(
                            fontSize: 21,
                            color: c.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!_isCapsule) _TagBar(text: _text.text, onTag: _insertTag),
            _MoodBar(value: _mood, onChanged: _setMood),
          ],
        ),
      ),
    );
  }
}

class _TargetPicker extends StatelessWidget {
  const _TargetPicker({required this.value, required this.onChanged});

  final ComposeTarget value;
  final ValueChanged<ComposeTarget> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const options = [
      (ComposeTarget.private, CupertinoIcons.lock_fill, 'Only me'),
      (ComposeTarget.circle, CupertinoIcons.circle_grid_hex_fill, 'Circle'),
      (ComposeTarget.everyone, CupertinoIcons.globe, 'Everyone'),
      (ComposeTarget.capsule, CupertinoIcons.hourglass, 'Capsule'),
    ];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
        children: [
          for (final (target, icon, label) in options)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: Space.xs),
              child: Pressable(
                onTap: () => onChanged(target),
                child: AnimatedContainer(
                  duration: Motion.base,
                  curve: Motion.ease,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: value == target ? c.ink : c.raised,
                    borderRadius: BorderRadius.circular(Radii.pill),
                    border: Border.all(color: value == target ? c.ink : c.line),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 15,
                        color: value == target ? c.canvas : c.inkSoft,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label.tr,
                        style: context.text.label.copyWith(
                          color: value == target ? c.canvas : c.ink,
                        ),
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

class _TargetHint extends StatelessWidget {
  const _TargetHint({required this.target});

  final ComposeTarget target;

  @override
  Widget build(BuildContext context) {
    final circleSize = Session.instance.circle.length;
    final text = switch (target) {
      ComposeTarget.private => 'Saved to your journal. Only you can see it.'.tr,
      ComposeTarget.circle =>
        circleSize == 0
            ? 'Your circle is empty, so only you will see this for now.'.tr
            : circleSize == 1
            ? 'Shared with the 1 person in your circle.'.tr
            : 'Shared with the {n} people in your circle.'.tr.replaceAll(
                '{n}',
                '$circleSize',
              ),
      ComposeTarget.everyone => 'Anyone on Note With Us can see and react.'.tr,
      ComposeTarget.capsule =>
        'Sealed until the date you choose. Nobody can read it before then.'.tr,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.sm,
        Space.gutter,
        Space.xs,
      ),
      child: AnimatedSwitcher(
        duration: Motion.base,
        child: Text(text, key: ValueKey(target), style: context.text.caption),
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({
    required this.prompt,
    required this.onShuffle,
    required this.onRemove,
  });

  final String prompt;
  final VoidCallback onShuffle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.sm,
        Space.gutter,
        0,
      ),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 6, 10),
        decoration: BoxDecoration(
          color: c.accentSoft,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.sparkles, size: 16, color: c.accent),
            const SizedBox(width: Space.xs),
            Expanded(
              child: Text(
                prompt,
                style: context.text.label.copyWith(color: c.ink),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Another idea'.tr,
              onPressed: onShuffle,
              icon: const Text('🎲', style: TextStyle(fontSize: 16)),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              icon: Icon(CupertinoIcons.xmark, size: 16, color: c.inkSoft),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }
}

class _IdeaButton extends StatelessWidget {
  const _IdeaButton({required this.onTap, required this.onFreeWrite});

  final VoidCallback onTap;
  final VoidCallback onFreeWrite;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.sm,
        Space.gutter,
        0,
      ),
      child: Wrap(
        spacing: Space.xs,
        runSpacing: Space.xs,
        children: [
          for (final (label, tap, hint) in [
            ('🎲  ${'Need an idea?'.tr}', onTap, 'Need an idea?'.tr),
            ('⏱  ${'Free writing'.tr}', onFreeWrite, 'Free writing'.tr),
          ])
            Pressable(
              onTap: tap,
              semanticLabel: hint,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: Text(
                  label,
                  style: context.text.label.copyWith(
                    color: c.ink,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: Motion.base);
  }
}

/// A ready-made letter for a time capsule. English text is the key for
/// the Arabic translation.
class _CapsuleTemplate {
  const _CapsuleTemplate({
    required this.emoji,
    required this.title,
    required this.body,
    required this.mood,
    required this.unlockAt,
    this.eid,
  });

  final String emoji;
  final String title;
  final String body;

  /// Set for an Eid greeting, whose text comes from [eidGreeting].
  final IslamicOccasion? eid;

  /// The starting letter in the app language.
  String text() => eid == null
      ? body.tr
      : '${eidGreeting(eid!)}\n\n${'This year I am grateful for…'.tr}';
  final Mood mood;
  final DateTime Function(DateTime now) unlockAt;
}

/// Eid greetings, offered only when Ramadan and Eid features are on.
final _eidTemplates = <_CapsuleTemplate>[
  _CapsuleTemplate(
    emoji: '🌙',
    title: 'Eid al-Fitr greeting',
    body: '',
    eid: IslamicOccasion.eidAlFitr,
    mood: Mood.joy,
    unlockAt: (now) => nextOccasionStart(IslamicOccasion.eidAlFitr, now),
  ),
  _CapsuleTemplate(
    emoji: '✨',
    title: 'Eid al-Adha greeting',
    body: '',
    eid: IslamicOccasion.eidAlAdha,
    mood: Mood.joy,
    unlockAt: (now) => nextOccasionStart(IslamicOccasion.eidAlAdha, now),
  ),
];

final _capsuleTemplates = <_CapsuleTemplate>[
  _CapsuleTemplate(
    emoji: '💌',
    title: 'Letter to me in 30 days',
    body:
        'Dear future me,\n\nToday I feel…\n\nBy the time you read this, I hope…',
    mood: Mood.calm,
    unlockAt: (now) => now.add(const Duration(days: 30)),
  ),
  _CapsuleTemplate(
    emoji: '🌅',
    title: 'Letter to me in 1 year',
    body:
        'Dear me, one year from now,\n\nThis is what my life looks like today…\n\nWhat I hope for you…',
    mood: Mood.dreamy,
    unlockAt: (now) => DateTime(now.year + 1, now.month, now.day, now.hour),
  ),
  _CapsuleTemplate(
    emoji: '🎆',
    title: 'Happy New Year',
    body: 'Happy New Year!\n\nLast year I…\n\nThis year I want…',
    mood: Mood.joy,
    unlockAt: (now) => DateTime(now.year + 1, 1, 1, 9),
  ),
  _CapsuleTemplate(
    emoji: '🫂',
    title: 'For a hard day',
    body:
        'Hey you,\n\nIf you are reading this on a hard day, remember…\n\nYou have gotten through hard days before.',
    mood: Mood.blue,
    unlockAt: (now) => now.add(const Duration(days: 90)),
  ),
];

/// Quick starts for an empty capsule.
class _CapsuleTemplates extends StatelessWidget {
  const _CapsuleTemplates({required this.onPick});

  final ValueChanged<_CapsuleTemplate> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            Space.sm,
            Space.gutter,
            Space.xs,
          ),
          child: Text('Start from a template'.tr, style: context.text.caption),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            children: [
              for (final template in [
                ..._capsuleTemplates,
                if (AppSettings.instance.islamic) ..._eidTemplates,
              ])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: Space.xs),
                  child: Pressable(
                    onTap: () => onPick(template),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.accentSoft,
                        borderRadius: BorderRadius.circular(Radii.pill),
                      ),
                      child: Text(
                        '${template.emoji}  ${template.title.tr}',
                        style: context.text.label.copyWith(color: c.ink),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: Motion.base);
  }
}

class _CapsuleOptions extends StatelessWidget {
  const _CapsuleOptions({
    required this.recipient,
    required this.unlockAt,
    required this.onRecipient,
    required this.onUnlockAt,
  });

  final AppUser recipient;
  final DateTime unlockAt;
  final ValueChanged<AppUser> onRecipient;
  final ValueChanged<DateTime> onUnlockAt;

  Future<void> _pickRecipient(BuildContext context) async {
    final picked = await pickPerson(
      context,
      title: 'Who is this capsule for?'.tr,
      includeMe: true,
    );
    if (picked != null) onRecipient(picked);
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await pickDate(
      context,
      initial: unlockAt,
      minimum: DateTime.now().add(const Duration(days: 1)),
      maximum: DateTime.now().add(const Duration(days: 365 * 20)),
    );
    if (picked != null) onUnlockAt(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final me = Session.instance.uid == recipient.uid;
    final now = DateTime.now();
    final birth = parseBirthDate(recipient.dateOfBirth);
    final presets = [
      // Profiles already store a birthday, so a capsule can arrive on it.
      if (birth != null)
        (
          me ? 'On my birthday 🎂' : 'On their birthday 🎂',
          nextBirthday(birth, now),
        ),
      ('1 month', now.add(const Duration(days: 30))),
      ('6 months', now.add(const Duration(days: 182))),
      ('1 year', DateTime(now.year + 1, now.month, now.day, now.hour)),
      ('5 years', DateTime(now.year + 5, now.month, now.day, now.hour)),
    ];
    bool isPreset(DateTime d) => d.difference(unlockAt).inHours.abs() < 2;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.sm,
        Space.gutter,
        Space.xs,
      ),
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: c.raised,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Pressable(
            onTap: () => _pickRecipient(context),
            child: Row(
              children: [
                Avatar(
                  url: recipient.image,
                  name: recipient.username,
                  size: 36,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('To'.tr, style: context.text.caption),
                      Text(
                        me ? 'Future me'.tr : recipient.username,
                        style: context.text.bodyStrong,
                      ),
                    ],
                  ),
                ),
                Text(
                  'Change'.tr,
                  style: context.text.label.copyWith(color: c.accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          Divider(color: c.line),
          const SizedBox(height: Space.md),
          Text('Opens on'.tr, style: context.text.caption),
          const SizedBox(height: 2),
          Text(
            fullDate(unlockAt),
            style: context.text.title.copyWith(fontSize: 22),
          ),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final (label, date) in presets)
                _DateChip(
                  label: label.tr,
                  selected: isPreset(date),
                  onTap: () => onUnlockAt(date),
                ),
              _DateChip(
                label: 'Pick a date'.tr,
                icon: CupertinoIcons.calendar,
                selected: !presets.any((p) => isPreset(p.$2)),
                onTap: () => _pickDate(context),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: Motion.base).slideY(begin: -0.05);
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.base,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.accentSoft : c.surface,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: selected ? c.accent : c.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? c.accent : c.inkSoft),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: context.text.caption.copyWith(
                color: selected ? c.accent : c.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One-tap `#tags` under the text: the ones you used lately, then a few
/// starters.
class _TagBar extends StatelessWidget {
  const _TagBar({required this.text, required this.onTag});

  final String text;
  final ValueChanged<String> onTag;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tags = tagSuggestions(text);
    if (tags.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: Space.gutter,
          vertical: 4,
        ),
        children: [
          for (final tag in tags)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: Pressable(
                onTap: () => onTag(tag),
                scale: 0.92,
                semanticLabel: '#$tag',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.accentSoft,
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                  child: Text(
                    '#$tag',
                    style: context.text.caption.copyWith(
                      color: c.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MoodBar extends StatelessWidget {
  const _MoodBar({required this.value, required this.onChanged});

  final Mood value;
  final ValueChanged<Mood> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.only(
        top: Space.sm,
        bottom: Space.sm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: c.canvas.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
          children: [
            Center(child: Text('Mood'.tr, style: context.text.overline)),
            const SizedBox(width: Space.sm),
            for (final mood in Mood.values)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: Pressable(
                  onTap: () => onChanged(mood),
                  scale: 0.9,
                  child: AnimatedContainer(
                    duration: Motion.base,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: mood == value
                          ? c.moodTint(mood)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(Radii.pill),
                      border: Border.all(
                        color: mood == value ? c.moodInk(mood) : c.line,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(mood.emoji, style: const TextStyle(fontSize: 16)),
                        if (mood == value) ...[
                          const SizedBox(width: 6),
                          Text(mood.label.tr, style: context.text.label),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A sheet to choose a person; optionally offers "Future me" first.
Future<AppUser?> pickPerson(
  BuildContext context, {
  required String title,
  bool includeMe = false,
}) {
  final session = Session.instance;
  final query = ValueNotifier('');
  return showNwuSheet<AppUser>(
    context,
    builder: (ctx) => SizedBox(
      height: MediaQuery.of(ctx).size.height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              Space.md,
              Space.gutter,
              Space.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ctx.text.title),
                const SizedBox(height: Space.sm),
                SearchField(
                  controller: TextEditingController(),
                  hint: 'Search people'.tr,
                  onChanged: (v) => query.value = v.toLowerCase(),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: query,
              builder: (ctx, q, _) {
                // Capsules go only to you or someone in your circle.
                final people = session.circleMembers
                    .where((p) => session.isVisible(p.uid))
                    .where((p) => p.username.toLowerCase().contains(q))
                    .toList();
                return ListView(
                  children: [
                    if (includeMe && q.isEmpty)
                      _PersonRow(
                        user: session.me,
                        label: 'Future me'.tr,
                        onTap: () => Navigator.pop(ctx, session.me),
                      ),
                    for (final person in people)
                      _PersonRow(
                        user: person,
                        inCircle: true,
                        onTap: () => Navigator.pop(ctx, person),
                      ),
                    if (session.circle.isEmpty && q.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(Space.gutter),
                        child: Text(
                          'Add people to your circle to send them capsules.'.tr,
                          style: ctx.text.small,
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.user,
    required this.onTap,
    this.label,
    this.inCircle = false,
  });

  final AppUser user;
  final VoidCallback onTap;
  final String? label;
  final bool inCircle;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.99,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.gutter,
          vertical: Space.xs,
        ),
        child: Row(
          children: [
            Avatar(
              url: user.image,
              name: user.username,
              size: 42,
              ring: inCircle,
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text(
                label ?? user.username,
                style: context.text.bodyStrong,
              ),
            ),
            if (inCircle) Tag(label: 'Circle'.tr),
          ],
        ),
      ),
    );
  }
}

/// Cupertino-style date wheel in a sheet.
Future<DateTime?> pickDate(
  BuildContext context, {
  required DateTime initial,
  required DateTime minimum,
  required DateTime maximum,
}) {
  var selected = initial;
  return showNwuSheet<DateTime>(
    context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.md,
        Space.gutter,
        Space.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 216,
            child: CupertinoTheme(
              data: CupertinoThemeData(
                brightness: ctx.colors.isDark
                    ? Brightness.dark
                    : Brightness.light,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: ctx.text.headline.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initial,
                minimumDate: minimum,
                maximumDate: maximum,
                onDateTimeChanged: (d) => selected = d,
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          NwuButton(
            label: 'Done'.tr,
            onPressed: () => Navigator.pop(ctx, selected),
          ),
        ],
      ),
    ),
  );
}
