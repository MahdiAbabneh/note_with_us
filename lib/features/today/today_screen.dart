import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/drafts.dart';
import '../../core/format.dart';
import '../../core/insights.dart';
import '../../core/l10n.dart';
import '../../core/prompts.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import '../auth/join_sheet.dart';
import '../capsules/capsule_card.dart';
import '../compose/compose_screen.dart';
import '../insights/your_week_screen.dart';
import '../messages/people_screen.dart';
import '../notes/note_card.dart';

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
  late Stream<List<Capsule>> _capsules;
  late Stream<List<Note>> _journal;
  late Stream<List<Note>> _mine;

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
      _circle = _journal = _mine = const Stream.empty();
      _capsules = const Stream.empty();
      return;
    }
    _circle = _session.notes.circleFeed(_session.uid);
    _capsules = _session.capsules.received(_session.uid);
    _journal = _session.notes.journal(_session.uid, limit: 200);
    _mine = _session.notes.mine(_session.uid);
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
      ]),
      builder: (context, _) => CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          if (_session.isGuest) const SliverToBoxAdapter(child: _GuestBanner()),
          const SliverToBoxAdapter(child: _PromptCard()),
          const SliverToBoxAdapter(child: _MoodRow()),
          SliverToBoxAdapter(child: _WeekCard(stream: _mine)),
          const SliverToBoxAdapter(child: _DraftCard()),
          SliverToBoxAdapter(child: _CapsuleSection(stream: _capsules)),
          SliverToBoxAdapter(child: _Memories(stream: _journal)),
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
                onTap: () => openComposer(
                  context,
                  target: ComposeTarget.private,
                  mood: mood,
                ),
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
        final all = snap.data ?? const <Capsule>[];
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

/// A one-line glance at the week; opens the full "Your week" screen.
class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.stream});

  final Stream<List<Note>> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Note>>(
      stream: stream,
      builder: (context, snap) {
        final notes = snap.data;
        if (notes == null || notes.isEmpty) return const SizedBox.shrink();
        final c = context.colors;
        final week = WeekInsights.from(notes, DateTime.now());
        final line = week.streak >= 2
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
      },
    );
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
        final memories = journal
            .where(
              (n) =>
                  n.time.month == now.month &&
                  n.time.day == now.day &&
                  n.time.year < now.year,
            )
            .toList();
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
                itemBuilder: (context, i) => _MemoryCard(note: memories[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final years = DateTime.now().year - note.time.year;
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
          Text(
            (years == 1 ? '1 year ago' : '{n} years ago').tr.replaceAll(
              '{n}',
              '$years',
            ),
            style: context.text.overline.copyWith(color: c.accent),
          ),
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
        final notes = snap.data!
            .where((n) => session.isVisible(n.ownerId))
            .toList();
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
