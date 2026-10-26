import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import '../capsules/capsule_card.dart';
import '../compose/compose_screen.dart';
import '../notes/note_card.dart';

/// Which Memories segment is showing (0 notes, 1 capsules, 2 favorites); lets a
/// capsule notification open the capsules list directly.
final ValueNotifier<int> memoriesTab = ValueNotifier(0);

/// "Memories": the private journal and time capsules.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  static const _pageSize = 40;

  final _session = Session.instance;
  final _search = TextEditingController();
  late Stream<List<Note>> _notes;
  late Stream<List<Capsule>> _received;
  late Stream<List<Capsule>> _sent;
  int _limit = _pageSize;
  int get _tab => memoriesTab.value;
  bool _searching = false;
  String _query = '';
  Mood? _mood;
  bool _archived = false;

  @override
  void initState() {
    super.initState();
    _subscribe();
    memoriesTab.addListener(_onTab);
  }

  @override
  void dispose() {
    memoriesTab.removeListener(_onTab);
    _search.dispose();
    super.dispose();
  }

  void _onTab() => setState(() {});

  void _subscribe() {
    _notes = _session.notes.journal(_session.uid, limit: _limit);
    _received = _session.capsules.received(_session.uid);
    _sent = _session.capsules.sent(_session.uid);
  }

  void _retry() => setState(_subscribe);

  void _loadMore() => setState(() {
    _limit += _pageSize;
    _notes = _session.notes.journal(_session.uid, limit: _limit);
  });

  void _toggleSearch() => setState(() {
    _searching = !_searching;
    if (!_searching) {
      _search.clear();
      _query = '';
    }
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageHeader(
          overline: 'Just for you'.tr,
          title: 'Memories'.tr,
          actions: [
            if (_tab == 0)
              CircleIconButton(
                icon: _searching ? CupertinoIcons.xmark : CupertinoIcons.search,
                semanticLabel: 'Search'.tr,
                onPressed: _toggleSearch,
              ),
            CircleIconButton(
              icon: CupertinoIcons.hourglass,
              semanticLabel: 'New capsule'.tr,
              onPressed: () =>
                  openComposer(context, target: ComposeTarget.capsule),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            0,
            Space.gutter,
            Space.xs,
          ),
          child: SegmentedPills(
            labels: ['Notes'.tr, 'Capsules'.tr, 'Favorites'.tr],
            index: _tab,
            onChanged: (i) => memoriesTab.value = i,
          ),
        ),
        if (_tab == 0) ...[
          AnimatedSize(
            duration: Motion.base,
            curve: Motion.ease,
            child: _searching
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.gutter,
                      Space.xs,
                      Space.gutter,
                      0,
                    ),
                    child: SearchField(
                      controller: _search,
                      autofocus: true,
                      hint: 'Search your notes'.tr,
                      onChanged: (v) =>
                          setState(() => _query = v.trim().toLowerCase()),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          _MoodFilter(
            value: _mood,
            onChanged: (m) => setState(() => _mood = m),
            archived: _archived,
            onArchived: (a) => setState(() => _archived = a),
          ),
        ],
        Expanded(
          child: AnimatedSwitcher(
            duration: Motion.base,
            child: _tab == 2
                ? const _FavoritesList(key: ValueKey('favorites'))
                : _tab == 0
                ? _NotesList(
                    key: ValueKey('notes-$_archived'),
                    stream: _notes,
                    query: _query,
                    mood: _mood,
                    archived: _archived,
                    limit: _limit,
                    onLoadMore: _loadMore,
                    onRetry: _retry,
                  )
                : _CapsuleList(
                    key: const ValueKey('capsules'),
                    received: _received,
                    sent: _sent,
                    onRetry: _retry,
                  ),
          ),
        ),
      ],
    );
  }
}

class _MoodFilter extends StatelessWidget {
  const _MoodFilter({
    required this.value,
    required this.onChanged,
    required this.archived,
    required this.onArchived,
  });

  final Mood? value;
  final ValueChanged<Mood?> onChanged;

  /// Showing archived notes instead of the journal.
  final bool archived;
  final ValueChanged<bool> onArchived;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget chip(
      String label,
      bool selected,
      VoidCallback onTap, {
      Mood? mood,
    }) => Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: Motion.base,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? (mood == null ? c.ink : c.moodTint(mood))
                : const Color(0x00000000),
            borderRadius: BorderRadius.circular(Radii.pill),
            border: Border.all(
              color: selected
                  ? (mood == null ? c.ink : c.moodInk(mood))
                  : c.line,
            ),
          ),
          child: Text(
            label,
            style: context.text.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: selected && mood == null ? c.canvas : c.ink,
            ),
          ),
        ),
      ),
    );

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          Space.xs,
          Space.gutter,
          Space.xxs,
        ),
        children: [
          chip('All'.tr, value == null && !archived, () {
            onArchived(false);
            onChanged(null);
          }),
          for (final mood in Mood.values.where((m) => m != Mood.plain))
            chip(
              '${mood.emoji} ${mood.label.tr}',
              value == mood,
              () => onChanged(value == mood ? null : mood),
              mood: mood,
            ),
          chip('📦 ${'Archived'.tr}', archived, () => onArchived(!archived)),
        ],
      ),
    );
  }
}

class _NotesList extends StatelessWidget {
  const _NotesList({
    super.key,
    required this.stream,
    required this.query,
    required this.mood,
    required this.archived,
    required this.limit,
    required this.onLoadMore,
    required this.onRetry,
  });

  final Stream<List<Note>> stream;
  final String query;
  final Mood? mood;
  final bool archived;
  final int limit;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Note>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) return ErrorState(onRetry: onRetry);
        if (!snap.hasData) {
          return ListView(
            padding: const EdgeInsets.only(top: Space.md),
            children: List.generate(3, (_) => const NoteSkeleton()),
          );
        }
        final all = snap.data!;
        if (all.isEmpty) {
          return EmptyState(
            emoji: '📔',
            title: 'Your journal is empty'.tr,
            message: 'Private notes live here. Only you can ever read them.'.tr,
            actionLabel: 'Write a private note'.tr,
            onAction: () =>
                openComposer(context, target: ComposeTarget.private),
          );
        }
        final filtered = all
            .where((n) => n.archived == archived)
            .where((n) => mood == null || n.mood == mood)
            .where(
              (n) =>
                  query.isEmpty ||
                  n.text.toLowerCase().contains(query) ||
                  n.prompt.toLowerCase().contains(query),
            )
            .toList();
        if (filtered.isEmpty && archived && query.isEmpty && mood == null) {
          return EmptyState(
            emoji: '📦',
            title: 'No archived notes'.tr,
            message:
                'Archive a note from its ••• menu to tuck it away here.'.tr,
          );
        }
        if (filtered.isEmpty) {
          return EmptyState(
            emoji: '🔎',
            title: 'No matching notes'.tr,
            message: 'Try another word or mood.'.tr,
          );
        }
        final pinned = filtered.where((n) => n.pinned).toList();
        final rest = filtered.where((n) => !n.pinned).toList();

        Widget card(Note note, int i) => Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            0,
            Space.gutter,
            Space.sm,
          ),
          child: NoteCard(note: note)
              .animate(delay: (i.clamp(0, 6) * 40).ms)
              .fadeIn(duration: Motion.slow)
              .slideY(begin: 0.05),
        );

        final items = <Widget>[];
        if (pinned.isNotEmpty) {
          items.add(SectionLabel('Pinned'.tr));
          for (var i = 0; i < pinned.length; i++) {
            items.add(card(pinned[i], i));
          }
        }
        String? month;
        for (var i = 0; i < rest.length; i++) {
          final label = monthYear(rest[i].time);
          if (label != month) {
            month = label;
            items.add(SectionLabel(label));
          }
          items.add(card(rest[i], i));
        }
        // A full page means there may be older notes to fetch.
        if (all.length >= limit) {
          items.add(
            Padding(
              padding: const EdgeInsets.all(Space.gutter),
              child: NwuButton(
                label: 'Show older notes'.tr,
                tone: ButtonTone.outline,
                onPressed: onLoadMore,
              ),
            ),
          );
        }
        return ListView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 110,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: items,
        );
      },
    );
  }
}

class _CapsuleList extends StatelessWidget {
  const _CapsuleList({
    super.key,
    required this.received,
    required this.sent,
    required this.onRetry,
  });

  final Stream<List<Capsule>> received;
  final Stream<List<Capsule>> sent;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Capsule>>(
      stream: received,
      builder: (context, receivedSnap) => StreamBuilder<List<Capsule>>(
        stream: sent,
        builder: (context, sentSnap) {
          if (receivedSnap.hasError || sentSnap.hasError) {
            return ErrorState(onRetry: onRetry);
          }
          if (!receivedSnap.hasData || !sentSnap.hasData) {
            return ListView(
              padding: const EdgeInsets.only(top: Space.md),
              children: List.generate(2, (_) => const NoteSkeleton()),
            );
          }
          final inbox = receivedSnap.data!;
          final outbox = sentSnap.data!;
          if (inbox.isEmpty && outbox.isEmpty) {
            return EmptyState(
              emoji: '⏳',
              title: 'Write to the future'.tr,
              message:
                  'Seal a note for yourself or someone in your circle. It opens on the day you choose.'
                      .tr,
              actionLabel: 'Seal a capsule'.tr,
              onAction: () =>
                  openComposer(context, target: ComposeTarget.capsule),
            );
          }
          final ready = inbox.where((c) => c.isUnlocked && !c.opened).toList();
          final waiting = inbox.where((c) => !c.isUnlocked).toList();
          final opened = inbox.where((c) => c.opened).toList()
            ..sort((a, b) => b.unlockAt.compareTo(a.unlockAt));

          Widget section(String title, List<Capsule> list) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(title),
              for (var i = 0; i < list.length; i++)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.gutter,
                    0,
                    Space.gutter,
                    Space.sm,
                  ),
                  child: CapsuleCard(
                    capsule: list[i],
                  ).animate(delay: (i * 40).ms).fadeIn().slideY(begin: 0.05),
                ),
            ],
          );

          return ListView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 110,
            ),
            children: [
              if (ready.isNotEmpty) section('Ready to open'.tr, ready),
              if (waiting.isNotEmpty) section('Waiting for you'.tr, waiting),
              if (outbox.isNotEmpty) section('Sent by you'.tr, outbox),
              if (opened.isNotEmpty) section('Opened'.tr, opened),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.gutter,
                  Space.md,
                  Space.gutter,
                  0,
                ),
                child: Text(
                  'Press and hold a capsule to delete it.'.tr,
                  style: context.text.caption,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Notes the user saved from anywhere: their journal, circle or Discover.
class _FavoritesList extends StatefulWidget {
  const _FavoritesList({super.key});

  @override
  State<_FavoritesList> createState() => _FavoritesListState();
}

class _FavoritesListState extends State<_FavoritesList> {
  int _attempt = 0;

  @override
  Widget build(BuildContext context) {
    final session = Session.instance;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final refs = session.favorites;
        if (refs.isEmpty) {
          return EmptyState(
            emoji: '⭐',
            title: 'No favorites yet'.tr,
            message:
                'Tap ••• on any note and choose Add to favorites to keep it here.'
                    .tr,
          );
        }
        return FutureBuilder<List<Note>>(
          // Re-fetch only when the set of favorites changes.
          key: ValueKey('$_attempt|${refs.map((r) => r.key).join('|')}'),
          future: session.notes.resolve(refs),
          builder: (context, snap) {
            if (snap.hasError) {
              return ErrorState(onRetry: () => setState(() => _attempt++));
            }
            if (!snap.hasData) {
              return ListView(
                padding: const EdgeInsets.only(top: Space.md),
                children: List.generate(2, (_) => const NoteSkeleton()),
              );
            }
            final notes = snap.data!
                .where((n) => session.isVisible(n.ownerId))
                .toList();
            if (notes.isEmpty) {
              return EmptyState(
                emoji: '⭐',
                title: 'No favorites yet'.tr,
                message:
                    'Notes you saved were deleted or are no longer shared with you.'
                        .tr,
              );
            }
            return ListView(
              padding: EdgeInsets.only(
                top: Space.md,
                bottom: MediaQuery.of(context).padding.bottom + 110,
              ),
              children: [
                for (final (i, note) in notes.indexed)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.gutter,
                      0,
                      Space.gutter,
                      Space.sm,
                    ),
                    child: NoteCard(note: note)
                        .animate(delay: (i.clamp(0, 6) * 40).ms)
                        .fadeIn(duration: Motion.slow),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
