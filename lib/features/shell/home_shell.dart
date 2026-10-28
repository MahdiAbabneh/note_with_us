import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/birthdays.dart';
import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/prompts.dart';
import '../../core/reminders.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import '../compose/compose_screen.dart';
import '../journal/journal_screen.dart';
import '../messages/messages_screen.dart';
import '../profile/me_screen.dart';
import '../today/today_screen.dart';
import 'guest_tab.dart';

/// Home with four tabs and a compose button. Guests get the same shell,
/// with Discover on Today and the other tabs inviting them to join.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  StreamSubscription<List<Capsule>>? _capsules;
  StreamSubscription<List<GroupCapsule>>? _groupCapsules;
  List<Capsule> _received = const [];
  List<GroupCapsule> _groups = const [];
  final _guest = Session.instance.isGuest;

  @override
  void initState() {
    super.initState();
    if (_guest) return;
    final reminders = Reminders.instance;
    reminders.openRequest.addListener(_handleNotificationTap);
    // A tap that launched the app arrives before this widget exists.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _handleNotificationTap(),
    );
    final session = Session.instance;
    _capsules = session.capsules.received(session.uid).listen((list) {
      _received = list;
      _syncCapsuleAlerts();
    }, onError: (_) {});
    session.addListener(_syncBirthdayAlerts);
    _syncBirthdayAlerts();
    _groupCapsules = session.groupCapsules.mine(session.uid).listen((list) {
      _groups = list;
      _syncCapsuleAlerts();
    }, onError: (_) {});
  }

  /// A reminder at 9:00 the day before each circle member's birthday.
  void _syncBirthdayAlerts() {
    final session = Session.instance;
    final now = DateTime.now();
    Reminders.instance.syncBirthdays([
      for (final person in session.circleMembers)
        if (parseBirthDate(person.dateOfBirth) case final birth?)
          (
            id: person.uid,
            at: reminderTimeFor(birth, now),
            title: '{name}’s birthday is tomorrow 🎂'.tr.replaceAll(
              '{name}',
              person.firstName,
            ),
            body: 'Send a morning note so it’s there when they wake up.'.tr,
          ),
    ]);
  }

  /// One alert per capsule that is still sealed: capsules sent to you
  /// (and morning notes) plus the circle capsules you are part of. The
  /// reminders keep only what is passed here, so both lists go together.
  void _syncCapsuleAlerts() {
    Reminders.instance.syncCapsules([
      for (final c in _received.where((c) => !c.opened))
        (
          id: c.id,
          unlockAt: c.unlockAt,
          title: c.isMorningNote
              ? 'A morning note is waiting ☀️'.tr
              : 'A time capsule is ready to open'.tr,
          body: c.isToSelf
              ? 'A note from your past self is waiting.'.tr
              : 'From {name}'.tr.replaceAll('{name}', c.ownerName),
        ),
      for (final g in _groups)
        (
          id: g.id,
          unlockAt: g.unlockAt,
          title: 'A circle capsule is ready to open'.tr,
          body: g.title,
        ),
    ]);
  }

  @override
  void dispose() {
    Reminders.instance.openRequest.removeListener(_handleNotificationTap);
    _capsules?.cancel();
    _groupCapsules?.cancel();
    Session.instance.removeListener(_syncBirthdayAlerts);
    super.dispose();
  }

  void _handleNotificationTap() {
    final request = Reminders.instance.openRequest.value;
    if (request == null || !mounted) return;
    Reminders.instance.openRequest.value = null;
    switch (request) {
      case ReminderTarget.write:
        setState(() => _tab = 0);
        openComposer(
          context,
          prompt: promptFor(DateTime.now()),
          target: ComposeTarget.private,
        );
      case ReminderTarget.capsules:
        memoriesTab.value = 1;
        setState(() => _tab = 1);
      case ReminderTarget.today:
        setState(() => _tab = 0);
    }
  }

  void _select(int index) {
    if (index == _tab) return;
    HapticFeedback.selectionClick();
    setState(() => _tab = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      // Tabs start below the status bar so scrolled content and the
      // pinned feed switcher never slide underneath the clock.
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: _guest
              ? [
                  const TodayScreen(),
                  GuestTab(
                    overline: 'Just for you'.tr,
                    title: 'Memories'.tr,
                    emoji: '📔',
                    headline: 'Your private journal'.tr,
                    points: [
                      ('🔒', 'Notes only you can see'.tr),
                      ('⏳', 'Time capsules that open in the future'.tr),
                      ('🌱', 'A gentle look back at your week and moods'.tr),
                    ],
                  ),
                  GuestTab(
                    overline: 'Stay close'.tr,
                    title: 'Messages'.tr,
                    emoji: '💬',
                    headline: 'Talk with your circle'.tr,
                    points: [
                      ('🫶', 'Invite the people you love to your circle'.tr),
                      ('💬', 'Private messages, only with your circle'.tr),
                      ('🎂', 'Send birthday capsules to each other'.tr),
                    ],
                  ),
                  const GuestMeScreen(),
                ]
              : const [
                  TodayScreen(),
                  JournalScreen(),
                  MessagesScreen(),
                  MeScreen(),
                ],
        ),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: Session.instance,
        builder: (context, _) => _FloatingNav(
          index: _tab,
          onSelect: _select,
          onCompose: () => openComposer(context),
          // Messages gets a dot while circle requests are waiting.
          badges: {if (Session.instance.incomingRequests.isNotEmpty) 2},
        ),
      ),
    );
  }
}

class _FloatingNav extends StatelessWidget {
  const _FloatingNav({
    required this.index,
    required this.onSelect,
    required this.onCompose,
    this.badges = const {},
  });

  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onCompose;

  /// Tab indexes that show a small dot.
  final Set<int> badges;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const tabs = [
      (CupertinoIcons.house, CupertinoIcons.house_fill, 'Today'),
      (CupertinoIcons.book, CupertinoIcons.book_fill, 'Memories'),
      (
        CupertinoIcons.chat_bubble_2,
        CupertinoIcons.chat_bubble_2_fill,
        'Messages',
      ),
      (
        CupertinoIcons.person_crop_circle,
        CupertinoIcons.person_crop_circle_fill,
        'Me',
      ),
    ];
    Widget tab(int i) {
      final (icon, active, label) = tabs[i];
      final selected = i == index;
      return Expanded(
        child: Pressable(
          scale: 0.88,
          haptic: false,
          semanticLabel: label.tr,
          onTap: () => onSelect(i),
          child: SizedBox(
            height: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedSwitcher(
                      duration: Motion.base,
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        selected ? active : icon,
                        key: ValueKey(selected),
                        size: 24,
                        color: selected ? c.ink : c.muted,
                      ),
                    ),
                    if (badges.contains(i))
                      PositionedDirectional(
                        top: -2,
                        end: -4,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: c.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.raised, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: Motion.base,
                  curve: Motion.ease,
                  width: selected ? 16 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: Space.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Radii.pill),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: Space.xs),
              decoration: BoxDecoration(
                color: c.raised.withValues(alpha: c.isDark ? 0.78 : 0.82),
                borderRadius: BorderRadius.circular(Radii.pill),
                border: Border.all(color: c.line.withValues(alpha: 0.8)),
              ),
              child: Row(
                children: [
                  tab(0),
                  tab(1),
                  Pressable(
                    scale: 0.9,
                    semanticLabel: 'New note'.tr,
                    onTap: onCompose,
                    child: Container(
                      width: 52,
                      height: 52,
                      margin: const EdgeInsets.symmetric(horizontal: Space.xs),
                      decoration: BoxDecoration(
                        color: c.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.add,
                        color: c.onAccent,
                        size: 26,
                      ),
                    ),
                  ),
                  tab(2),
                  tab(3),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().slideY(begin: 1, curve: Motion.ease, duration: Motion.slow);
  }
}
