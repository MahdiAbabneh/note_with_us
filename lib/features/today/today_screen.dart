import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/birthdays.dart';
import '../../core/drafts.dart';
import '../../core/format.dart';
import '../../core/insights.dart';
import '../../core/l10n.dart';
import '../../core/prompts.dart';
import '../../core/reminders.dart';
import '../../core/settings.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import '../auth/join_sheet.dart';
import '../capsules/capsule_card.dart';
import '../compose/compose_screen.dart';
import '../insights/your_week_screen.dart';
import '../messages/people_screen.dart';
import '../capsules/morning_note_sheet.dart';
import '../comfort/comfort_sheet.dart';
import '../gratitude/gratitude_screen.dart';
import '../islamic/occasion_card.dart';
import '../messages/chat_screen.dart';
import '../notes/note_card.dart';
import '../together/ask_circle_screen.dart';
import '../together/group_capsules_screen.dart';
import '../together/notebooks_screen.dart';

/// Home tab: a quick mood check-in, anything waiting for you, then what
/// your circle shared.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final _session = Session.instance;
  late Stream<List<Note>> _everyone;
  late Stream<List<Note>> _circle;

  /// The same circle notes for the circle question card. Kept separate from
  /// [_circle]: a Firestore stream doesn't replay its last snapshot, so the
  /// feed, subscribing later while the card still listens, would wait
  /// forever on a shared one.
  late Stream<List<Note>> _circleForQuestion;
  late Stream<List<Capsule>> _capsules;
  late Stream<List<Note>> _journal;
  late Stream<List<Note>> _mine;
  late Stream<List<GroupCapsule>> _groups;
  late Stream<List<SharedNotebook>> _notebooks;
  late Stream<List<CircleAsk>> _asksForMe;

  /// 0 = Discover (shown first, and the default), 1 = My circle.
  int _feed = 0;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  /// (Re)creates the live queries; also used by "Try again".
  void _subscribe() {
    _everyone = _session.notes.everyone();
    if (_session.isGuest) {
      // Guests only see public notes; nothing of their own exists yet.
      _circle = _circleForQuestion = _journal = _mine = const Stream.empty();
      _capsules = const Stream.empty();
      _groups = const Stream.empty();
      _notebooks = const Stream.empty();
      _asksForMe = const Stream.empty();
      return;
    }
    _circle = _session.notes.circleFeed(_session.uid);
    _circleForQuestion = _session.notes.circleFeed(_session.uid);
    _capsules = _session.capsules.received(_session.uid);
    _journal = _session.notes.journal(_session.uid, limit: 200);
    _mine = _session.notes.mine(_session.uid);
    _groups = _session.groupCapsules.mine(_session.uid);
    _notebooks = _session.notebooks.mine(_session.uid);
    _asksForMe = _session.asks.forMe(_session.uid);
  }

  void _retry() => setState(_subscribe);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom + 96;
    return ListenableBuilder(
      listenable: Listenable.merge([
        _session,
        DraftStore.instance,
        PromptState.instance,
        PastSelfState.instance,
        AppSettings.instance,
        Reminders.instance,
      ]),
      builder: (context, _) => CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        // Cards appear and disappear above each other (the circle ones once
        // the circle loads), so each has a key: without one a shifted card
        // is rebuilt and re-subscribes to its stream, which crashes or
        // leaves it blank.
        slivers: [
          if (_session.isGuest)
            const SliverToBoxAdapter(
              key: ValueKey('guest'),
              child: _GuestBanner(),
            ),
          const SliverToBoxAdapter(
            key: ValueKey('occasion'),
            child: OccasionCard(),
          ),
          if (!ramadanPromptShows(DateTime.now()))
            const SliverToBoxAdapter(
              key: ValueKey('prompt'),
              child: _PromptCard(),
            ),
          if (!_session.isGuest && _session.circle.isNotEmpty)
            SliverToBoxAdapter(
              key: const ValueKey('circleQuestion'),
              child: _CircleQuestion(stream: _circleForQuestion),
            ),
          if (!_session.isGuest && _session.circle.isNotEmpty)
            const SliverToBoxAdapter(
              key: ValueKey('birthday'),
              child: _BirthdayCard(),
            ),
          if (!_session.isGuest && _session.circle.isNotEmpty)
            SliverToBoxAdapter(
              key: const ValueKey('together'),
              child: _TogetherCard(
                groups: _groups,
                notebooks: _notebooks,
                asks: _asksForMe,
              ),
            ),
          const SliverToBoxAdapter(key: ValueKey('moods'), child: _MoodRow()),
          SliverToBoxAdapter(
            key: const ValueKey('mine'),
            child: _MineSection(stream: _mine),
          ),
          if (!_session.isGuest)
            SliverToBoxAdapter(
              key: const ValueKey('jar'),
              child: _JarCard(stream: _journal),
            ),
          const SliverToBoxAdapter(key: ValueKey('draft'), child: _DraftCard()),
          SliverToBoxAdapter(
            key: const ValueKey('capsules'),
            child: _CapsuleSection(stream: _capsules),
          ),
          SliverToBoxAdapter(
            key: const ValueKey('memories'),
            child: _Memories(stream: _journal),
          ),
          if (!_session.isGuest)
            SliverToBoxAdapter(
              key: const ValueKey('pastSelf'),
              child: _PastSelfCard(stream: _journal),
            ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _FeedSwitcher(
              index: _feed,
              onChanged: (i) {
                if (i == 1 &&
                    needsAccount(context, 'Join to build your circle'.tr)) {
                  return;
                }
                setState(() => _feed = i);
              },
              background: context.colors.canvas,
            ),
          ),
          _FeedList(
            key: ValueKey('$_feed-${_circle.hashCode}'),
            stream: _feed == 1 ? _circle : _everyone,
            isCircle: _feed == 1,
            onRetry: _retry,
          ),
          SliverToBoxAdapter(child: SizedBox(height: bottomInset)),
        ],
      ),
    );
  }
}

/// Welcomes a guest and says what an account adds.
class _GuestBanner extends StatelessWidget {
  const _GuestBanner();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.md,
        Space.gutter,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: c.raised,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: c.line.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            const Text('👋', style: TextStyle(fontSize: 26)),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You’re looking around'.tr, style: context.text.label),
                  const SizedBox(height: 2),
                  Text(
                    'Read what people share. Join to write and react.'.tr,
                    style: context.text.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.xs),
            NwuButton(
              label: 'Join'.tr,
              tone: ButtonTone.accent,
              compact: true,
              expand: false,
              onPressed: () => showJoinSheet(context),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: Motion.slow).slideY(begin: 0.05);
  }
}

/// Today's writing prompt as a slim, quiet card. Tapping writes a private
/// answer; once answered it shrinks to a single line, and it can be
/// hidden until tomorrow.
class _PromptCard extends StatelessWidget {
  const _PromptCard();

  @override
  Widget build(BuildContext context) {
    final state = PromptState.instance;
    if (state.hiddenToday) return const SizedBox.shrink();
    final c = context.colors;
    final prompt = state.today;
    void write() =>
        openComposer(context, prompt: prompt, target: ComposeTarget.private);

    final Widget child;
    if (state.answeredToday) {
      child = Pressable(
        key: const ValueKey('answered'),
        onTap: write,
        semanticLabel: 'You answered today’s prompt'.tr,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.sm,
          ),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.checkmark_seal_fill,
                size: 18,
                color: c.success,
              ),
              const SizedBox(width: Space.xs),
              Expanded(
                child: Text(
                  'You answered today’s prompt'.tr,
                  style: context.text.label.copyWith(color: c.inkSoft),
                ),
              ),
              Text(
                'Write more'.tr,
                style: context.text.caption.copyWith(color: c.accent),
              ),
            ],
          ),
        ),
      );
    } else {
      child = Pressable(
        key: const ValueKey('open'),
        scale: 0.98,
        onTap: write,
        semanticLabel: '${'Today’s prompt'.tr}: $prompt',
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(
            Space.md,
            Space.md,
            Space.xs,
            Space.md,
          ),
          decoration: BoxDecoration(
            color: c.accentSoft,
            borderRadius: BorderRadius.circular(Radii.lg),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.raised,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '✦',
                  style: TextStyle(fontSize: 16, color: c.accent),
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today’s prompt'.tr.toUpperCase(),
                      style: context.text.overline.copyWith(color: c.accent),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prompt,
                      style: context.text.noteBody.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: Space.xs),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.lock_fill,
                          size: 11,
                          color: c.inkSoft,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tap to write privately'.tr,
                          style: context.text.caption.copyWith(
                            color: c.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              CircleIconButton(
                icon: CupertinoIcons.xmark,
                size: 32,
                filled: false,
                iconColor: c.muted,
                semanticLabel: 'Hide for today'.tr,
                onPressed: state.hideForToday,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.md,
        Space.gutter,
        0,
      ),
      child: AnimatedSwitcher(
        duration: Motion.base,
        switchInCurve: Motion.ease,
        child: child,
      ),
    ).animate().fadeIn(duration: Motion.slow).slideY(begin: 0.05);
  }
}

/// Today's question, answered together with your circle. Friends' answers
/// stay hidden until you have answered yours.
class _CircleQuestion extends StatelessWidget {
  const _CircleQuestion({required this.stream});

  final Stream<List<Note>> stream;

  @override
  Widget build(BuildContext context) {
    final session = Session.instance;
    return StreamBuilder<List<Note>>(
      stream: stream,
      builder: (context, snap) {
        final notes = (snap.data ?? const <Note>[]).where(
          (n) => session.isVisible(n.ownerId),
        );
        final question = circleQuestionFor(notes, session.uid, DateTime.now());
        final c = context.colors;
        final prompt = PromptState.instance.today;
        void answer() =>
            openComposer(context, prompt: prompt, target: ComposeTarget.circle);

        final waiting = question.others.length;
        final String status;
        if (question.answered) {
          status = waiting == 0
              ? 'You answered. Waiting for your circle.'.tr
              : (waiting == 1 ? '1 friend answered' : '{n} friends answered').tr
                    .replaceAll('{n}', '$waiting');
        } else {
          status = waiting == 0
              ? 'Be the first to answer.'.tr
              : (waiting == 1
                        ? '1 friend answered. Answer to see it.'
                        : '{n} friends answered. Answer to see them.')
                    .tr
                    .replaceAll('{n}', '$waiting');
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            Space.md,
            Space.gutter,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Pressable(
                onTap: question.answered ? null : answer,
                semanticLabel: '${'Circle question'.tr}: $prompt',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Space.md),
                  decoration: BoxDecoration(
                    color: c.raised,
                    borderRadius: BorderRadius.circular(Radii.lg),
                    border: Border.all(color: c.accent.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.circle_grid_hex_fill,
                            size: 14,
                            color: c.accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Circle question'.tr.toUpperCase(),
                            style: context.text.overline.copyWith(
                              color: c.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        prompt,
                        style: context.text.noteBody.copyWith(fontSize: 17),
                      ),
                      const SizedBox(height: Space.sm),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              status,
                              style: context.text.caption.copyWith(
                                color: c.inkSoft,
                              ),
                            ),
                          ),
                          if (!question.answered)
                            NwuButton(
                              label: 'Answer'.tr,
                              tone: ButtonTone.accent,
                              compact: true,
                              expand: false,
                              onPressed: answer,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (question.answered)
                for (final note in question.others.take(3))
                  Padding(
                    padding: const EdgeInsets.only(top: Space.sm),
                    child: NoteCard(note: note),
                  ),
            ],
          ),
        ).animate().fadeIn(duration: Motion.base);
      },
    );
  }
}

/// Friends in your circle with a birthday today or tomorrow, with one
/// tap to say something kind.
class _BirthdayCard extends StatelessWidget {
  const _BirthdayCard();

  @override
  Widget build(BuildContext context) {
    final session = Session.instance;
    final birthdays = upcomingBirthdays(
      session.circleMembers.where((u) => session.isVisible(u.uid)),
      DateTime.now(),
    ).take(2).toList();
    if (birthdays.isEmpty) return const SizedBox.shrink();
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.md,
        Space.gutter,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: c.accentSoft,
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: Column(
          children: [
            for (final (i, birthday) in birthdays.indexed) ...[
              if (i > 0) const SizedBox(height: Space.sm),
              Row(
                children: [
                  Avatar(
                    url: birthday.user.image,
                    name: birthday.user.username,
                    size: 40,
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Text(
                      (birthday.daysAway == 0
                              ? '{name}’s birthday is today 🎂'
                              : '{name}’s birthday is tomorrow 🎂')
                          .tr
                          .replaceAll('{name}', birthday.user.firstName),
                      style: context.text.label,
                    ),
                  ),
                  const SizedBox(width: Space.xs),
                  NwuButton(
                    label: birthday.daysAway == 0
                        ? 'Message'.tr
                        : 'Send a morning note'.tr,
                    tone: ButtonTone.accent,
                    compact: true,
                    expand: false,
                    onPressed: () => birthday.daysAway == 0
                        ? openChat(context, birthday.user)
                        : showMorningNoteSheet(context, birthday.user),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: Motion.base);
  }
}

/// A slim way into the gratitude jar, showing how full it is this month.
class _JarCard extends StatelessWidget {
  const _JarCard({required this.stream});

  final Stream<List<Note>> stream;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return StreamBuilder<List<Note>>(
      stream: stream,
      builder: (context, snap) {
        final now = DateTime.now();
        final beads = gratitudeItems(
          snap.data ?? const <Note>[],
          month: DateTime(now.year, now.month),
        ).length;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            Space.md,
            Space.gutter,
            0,
          ),
          child: Pressable(
            semanticLabel: 'Gratitude jar'.tr,
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute<void>(builder: (_) => const GratitudeScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.md,
                vertical: Space.sm,
              ),
              decoration: BoxDecoration(
                color: c.raised,
                borderRadius: BorderRadius.circular(Radii.lg),
                border: Border.all(color: c.line.withValues(alpha: 0.7)),
              ),
              child: Row(
                children: [
                  const Text('🫙', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gratitude jar'.tr, style: context.text.label),
                        Text(
                          beads == 0
                              ? 'Start filling it with what you are grateful for'
                                    .tr
                              : (beads == 1
                                        ? '1 bead this month'
                                        : '{n} beads this month')
                                    .tr
                                    .replaceAll('{n}', '$beads'),
                          style: context.text.caption,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? CupertinoIcons.chevron_left
                        : CupertinoIcons.chevron_right,
                    size: 16,
                    color: c.muted,
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: Motion.base);
      },
    );
  }
}

/// Two ways to write with others: circle capsules and shared notebooks.
class _TogetherCard extends StatelessWidget {
  const _TogetherCard({
    required this.groups,
    required this.notebooks,
    required this.asks,
  });

  final Stream<List<GroupCapsule>> groups;
  final Stream<List<SharedNotebook>> notebooks;
  final Stream<List<CircleAsk>> asks;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final uid = Session.instance.uid;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.md,
        Space.gutter,
        0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: c.raised,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: c.line.withValues(alpha: 0.7)),
        ),
        child: Column(
          children: [
            StreamBuilder<List<GroupCapsule>>(
              stream: groups,
              builder: (context, snap) {
                final all = (snap.data ?? const <GroupCapsule>[])
                    .where((g) => Session.instance.isVisible(g.ownerId))
                    .toList();
                final ready = all.where((g) => g.isUnlocked).length;
                final waiting = all.length - ready;
                final needLetter = all
                    .where((g) => !g.isUnlocked && !g.hasWritten(uid))
                    .length;
                final String subtitle;
                if (ready > 0) {
                  subtitle =
                      (ready == 1 ? '1 ready to open ✨' : '{n} ready to open ✨')
                          .tr
                          .replaceAll('{n}', '$ready');
                } else if (needLetter > 0) {
                  subtitle = 'Your letter is missing ✍️'.tr;
                } else if (waiting > 0) {
                  subtitle = (waiting == 1 ? '1 waiting' : '{n} waiting').tr
                      .replaceAll('{n}', '$waiting');
                } else {
                  subtitle = 'Everyone writes, all open together'.tr;
                }
                return _TogetherRow(
                  emoji: '🎆',
                  title: 'Circle capsules'.tr,
                  subtitle: subtitle,
                  highlight: ready > 0 || needLetter > 0,
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      builder: (_) => const GroupCapsulesScreen(),
                    ),
                  ),
                );
              },
            ),
            Container(height: 1, color: c.line),
            StreamBuilder<List<SharedNotebook>>(
              stream: notebooks,
              builder: (context, snap) {
                final all = snap.data ?? const <SharedNotebook>[];
                final myTurn = all.where((n) => n.isMyTurn(uid)).length;
                final String subtitle;
                if (myTurn > 0) {
                  subtitle =
                      (myTurn == 1
                              ? 'Your turn in 1 notebook ✍️'
                              : 'Your turn in {n} notebooks ✍️')
                          .tr
                          .replaceAll('{n}', '$myTurn');
                } else if (all.isNotEmpty) {
                  subtitle = 'Waiting for their page'.tr;
                } else {
                  subtitle = 'Take turns writing with one person'.tr;
                }
                return _TogetherRow(
                  emoji: '📖',
                  title: 'Shared notebooks'.tr,
                  subtitle: subtitle,
                  highlight: myTurn > 0,
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      builder: (_) => const NotebooksScreen(),
                    ),
                  ),
                );
              },
            ),
            Container(height: 1, color: c.line),
            StreamBuilder<List<CircleAsk>>(
              stream: asks,
              builder: (context, snap) {
                final waiting = (snap.data ?? const <CircleAsk>[])
                    .where(
                      (a) =>
                          !a.hasAnswered(uid) &&
                          Session.instance.isVisible(a.ownerId),
                    )
                    .length;
                final subtitle = waiting == 0
                    ? 'Ask a question, read answers only you see'.tr
                    : (waiting == 1
                              ? '1 question waiting for you'
                              : '{n} questions waiting for you')
                          .tr
                          .replaceAll('{n}', '$waiting');
                return _TogetherRow(
                  emoji: '💬',
                  title: 'Ask your circle'.tr,
                  subtitle: subtitle,
                  highlight: waiting > 0,
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      builder: (_) => const AskCircleScreen(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: Motion.base);
  }
}

class _TogetherRow extends StatelessWidget {
  const _TogetherRow({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.highlight,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final bool highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      scale: 0.99,
      semanticLabel: '$title. $subtitle',
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(Space.md),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.label),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: context.text.caption.copyWith(
                      color: highlight ? c.accent : c.inkSoft,
                      fontWeight: highlight ? FontWeight.w700 : null,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? CupertinoIcons.chevron_left
                  : CupertinoIcons.chevron_right,
              size: 16,
              color: c.muted,
            ),
          ],
        ),
      ),
    );
  }
}

/// One tap from "how do I feel" to a private note in that mood.
class _MoodRow extends StatelessWidget {
  const _MoodRow();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final moods = Mood.values.where((m) => m != Mood.plain).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('How are you feeling?'.tr),
        SizedBox(
          height: 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            itemCount: moods.length,
            separatorBuilder: (_, _) => const SizedBox(width: Space.xs),
            itemBuilder: (context, i) {
              final mood = moods[i];
              return Pressable(
                semanticLabel: mood.label.tr,
                onTap: () async {
                  // A hard day first gets something kind to read.
                  if (mood == Mood.blue && !Session.instance.isGuest) {
                    await showComfortSheet(context);
                    if (!context.mounted) return;
                  }
                  openComposer(
                    context,
                    target: ComposeTarget.private,
                    mood: mood,
                  );
                },
                child: Container(
                  width: 68,
                  decoration: BoxDecoration(
                    color: c.moodTint(mood),
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(mood.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(
                        mood.label.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.caption.copyWith(
                          color: c.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard();

  @override
  Widget build(BuildContext context) {
    final draft = DraftStore.instance.current;
    if (draft == null) return const SizedBox.shrink();
    final c = context.colors;
    final firstLine = draft.text.trim().split('\n').first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.lg,
        Space.gutter,
        0,
      ),
      child: Pressable(
        onTap: () => openComposer(context),
        child: Container(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: c.raised,
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.pencil_outline, color: c.accent, size: 20),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Continue your draft'.tr, style: context.text.label),
                    const SizedBox(height: 2),
                    ContentText(
                      firstLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.small,
                    ),
                  ],
                ),
              ),
              CircleIconButton(
                icon: CupertinoIcons.xmark,
                size: 36,
                filled: false,
                iconColor: c.muted,
                semanticLabel: 'Discard draft'.tr,
                onPressed: () => DraftStore.instance.clear(),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: Motion.base);
  }
}

/// Capsules that just unlocked come first; otherwise a single quiet line
/// about the next one.
class _CapsuleSection extends StatelessWidget {
  const _CapsuleSection({required this.stream});

  final Stream<List<Capsule>> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Capsule>>(
      stream: stream,
      builder: (context, snap) {
        final all = (snap.data ?? const <Capsule>[])
            .where((c) => !c.isSurpriseFor(Session.instance.uid))
            .toList();
        final ready = all.where((c) => c.isUnlocked && !c.opened).toList();
        final upcoming = all.where((c) => !c.isUnlocked).toList();
        if (ready.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(
                ready.length == 1
                    ? 'A capsule just unlocked'.tr
                    : '{n} capsules unlocked'.tr.replaceAll(
                        '{n}',
                        '${ready.length}',
                      ),
              ),
              for (final capsule in ready)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.gutter,
                    0,
                    Space.gutter,
                    Space.sm,
                  ),
                  child: CapsuleCard(capsule: capsule),
                ),
            ],
          ).animate().fadeIn(duration: Motion.slow);
        }
        if (upcoming.isEmpty) return const SizedBox.shrink();
        return _NextCapsule(capsule: upcoming.first, more: upcoming.length - 1);
      },
    );
  }
}

class _NextCapsule extends StatelessWidget {
  const _NextCapsule({required this.capsule, required this.more});

  final Capsule capsule;
  final int more;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.lg,
        Space.gutter,
        0,
      ),
      child: Pressable(
        onTap: () => showToast(context, countdown(capsule.unlockAt)),
        child: Container(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: c.moodTint(capsule.mood) == c.raised
                ? c.surface
                : c.moodTint(capsule.mood),
            borderRadius: BorderRadius.circular(Radii.lg),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.hourglass,
                  size: 18,
                  color: c.onAccent,
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      capsule.isToSelf
                          ? 'Your next capsule'.tr
                          : 'From {name}'.tr.replaceAll(
                              '{name}',
                              capsule.ownerName,
                            ),
                      style: context.text.label,
                    ),
                    Text(
                      more > 0
                          ? '${countdown(capsule.unlockAt)} · +$more'
                          : countdown(capsule.unlockAt),
                      style: context.text.caption,
                    ),
                  ],
                ),
              ),
              Icon(CupertinoIcons.lock_fill, size: 16, color: c.muted),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: Motion.base);
  }
}

/// Your own notes drive two cards, so they share one listener (the
/// stream can only be listened to once).
class _MineSection extends StatelessWidget {
  const _MineSection({required this.stream});

  final Stream<List<Note>> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Note>>(
      stream: stream,
      builder: (context, snap) {
        final notes = snap.data;
        if (notes == null || notes.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            _WeekCard(notes: notes),
            if (!Session.instance.isGuest) _ReminderNudge(notes: notes),
          ],
        );
      },
    );
  }
}

/// A one-line glance at the week; opens the full "Your week" screen.
class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.notes});

  final List<Note> notes;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final week = WeekInsights.from(notes, DateTime.now());
    // Gentle by design: invite today's note, never count a loss.
    final line = week.streak >= 2 && !week.wroteToday
        ? '🌱 ${'Keep your {n}-day rhythm going today'.tr.replaceAll('{n}', '${week.streak}')}'
        : week.streak >= 2
        ? '🌱 ${'{n} days in a row'.tr.replaceAll('{n}', '${week.streak}')}'
        : '{n} of 7 days'.tr.replaceAll('{n}', '${week.daysWritten}');
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.lg,
        Space.gutter,
        0,
      ),
      child: Pressable(
        semanticLabel: 'Your week'.tr,
        onTap: () => Navigator.of(context).push(
          CupertinoPageRoute<void>(builder: (_) => const YourWeekScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            Space.md,
            Space.sm,
            Space.sm,
            Space.sm,
          ),
          decoration: BoxDecoration(
            color: c.raised,
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(color: c.line.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your week'.tr, style: context.text.label),
                  const SizedBox(height: 2),
                  Text(line, style: context.text.caption),
                ],
              ),
              const SizedBox(width: Space.md),
              Expanded(child: WeekStrip(days: week.days)),
              const SizedBox(width: Space.xs),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? CupertinoIcons.chevron_left
                    : CupertinoIcons.chevron_right,
                size: 16,
                color: c.muted,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: Motion.base);
  }
}

class _NoteOfDayCard extends StatelessWidget {
  const _NoteOfDayCard({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: c.paperTint(note.mood, note.colorSeed),
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${note.mood == Mood.plain ? '📔' : note.mood.emoji}  ${fullDate(note.time)}',
            style: context.text.caption.copyWith(color: c.inkSoft),
          ),
          const SizedBox(height: Space.xs),
          ContentText(
            note.text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: context.text.noteBody.copyWith(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _Memories extends StatelessWidget {
  const _Memories({required this.stream});

  final Stream<List<Note>> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Note>>(
      stream: stream,
      builder: (context, snap) {
        final now = DateTime.now();
        final journal = (snap.data ?? const <Note>[])
            .where((n) => !n.archived)
            .toList();
        final memories = memoriesFor(journal, now);
        if (memories.isEmpty) {
          // No same-date memory: resurface one older note instead.
          final pick = noteOfTheDay(journal, now);
          if (pick == null) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel('Note of the day'.tr),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                child: _NoteOfDayCard(note: pick),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel('On this day'.tr),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                itemCount: memories.length,
                separatorBuilder: (_, _) => const SizedBox(width: Space.sm),
                itemBuilder: (context, i) => _MemoryCard(memory: memories[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// An old journal note brought back with a question: "do you still feel
/// this way?". One at a time, and only until it is answered or put off.
class _PastSelfCard extends StatelessWidget {
  const _PastSelfCard({required this.stream});

  final Stream<List<Note>> stream;

  @override
  Widget build(BuildContext context) {
    final state = PastSelfState.instance;
    return StreamBuilder<List<Note>>(
      stream: stream,
      builder: (context, snap) {
        final now = DateTime.now();
        final window = pastSelfWindow(now);
        if (state.isDone(window)) return const SizedBox.shrink();
        final note = pastSelfNote(snap.data ?? const <Note>[], now);
        if (note == null) return const SizedBox.shrink();
        final c = context.colors;
        final question = 'Do you still feel this way?'.tr;
        void reflect() {
          state.markDone(window);
          openComposer(
            context,
            prompt:
                '${'You wrote this on {date}.'.tr.replaceAll('{date}', fullDate(note.time))} $question',
            target: ComposeTarget.private,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel('A note from past you'.tr),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Space.md),
                decoration: BoxDecoration(
                  color: c.paperTint(note.mood, note.colorSeed),
                  borderRadius: BorderRadius.circular(Radii.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${note.mood == Mood.plain ? '📔' : note.mood.emoji}  ${fullDate(note.time)}',
                      style: context.text.caption.copyWith(color: c.inkSoft),
                    ),
                    const SizedBox(height: Space.xs),
                    ContentText(
                      note.text,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.noteBody.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: Space.sm),
                    Text(question, style: context.text.label),
                    const SizedBox(height: Space.sm),
                    Row(
                      children: [
                        NwuButton(
                          label: 'Reflect'.tr,
                          tone: ButtonTone.accent,
                          compact: true,
                          expand: false,
                          onPressed: reflect,
                        ),
                        const SizedBox(width: Space.xs),
                        NwuButton(
                          label: 'Not now'.tr,
                          tone: ButtonTone.ghost,
                          compact: true,
                          expand: false,
                          onPressed: () => state.markDone(window),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ).animate().fadeIn(duration: Motion.base);
      },
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.memory});

  final Memory memory;

  Note get note => memory.note;

  /// "1 month ago", "6 months ago", "1 year ago", "2 years ago".
  String get _label {
    final m = memory.months;
    if (m >= 12) {
      return (m == 12 ? '1 year ago' : '{n} years ago').tr.replaceAll(
        '{n}',
        '${m ~/ 12}',
      );
    }
    return (m == 1 ? '1 month ago' : '{n} months ago').tr.replaceAll(
      '{n}',
      '$m',
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 240,
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: c.paperTint(note.mood, note.colorSeed),
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_label, style: context.text.overline.copyWith(color: c.accent)),
          const SizedBox(height: Space.xs),
          Expanded(
            child: ContentText(
              note.text,
              overflow: TextOverflow.fade,
              style: context.text.noteBody.copyWith(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

/// Offered once, right after the first note: a daily reminder is the
/// single best nudge to keep writing. One tap turns it on at the default
/// time; it can be changed in Me.
class _ReminderNudge extends StatelessWidget {
  const _ReminderNudge({required this.notes});

  final List<Note> notes;

  @override
  Widget build(BuildContext context) {
    final reminders = Reminders.instance;
    if (reminders.dailyEnabled || reminders.nudgeDismissed) {
      return const SizedBox.shrink();
    }
    final c = context.colors;
    final t = reminders.time;
    final time = clockTime(DateTime(2000, 1, 1, t.hour, t.minute));
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.md,
        Space.gutter,
        0,
      ),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(
          Space.md,
          Space.md,
          Space.xs,
          Space.md,
        ),
        decoration: BoxDecoration(
          color: c.accentSoft,
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(CupertinoIcons.bell_fill, color: c.accent, size: 20),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Make it a habit'.tr, style: context.text.label),
                  const SizedBox(height: 2),
                  Text(
                    'A gentle reminder each evening helps you keep writing.'.tr,
                    style: context.text.caption.copyWith(color: c.inkSoft),
                  ),
                  const SizedBox(height: Space.sm),
                  NwuButton(
                    label: 'Remind me at {time}'.tr.replaceAll('{time}', time),
                    tone: ButtonTone.accent,
                    compact: true,
                    expand: false,
                    onPressed: () async {
                      final ok = await reminders.setDaily(true);
                      if (!context.mounted) return;
                      showToast(
                        context,
                        ok
                            ? 'Reminder on. Change the time in Me.'.tr
                            : 'Allow notifications in Settings'.tr,
                        error: !ok,
                      );
                    },
                  ),
                ],
              ),
            ),
            CircleIconButton(
              icon: CupertinoIcons.xmark,
              size: 32,
              filled: false,
              iconColor: c.muted,
              semanticLabel: 'Not now'.tr,
              onPressed: reminders.dismissNudge,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: Motion.base);
  }
}

class _FeedSwitcher extends SliverPersistentHeaderDelegate {
  _FeedSwitcher({
    required this.index,
    required this.onChanged,
    required this.background,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final Color background;

  @override
  double get minExtent => 76;
  @override
  double get maxExtent => 76;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    // A pinned header must paint exactly its declared extent.
    return Container(
      height: maxExtent,
      alignment: Alignment.bottomCenter,
      color: background,
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.lg,
        Space.gutter,
        Space.xs,
      ),
      child: SegmentedPills(
        labels: ['Discover'.tr, 'My circle'.tr],
        index: index,
        onChanged: onChanged,
      ),
    );
  }

  @override
  bool shouldRebuild(_FeedSwitcher old) =>
      old.index != index || old.background != background;
}

class _FeedList extends StatelessWidget {
  const _FeedList({
    super.key,
    required this.stream,
    required this.isCircle,
    required this.onRetry,
  });

  final Stream<List<Note>> stream;
  final bool isCircle;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final session = Session.instance;
    return StreamBuilder<List<Note>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return SliverToBoxAdapter(child: ErrorState(onRetry: onRetry));
        }
        if (!snap.hasData) {
          return SliverList.list(
            children: List.generate(3, (_) => const NoteSkeleton()),
          );
        }
        final visible = snap.data!
            .where((n) => session.isVisible(n.ownerId))
            // Discover only shows notes from the new app, which have a feeling.
            .where((n) => isCircle || !n.fromOldApp)
            .toList();
        // Friends' answers to today's circle question wait until you have
        // answered it yourself.
        final today = dayKey(DateTime.now());
        final hideAnswers =
            isCircle &&
            !circleQuestionFor(visible, session.uid, DateTime.now()).answered;
        final notes = hideAnswers
            ? visible
                  .where(
                    (n) => n.promptDay != today || n.ownerId == session.uid,
                  )
                  .toList()
            : visible;
        if (notes.isEmpty) {
          return SliverToBoxAdapter(
            child: isCircle
                ? EmptyState(
                    emoji: '🫶',
                    title: 'Your circle is quiet'.tr,
                    message:
                        'Add the people you love. Notes you share with your circle show up here.'
                            .tr,
                    actionLabel: 'Find people'.tr,
                    onAction: () => Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) => const PeopleScreen(),
                      ),
                    ),
                  )
                : EmptyState(
                    emoji: '🌍',
                    title: 'Nothing here yet'.tr,
                    message: 'Be the first to share a note with everyone.'.tr,
                  ),
          );
        }
        return SliverList.builder(
          itemCount: notes.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              Space.xs,
              Space.gutter,
              Space.xs,
            ),
            child: NoteCard(note: notes[i])
                .animate(delay: (i.clamp(0, 6) * 50).ms)
                .fadeIn(duration: Motion.slow)
                .slideY(begin: 0.06, curve: Motion.ease),
          ),
        );
      },
    );
  }
}
