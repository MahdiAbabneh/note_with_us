import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';

/// Questions to your circle with private answers: ask something like
/// "what is your best memory with me?" and only you read the replies.
class AskCircleScreen extends StatefulWidget {
  const AskCircleScreen({super.key});

  @override
  State<AskCircleScreen> createState() => _AskCircleScreenState();
}

class _AskCircleScreenState extends State<AskCircleScreen> {
  final _session = Session.instance;
  late Stream<List<CircleAsk>> _forMe = _session.asks.forMe(_session.uid);
  late Stream<List<CircleAsk>> _asked = _session.asks.asked(_session.uid);

  void _retry() => setState(() {
    _forMe = _session.asks.forMe(_session.uid);
    _asked = _session.asks.asked(_session.uid);
  });

  Future<void> _create() async {
    if (_session.circle.isEmpty) {
      showToast(context, 'Add people to your circle first.'.tr, error: true);
      return;
    }
    final created = await showNwuSheet<bool>(
      context,
      builder: (_) => const _NewAskSheet(),
    );
    if (created == true && mounted) showToast(context, 'Question sent'.tr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(
        title: 'Ask your circle'.tr,
        actions: [
          CircleIconButton(
            icon: CupertinoIcons.add,
            size: 40,
            semanticLabel: 'Ask a question'.tr,
            onPressed: _create,
          ),
        ],
      ),
      body: StreamBuilder<List<CircleAsk>>(
        stream: _forMe,
        builder: (context, forMeSnap) => StreamBuilder<List<CircleAsk>>(
          stream: _asked,
          builder: (context, askedSnap) {
            if (forMeSnap.hasError || askedSnap.hasError) {
              return ErrorState(onRetry: _retry);
            }
            if (!forMeSnap.hasData || !askedSnap.hasData) {
              return const Center(child: CupertinoActivityIndicator());
            }
            final uid = _session.uid;
            // Someone you blocked can't put questions in front of you.
            final forMe = forMeSnap.data!
                .where((a) => _session.isVisible(a.ownerId))
                .toList();
            final waiting = forMe.where((a) => !a.hasAnswered(uid)).toList();
            final answered = forMe.where((a) => a.hasAnswered(uid)).toList();
            final asked = askedSnap.data!;
            if (forMe.isEmpty && asked.isEmpty) {
              return EmptyState(
                emoji: '💬',
                title: 'Ask something that matters'.tr,
                message:
                    'Ask your circle a question, like “What is your best memory with me?”. Their answers are private. Only you can read them.'
                        .tr,
                actionLabel: 'Ask a question'.tr,
                onAction: _create,
              );
            }
            Widget section(String title, List<CircleAsk> list, bool mine) =>
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(title),
                    for (final (i, ask) in list.indexed)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Space.gutter,
                          0,
                          Space.gutter,
                          Space.sm,
                        ),
                        child: _AskTile(ask: ask, mine: mine)
                            .animate(delay: (i * 40).ms)
                            .fadeIn()
                            .slideY(begin: 0.05),
                      ),
                  ],
                );
            return ListView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + Space.xxl,
              ),
              children: [
                if (waiting.isNotEmpty)
                  section('Waiting for your answer'.tr, waiting, false),
                if (asked.isNotEmpty) section('Your questions'.tr, asked, true),
                if (answered.isNotEmpty)
                  section('Answered by you'.tr, answered, false),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AskTile extends StatelessWidget {
  const _AskTile({required this.ask, required this.mine});

  final CircleAsk ask;

  /// Whether you asked it (and read the answers) rather than answer it.
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final session = Session.instance;
    final answeredByMe = ask.hasAnswered(session.uid);
    final String status;
    if (mine) {
      status = '{a} of {b} answered'.tr
          .replaceAll('{a}', '${ask.answered.length}')
          .replaceAll('{b}', '${ask.members.length}');
    } else {
      status = answeredByMe
          ? 'You answered'.tr
          : 'From {name}'.tr.replaceAll('{name}', ask.ownerName);
    }
    final highlight = !mine && !answeredByMe;
    return Pressable(
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => mine
              ? AskAnswersScreen(askId: ask.id)
              : AnswerAskScreen(askId: ask.id),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: highlight ? c.accentSoft : c.raised,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: highlight
              ? null
              : Border.all(color: c.line.withValues(alpha: 0.7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ask.text, style: context.text.headline),
            const SizedBox(height: Space.xs),
            Text(
              '$status  ·  ${relativeTime(ask.createdAt)}',
              style: context.text.caption.copyWith(
                color: highlight ? c.accent : c.inkSoft,
                fontWeight: highlight ? FontWeight.w700 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Writes a question and picks who gets it (everyone by default).
class _NewAskSheet extends StatefulWidget {
  const _NewAskSheet();

  @override
  State<_NewAskSheet> createState() => _NewAskSheetState();
}

class _NewAskSheetState extends State<_NewAskSheet> {
  final _session = Session.instance;
  final _text = TextEditingController();
  late final Set<String> _chosen = {..._session.circle};
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || _chosen.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _session.asks.create(
        author: _session.me,
        text: text,
        members: _chosen,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
        showToast(context, 'Something went wrong'.tr, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final people = _session.circleMembers;
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
          Text('Ask your circle'.tr, style: context.text.title),
          const SizedBox(height: Space.xs),
          Text(
            'Their answers are private. Only you can read them.'.tr,
            style: context.text.small,
          ),
          const SizedBox(height: Space.md),
          NwuField(
            controller: _text,
            hint: 'What is your best memory with me?'.tr,
            maxLines: 3,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: Space.sm),
          Text('ASK'.tr, style: context.text.overline),
          const SizedBox(height: Space.xs),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final person in people)
                Pressable(
                  onTap: () => setState(() {
                    if (!_chosen.add(person.uid)) _chosen.remove(person.uid);
                  }),
                  child: AnimatedContainer(
                    duration: Motion.base,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _chosen.contains(person.uid)
                          ? c.accentSoft
                          : c.surface,
                      borderRadius: BorderRadius.circular(Radii.pill),
                      border: Border.all(
                        color: _chosen.contains(person.uid) ? c.accent : c.line,
                      ),
                    ),
                    child: Text(
                      person.firstName,
                      style: context.text.caption.copyWith(
                        color: _chosen.contains(person.uid) ? c.accent : c.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.lg),
          ListenableBuilder(
            listenable: _text,
            builder: (context, _) => NwuButton(
              label: 'Send question'.tr,
              tone: ButtonTone.accent,
              loading: _sending,
              onPressed: _text.text.trim().isEmpty || _chosen.isEmpty
                  ? null
                  : _send,
            ),
          ),
        ],
      ),
    );
  }
}

/// Answer a question you were asked; only its asker sees the answer.
class AnswerAskScreen extends StatefulWidget {
  const AnswerAskScreen({super.key, required this.askId});

  final String askId;

  @override
  State<AnswerAskScreen> createState() => _AnswerAskScreenState();
}

class _AnswerAskScreenState extends State<AnswerAskScreen> {
  final _session = Session.instance;
  final _text = TextEditingController();
  late final Stream<CircleAsk?> _ask = _session.asks.watch(widget.askId);
  bool _loading = true;
  bool _saving = false;
  bool _hadAnswer = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final mine = await _session.asks.myAnswer(widget.askId, _session.uid);
      if (mine != null) {
        _text.text = mine.text;
        _hadAnswer = true;
      }
    } catch (_) {
      // An empty page is fine; saving still works.
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save(CircleAsk ask) async {
    final text = _text.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await _session.asks.saveAnswer(ask: ask, author: _session.me, text: text);
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      final navigator = Navigator.of(context);
      navigator.pop();
      showToast(navigator.context, 'Your answer was sent'.tr);
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
    return StreamBuilder<CircleAsk?>(
      stream: _ask,
      builder: (context, snap) {
        final ask = snap.data;
        return Scaffold(
          appBar: const TopBar(),
          body: snap.hasError
              ? ErrorState(onRetry: () => setState(() {}))
              : ask == null
              ? (snap.connectionState == ConnectionState.waiting
                    ? const Center(child: CupertinoActivityIndicator())
                    : EmptyState(
                        emoji: '🕊️',
                        title: 'This question is gone'.tr,
                        message: 'Its author may have deleted it.'.tr,
                      ))
              : ListView(
                  padding: EdgeInsets.fromLTRB(
                    Space.gutter,
                    Space.sm,
                    Space.gutter,
                    MediaQuery.of(context).padding.bottom + Space.xxl,
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    Text(
                      'From {name}'.tr.replaceAll('{name}', ask.ownerName),
                      style: context.text.caption,
                    ),
                    const SizedBox(height: Space.xs),
                    Text(ask.text, style: context.text.display),
                    const SizedBox(height: Space.xs),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.lock_fill,
                          size: 12,
                          color: c.inkSoft,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Only {name} will see your answer.'.tr.replaceAll(
                              '{name}',
                              ask.ownerName,
                            ),
                            style: context.text.caption,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.lg),
                    if (_loading)
                      const Center(child: CupertinoActivityIndicator())
                    else ...[
                      NwuField(
                        controller: _text,
                        hint: 'Write your answer…'.tr,
                        maxLines: 8,
                        maxLength: 1000,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: Space.sm),
                      ListenableBuilder(
                        listenable: _text,
                        builder: (context, _) => NwuButton(
                          label:
                              (_hadAnswer
                                      ? 'Update my answer'
                                      : 'Send my answer')
                                  .tr,
                          tone: ButtonTone.accent,
                          loading: _saving,
                          onPressed: _text.text.trim().isEmpty
                              ? null
                              : () => _save(ask),
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

/// The answers to a question you asked, which only you can read.
class AskAnswersScreen extends StatefulWidget {
  const AskAnswersScreen({super.key, required this.askId});

  final String askId;

  @override
  State<AskAnswersScreen> createState() => _AskAnswersScreenState();
}

class _AskAnswersScreenState extends State<AskAnswersScreen> {
  final _session = Session.instance;
  late final Stream<CircleAsk?> _ask = _session.asks.watch(widget.askId);
  late Future<List<AskAnswer>> _answers = _session.asks.answers(widget.askId);

  Future<void> _delete(CircleAsk ask) async {
    final ok = await confirm(
      context,
      title: 'Delete this question?'.tr,
      message: 'Its answers will be deleted too. This can’t be undone.'.tr,
      confirmLabel: 'Delete'.tr,
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await _session.asks.delete(ask);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) showToast(context, 'Something went wrong'.tr, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return StreamBuilder<CircleAsk?>(
      stream: _ask,
      builder: (context, snap) {
        final ask = snap.data;
        return Scaffold(
          appBar: TopBar(
            actions: [
              if (ask != null)
                CircleIconButton(
                  icon: CupertinoIcons.trash,
                  size: 40,
                  semanticLabel: 'Delete question'.tr,
                  onPressed: () => _delete(ask),
                ),
            ],
          ),
          body: ask == null
              ? (snap.connectionState == ConnectionState.waiting
                    ? const Center(child: CupertinoActivityIndicator())
                    : EmptyState(
                        emoji: '🕊️',
                        title: 'This question is gone'.tr,
                        message: 'It was deleted.'.tr,
                      ))
              : FutureBuilder<List<AskAnswer>>(
                  future: _answers,
                  builder: (context, answersSnap) {
                    if (answersSnap.hasError) {
                      return ErrorState(
                        onRetry: () => setState(
                          () => _answers = _session.asks.answers(widget.askId),
                        ),
                      );
                    }
                    if (!answersSnap.hasData) {
                      return const Center(child: CupertinoActivityIndicator());
                    }
                    final answers = answersSnap.data!;
                    final waiting = [
                      for (final id in ask.members)
                        if (!answers.any((a) => a.ownerId == id))
                          _session.userOr(id).firstName,
                    ].where((n) => n.isNotEmpty).toList();
                    return ListView(
                      padding: EdgeInsets.fromLTRB(
                        Space.gutter,
                        Space.sm,
                        Space.gutter,
                        MediaQuery.of(context).padding.bottom + Space.xxl,
                      ),
                      children: [
                        Text(ask.text, style: context.text.display),
                        const SizedBox(height: Space.xs),
                        Text(
                          'Only you can read these answers.'.tr,
                          style: context.text.caption,
                        ),
                        const SizedBox(height: Space.lg),
                        if (answers.isEmpty)
                          Text(
                            'No answers yet.'.tr,
                            style: context.text.body.copyWith(color: c.inkSoft),
                          ),
                        for (final (i, answer) in answers.indexed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Space.sm),
                            child:
                                Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(Space.md),
                                      decoration: BoxDecoration(
                                        color: c.paperTint(
                                          Mood.plain,
                                          answer.ownerId,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          Radii.lg,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Avatar(
                                                url: _session
                                                    .userOr(
                                                      answer.ownerId,
                                                      image: answer.ownerImage,
                                                    )
                                                    .image,
                                                name: answer.ownerName,
                                                size: 32,
                                              ),
                                              const SizedBox(width: Space.xs),
                                              Expanded(
                                                child: Text(
                                                  _session
                                                      .userOr(
                                                        answer.ownerId,
                                                        name: answer.ownerName,
                                                      )
                                                      .username,
                                                  style: context.text.label,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: Space.sm),
                                          ContentText(
                                            answer.text,
                                            style: context.text.noteBody
                                                .copyWith(fontSize: 17),
                                          ),
                                        ],
                                      ),
                                    )
                                    .animate(delay: (i.clamp(0, 8) * 100).ms)
                                    .fadeIn(duration: Motion.slow)
                                    .slideY(begin: 0.06, curve: Motion.ease),
                          ),
                        if (waiting.isNotEmpty) ...[
                          const SizedBox(height: Space.sm),
                          Text(
                            '${'Still to answer'.tr}: ${waiting.join(', ')}',
                            style: context.text.caption,
                          ),
                        ],
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}
