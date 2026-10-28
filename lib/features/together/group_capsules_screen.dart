import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/format.dart';
import '../../core/hijri.dart';
import '../../core/islamic.dart';
import '../../core/settings.dart';
import '../../core/l10n.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import '../compose/compose_screen.dart' show pickDate;

/// Capsules the whole circle writes to and opens on the same day.
class GroupCapsulesScreen extends StatefulWidget {
  const GroupCapsulesScreen({super.key});

  @override
  State<GroupCapsulesScreen> createState() => _GroupCapsulesScreenState();
}

class _GroupCapsulesScreenState extends State<GroupCapsulesScreen> {
  final _session = Session.instance;
  late Stream<List<GroupCapsule>> _capsules = _session.groupCapsules.mine(
    _session.uid,
  );

  void _retry() =>
      setState(() => _capsules = _session.groupCapsules.mine(_session.uid));

  Future<void> _create() async {
    if (_session.circle.isEmpty) {
      showToast(context, 'Add people to your circle first.'.tr, error: true);
      return;
    }
    final created = await showNwuSheet<GroupCapsule?>(
      context,
      builder: (_) => const _NewGroupCapsuleSheet(),
    );
    if (created != null && mounted) showToast(context, 'Capsule started'.tr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(
        title: 'Circle capsules'.tr,
        actions: [
          CircleIconButton(
            icon: CupertinoIcons.add,
            size: 40,
            semanticLabel: 'New circle capsule'.tr,
            onPressed: _create,
          ),
        ],
      ),
      body: StreamBuilder<List<GroupCapsule>>(
        stream: _capsules,
        builder: (context, snap) {
          if (snap.hasError) return ErrorState(onRetry: _retry);
          if (!snap.hasData) {
            return const Center(child: CupertinoActivityIndicator());
          }
          final all = snap.data!;
          if (all.isEmpty) {
            return EmptyState(
              emoji: '🎆',
              title: 'Write together, open together'.tr,
              message:
                  'Everyone in your circle writes a letter. They all open on the same day.'
                      .tr,
              actionLabel: 'New circle capsule'.tr,
              onAction: _create,
            );
          }
          final ready = all.where((c) => c.isUnlocked).toList();
          final waiting = all.where((c) => !c.isUnlocked).toList();
          Widget section(String title, List<GroupCapsule> list) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(title),
              for (final (i, capsule) in list.indexed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.gutter,
                    0,
                    Space.gutter,
                    Space.sm,
                  ),
                  child: _CapsuleTile(
                    capsule: capsule,
                  ).animate(delay: (i * 40).ms).fadeIn().slideY(begin: 0.05),
                ),
            ],
          );
          return ListView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + Space.xxl,
            ),
            children: [
              if (ready.isNotEmpty) section('Ready to open'.tr, ready),
              if (waiting.isNotEmpty) section('Waiting'.tr, waiting),
            ],
          );
        },
      ),
    );
  }
}

class _CapsuleTile extends StatelessWidget {
  const _CapsuleTile({required this.capsule});

  final GroupCapsule capsule;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final session = Session.instance;
    final ready = capsule.isUnlocked;
    final wrote = capsule.written.length;
    final people = capsule.members.length;
    final String status;
    if (ready) {
      status = 'Ready — tap to open'.tr;
    } else if (!capsule.hasWritten(session.uid)) {
      status = 'Your letter is missing ✍️'.tr;
    } else {
      status = '{a} of {b} have written'.tr
          .replaceAll('{a}', '$wrote')
          .replaceAll('{b}', '$people');
    }
    return Pressable(
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => GroupCapsuleScreen(capsuleId: capsule.id),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: ready ? c.accentSoft : c.raised,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: ready
              ? null
              : Border.all(color: c.line.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            Text(ready ? '💌' : '⏳', style: const TextStyle(fontSize: 28)),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(capsule.title, style: context.text.headline),
                  const SizedBox(height: 2),
                  Text(
                    ready
                        ? fullDate(capsule.unlockAt)
                        : '${countdown(capsule.unlockAt)} · ${fullDate(capsule.unlockAt)}',
                    style: context.text.caption,
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    status,
                    style: context.text.label.copyWith(
                      color: ready ? c.accent : c.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Names a new circle capsule and picks the day it opens.
class _NewGroupCapsuleSheet extends StatefulWidget {
  const _NewGroupCapsuleSheet();

  @override
  State<_NewGroupCapsuleSheet> createState() => _NewGroupCapsuleSheetState();
}

class _NewGroupCapsuleSheetState extends State<_NewGroupCapsuleSheet> {
  final _session = Session.instance;
  final _title = TextEditingController();
  late DateTime _unlockAt = _presets(DateTime.now()).first.$2;
  bool _saving = false;

  static List<(String, DateTime)> _presets(DateTime now) => [
    ('New Year', DateTime(now.year + 1, 1, 1, 9)),
    if (AppSettings.instance.islamic) ...[
      ('Ramadan', nextOccasionStart(IslamicOccasion.ramadan, now)),
      ('Eid al-Fitr', nextOccasionStart(IslamicOccasion.eidAlFitr, now)),
      ('Eid al-Adha', nextOccasionStart(IslamicOccasion.eidAlAdha, now)),
    ],
    ('1 month', now.add(const Duration(days: 30))),
    ('6 months', now.add(const Duration(days: 182))),
    ('1 year', DateTime(now.year + 1, now.month, now.day, now.hour)),
  ];

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  /// A name for the capsule when a dated preset is chosen and no name was
  /// typed yet, e.g. "Eid al-Fitr 1448".
  void _choosePreset(String label, DateTime date) {
    setState(() => _unlockAt = date);
    if (_title.text.trim().isNotEmpty) return;
    final year = switch (label) {
      'Ramadan' || 'Eid al-Fitr' || 'Eid al-Adha' => hijriYearOf(date),
      'New Year' => date.year,
      _ => null,
    };
    if (year != null) _title.text = '${label.tr} $year';
  }

  Future<void> _pickDate() async {
    final picked = await pickDate(
      context,
      initial: _unlockAt,
      minimum: DateTime.now().add(const Duration(days: 1)),
      maximum: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _unlockAt = picked);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await _session.groupCapsules.create(
        author: _session.me,
        title: title,
        unlockAt: _unlockAt,
        circle: _session.circle,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showToast(context, 'Something went wrong'.tr, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final presets = _presets(DateTime.now());
    bool isPreset(DateTime d) => d.difference(_unlockAt).inHours.abs() < 2;
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
          Text('New circle capsule'.tr, style: context.text.title),
          const SizedBox(height: Space.xs),
          Text(
            'Everyone in your circle ({n}) can write a letter. Nobody can read them until the day it opens.'
                .tr
                .replaceAll('{n}', '${_session.circle.length}'),
            style: context.text.small,
          ),
          const SizedBox(height: Space.md),
          NwuField(
            controller: _title,
            hint: 'Name it, e.g. New Year 2027'.tr,
            maxLength: 60,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: Space.sm),
          Text('Opens on'.tr, style: context.text.caption),
          const SizedBox(height: 2),
          Text(
            fullDate(_unlockAt),
            style: context.text.title.copyWith(fontSize: 22),
          ),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final (label, date) in presets)
                _Chip(
                  label: label.tr,
                  selected: isPreset(date),
                  onTap: () => _choosePreset(label, date),
                ),
              _Chip(
                label: 'Pick a date'.tr,
                selected: !presets.any((p) => isPreset(p.$2)),
                onTap: _pickDate,
              ),
            ],
          ),
          const SizedBox(height: Space.lg),
          ListenableBuilder(
            listenable: _title,
            builder: (context, _) => NwuButton(
              label: 'Start capsule'.tr,
              tone: ButtonTone.accent,
              loading: _saving,
              onPressed: _title.text.trim().isEmpty ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

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
        child: Text(
          label,
          style: context.text.caption.copyWith(
            color: selected ? c.accent : c.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// One circle capsule: write your letter while it is sealed, read
/// everyone's once it opens.
class GroupCapsuleScreen extends StatefulWidget {
  const GroupCapsuleScreen({super.key, required this.capsuleId});

  final String capsuleId;

  @override
  State<GroupCapsuleScreen> createState() => _GroupCapsuleScreenState();
}

class _GroupCapsuleScreenState extends State<GroupCapsuleScreen> {
  final _session = Session.instance;
  late final Stream<GroupCapsule?> _capsule = _session.groupCapsules.watch(
    widget.capsuleId,
  );

  Future<void> _delete(GroupCapsule capsule) async {
    final ok = await confirm(
      context,
      title: 'Delete this capsule?'.tr,
      message: 'Everyone’s letters will be deleted. This can’t be undone.'.tr,
      confirmLabel: 'Delete'.tr,
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await _session.groupCapsules.delete(capsule);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) showToast(context, 'Something went wrong'.tr, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GroupCapsule?>(
      stream: _capsule,
      builder: (context, snap) {
        final capsule = snap.data;
        return Scaffold(
          appBar: TopBar(
            title: capsule?.title ?? '',
            actions: [
              if (capsule != null && capsule.ownerId == _session.uid)
                CircleIconButton(
                  icon: CupertinoIcons.trash,
                  size: 40,
                  semanticLabel: 'Delete capsule'.tr,
                  onPressed: () => _delete(capsule),
                ),
            ],
          ),
          body: snap.hasError
              ? ErrorState(onRetry: () => setState(() {}))
              : capsule == null
              ? (snap.connectionState == ConnectionState.waiting
                    ? const Center(child: CupertinoActivityIndicator())
                    : EmptyState(
                        emoji: '🕊️',
                        title: 'This capsule is gone'.tr,
                        message: 'Its creator may have deleted it.'.tr,
                      ))
              : capsule.isUnlocked
              ? _Opened(capsule: capsule)
              : _Sealed(capsule: capsule),
        );
      },
    );
  }
}

/// Before it opens: who has written, and your own letter.
class _Sealed extends StatefulWidget {
  const _Sealed({required this.capsule});

  final GroupCapsule capsule;

  @override
  State<_Sealed> createState() => _SealedState();
}

class _SealedState extends State<_Sealed> {
  static const _maxLength = 1000;

  final _session = Session.instance;
  final _text = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _hadLetter = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final mine = await _session.groupCapsules.myEntry(
        widget.capsule.id,
        _session.uid,
      );
      if (mine != null) {
        _text.text = mine.text;
        _hadLetter = true;
      }
    } catch (_) {
      // Start with an empty page; saving still works.
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _text.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await _session.groupCapsules.saveEntry(
        capsule: widget.capsule,
        author: _session.me,
        text: text,
        mood: Mood.plain,
      );
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      setState(() {
        _saving = false;
        _hadLetter = true;
      });
      showToast(context, 'Your letter is sealed ⏳'.tr);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showToast(context, 'Something went wrong'.tr, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final capsule = widget.capsule;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        Space.gutter,
        Space.sm,
        Space.gutter,
        MediaQuery.of(context).padding.bottom + Space.xxl,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Text(countdown(capsule.unlockAt), style: context.text.display),
        const SizedBox(height: Space.xs),
        Text(
          'Opens {date}. Nobody can read the letters before then.'.tr
              .replaceAll('{date}', fullDate(capsule.unlockAt)),
          style: context.text.body.copyWith(color: c.inkSoft),
        ),
        const SizedBox(height: Space.lg),
        Wrap(
          spacing: Space.md,
          runSpacing: Space.sm,
          children: [
            for (final id in capsule.members)
              _Member(
                user: _session.userOr(id),
                written: capsule.hasWritten(id),
              ),
          ],
        ),
        const SizedBox(height: Space.xl),
        Text(
          (_hadLetter ? 'YOUR LETTER' : 'WRITE YOUR LETTER').tr,
          style: context.text.overline,
        ),
        const SizedBox(height: Space.sm),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(Space.lg),
            child: Center(child: CupertinoActivityIndicator()),
          )
        else ...[
          NwuField(
            controller: _text,
            hint: 'Write something for everyone…'.tr,
            maxLines: 8,
            maxLength: _maxLength,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: Space.sm),
          ListenableBuilder(
            listenable: _text,
            builder: (context, _) => NwuButton(
              label: (_hadLetter ? 'Update my letter' : 'Seal my letter').tr,
              tone: ButtonTone.accent,
              loading: _saving,
              onPressed: _text.text.trim().isEmpty ? null : _save,
            ),
          ),
        ],
      ],
    );
  }
}

class _Member extends StatelessWidget {
  const _Member({required this.user, required this.written});

  final AppUser user;
  final bool written;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: 60,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Opacity(
                opacity: written ? 1 : 0.45,
                child: Avatar(url: user.image, name: user.username, size: 48),
              ),
              if (written)
                PositionedDirectional(
                  end: -2,
                  bottom: -2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: c.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.canvas, width: 2),
                    ),
                    child: const Icon(
                      CupertinoIcons.checkmark,
                      size: 11,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            user.firstName.isEmpty ? '…' : user.firstName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.caption,
          ),
        ],
      ),
    );
  }
}

/// After it opens: everyone's letters, one after another.
class _Opened extends StatefulWidget {
  const _Opened({required this.capsule});

  final GroupCapsule capsule;

  @override
  State<_Opened> createState() => _OpenedState();
}

class _OpenedState extends State<_Opened> {
  late Future<List<GroupEntry>> _entries = Session.instance.groupCapsules
      .entries(widget.capsule.id);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GroupEntry>>(
      future: _entries,
      builder: (context, snap) {
        if (snap.hasError) {
          return ErrorState(
            onRetry: () => setState(
              () => _entries = Session.instance.groupCapsules.entries(
                widget.capsule.id,
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CupertinoActivityIndicator());
        }
        final letters = snap.data!;
        if (letters.isEmpty) {
          return EmptyState(
            emoji: '🕊️',
            title: 'No letters this time'.tr,
            message: 'Nobody wrote a letter before it opened.'.tr,
          );
        }
        final c = context.colors;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            Space.gutter,
            Space.sm,
            Space.gutter,
            MediaQuery.of(context).padding.bottom + Space.xxl,
          ),
          children: [
            Text(
              '${(letters.length == 1 ? '1 letter' : '{n} letters').tr.replaceAll('{n}', '${letters.length}')} · ${fullDate(widget.capsule.unlockAt)}',
              style: context.text.display,
            ),
            const SizedBox(height: Space.lg),
            for (final (i, letter) in letters.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child:
                    Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(Space.md),
                          decoration: BoxDecoration(
                            color: c.paperTint(letter.mood, letter.ownerId),
                            borderRadius: BorderRadius.circular(Radii.lg),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Avatar(
                                    url: Session.instance
                                        .userOr(
                                          letter.ownerId,
                                          image: letter.ownerImage,
                                        )
                                        .image,
                                    name: letter.ownerName,
                                    size: 32,
                                  ),
                                  const SizedBox(width: Space.xs),
                                  Expanded(
                                    child: Text(
                                      Session.instance
                                          .userOr(
                                            letter.ownerId,
                                            name: letter.ownerName,
                                          )
                                          .username,
                                      style: context.text.label,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: Space.sm),
                              ContentText(
                                letter.text,
                                style: context.text.noteBody.copyWith(
                                  fontSize: 17,
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate(delay: (i.clamp(0, 8) * 120).ms)
                        .fadeIn(duration: Motion.slow)
                        .slideY(begin: 0.06, curve: Motion.ease),
              ),
          ],
        );
      },
    );
  }
}
