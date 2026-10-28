import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/hijri.dart';
import '../../core/l10n.dart';
import '../../core/reminders.dart';
import '../../core/settings.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import '../auth/welcome_screen.dart';
import 'circle_screen.dart';
import 'edit_profile_screen.dart';
import 'games_screen.dart';

const _privacyUrl =
    'https://github.com/MahdiAbabneh/note-privacy/blob/main/prvacy-policy.md';
const _termsUrl =
    'https://github.com/MahdiAbabneh/Terms-of-Use/blob/main/Note%20app%20Terms%20of%20Use';

/// Your profile and settings.
class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  void _push(BuildContext context, Widget screen) => Navigator.of(
    context,
  ).push(CupertinoPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final session = Session.instance;
    final settings = AppSettings.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([session, settings, Reminders.instance]),
      builder: (context, _) {
        final me = session.me;
        return ListView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 110,
          ),
          children: [
            SafeArea(
              bottom: false,
              child: _Header(
                onEdit: () => _push(context, const EditProfileScreen()),
              ),
            ),
            SectionLabel('Your people'.tr),
            GroupedList(
              children: [
                ListRow(
                  icon: CupertinoIcons.circle_grid_hex,
                  title: 'My circle'.tr,
                  value: '${session.circle.length}',
                  onTap: () => _push(context, const CircleScreen()),
                ),
                ListRow(
                  icon: CupertinoIcons.hand_raised,
                  title: 'Blocked people'.tr,
                  value: '${session.blocked.length}',
                  onTap: () => _push(context, const BlockedScreen()),
                ),
              ],
            ),
            SectionLabel('Notifications'.tr),
            const _NotificationSettings(),
            SectionLabel('Appearance'.tr),
            GroupedList(
              children: [
                ListRow(
                  icon: CupertinoIcons.moon,
                  title: 'Theme'.tr,
                  value: switch (settings.mode) {
                    ThemeMode.light => 'Light'.tr,
                    ThemeMode.dark => 'Dark'.tr,
                    ThemeMode.system => 'Automatic'.tr,
                  },
                  onTap: () => _showAppearance(context),
                ),
                ListRow(
                  icon: CupertinoIcons.globe,
                  title: 'Language'.tr,
                  value: settings.isArabic ? 'العربية' : 'English',
                  onTap: () => _showLanguage(context),
                ),
                ..._hijriRows(context, settings),
              ],
            ),
            SectionLabel('More'.tr),
            GroupedList(
              children: [
                ListRow(
                  icon: CupertinoIcons.game_controller,
                  title: 'For fun'.tr,
                  subtitle: 'Quick games to play with friends'.tr,
                  onTap: () => _push(context, const GamesScreen()),
                ),
                ListRow(
                  icon: CupertinoIcons.lock_shield,
                  title: 'Privacy policy'.tr,
                  onTap: () => launchUrl(Uri.parse(_privacyUrl)),
                ),
                ListRow(
                  icon: CupertinoIcons.doc_text,
                  title: 'Terms of use'.tr,
                  onTap: () => launchUrl(Uri.parse(_termsUrl)),
                ),
              ],
            ),
            const SizedBox(height: Space.xl),
            GroupedList(
              children: [
                ListRow(
                  icon: CupertinoIcons.square_arrow_right,
                  title: 'Sign out'.tr,
                  onTap: () async {
                    final ok = await confirm(
                      context,
                      title: 'Sign out?'.tr,
                      message: 'You can sign back in any time.'.tr,
                      confirmLabel: 'Sign out'.tr,
                    );
                    if (ok) await session.auth.signOut();
                  },
                ),
                ListRow(
                  icon: CupertinoIcons.trash,
                  title: 'Delete account'.tr,
                  destructive: true,
                  onTap: () => _deleteAccount(context),
                ),
              ],
            ),
            const SizedBox(height: Space.lg),
            Center(
              child: Text(
                'Note With Us · ${me.email}',
                style: context.text.caption,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The Me tab for guests: join, plus the settings that work without an
/// account (appearance, language, games).
class GuestMeScreen extends StatelessWidget {
  const GuestMeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final settings = AppSettings.instance;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 110,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              Space.lg,
              Space.gutter,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('👋', style: TextStyle(fontSize: 34)),
                ),
                const SizedBox(height: Space.md),
                Text('Hello, guest'.tr, style: context.text.display),
                const SizedBox(height: Space.xxs),
                Text(
                  'Create a free account to write notes, build your circle and keep a private journal.'
                      .tr,
                  style: context.text.body.copyWith(color: c.inkSoft),
                ),
                const SizedBox(height: Space.lg),
                const SignInOptions(),
              ],
            ).animate().fadeIn(duration: Motion.slow).slideY(begin: 0.05),
          ),
          SectionLabel('Appearance'.tr),
          GroupedList(
            children: [
              ListRow(
                icon: CupertinoIcons.moon,
                title: 'Theme'.tr,
                value: switch (settings.mode) {
                  ThemeMode.light => 'Light'.tr,
                  ThemeMode.dark => 'Dark'.tr,
                  ThemeMode.system => 'Automatic'.tr,
                },
                onTap: () => _showAppearance(context),
              ),
              ListRow(
                icon: CupertinoIcons.globe,
                title: 'Language'.tr,
                value: settings.isArabic ? 'العربية' : 'English',
                onTap: () => _showLanguage(context),
              ),
              ..._hijriRows(context, settings),
            ],
          ),
          SectionLabel('More'.tr),
          GroupedList(
            children: [
              ListRow(
                icon: CupertinoIcons.game_controller,
                title: 'For fun'.tr,
                subtitle: 'Quick games to play with friends'.tr,
                onTap: () => Navigator.of(context).push(
                  CupertinoPageRoute<void>(builder: (_) => const GamesScreen()),
                ),
              ),
              ListRow(
                icon: CupertinoIcons.lock_shield,
                title: 'Privacy policy'.tr,
                onTap: () => launchUrl(Uri.parse(_privacyUrl)),
              ),
              ListRow(
                icon: CupertinoIcons.doc_text,
                title: 'Terms of use'.tr,
                onTap: () => launchUrl(Uri.parse(_termsUrl)),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          GroupedList(
            children: [
              ListRow(
                icon: CupertinoIcons.arrow_uturn_left,
                title: 'Back to welcome'.tr,
                onTap: Session.instance.leaveGuest,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final session = Session.instance;
    final me = session.me;
    final details = [
      if (me.age != null) '${me.age} ${'years'.tr}',
      if (me.location.isNotEmpty) me.location,
    ].join('  ·  ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.lg,
        Space.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(url: me.image, name: me.username, size: 76),
              const Spacer(),
              NwuButton(
                label: 'Edit profile'.tr,
                tone: ButtonTone.outline,
                compact: true,
                expand: false,
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          Text(me.username, style: context.text.display),
          if (details.isNotEmpty) Text(details, style: context.text.small),
          if (me.bio.isNotEmpty) ...[
            const SizedBox(height: Space.xs),
            Text(me.bio, style: context.text.body.copyWith(color: c.inkSoft)),
          ],
        ],
      ).animate().fadeIn(duration: Motion.slow).slideY(begin: 0.05),
    );
  }
}

/// The Hijri date switch and, when it is on, the day adjustment.
List<Widget> _hijriRows(BuildContext context, AppSettings settings) => [
  ListRow(
    icon: CupertinoIcons.moon_stars,
    title: 'Hijri dates'.tr,
    subtitle: 'Show the Hijri date next to the usual one'.tr,
    trailing: CupertinoSwitch(
      value: settings.hijri,
      activeTrackColor: context.colors.accent,
      onChanged: settings.setHijri,
    ),
  ),
  if (settings.hijri)
    ListRow(
      icon: CupertinoIcons.plus_slash_minus,
      title: 'Hijri adjustment'.tr,
      value: switch (settings.hijriOffset) {
        < 0 => 'A day earlier'.tr,
        > 0 => 'A day later'.tr,
        _ => 'As calculated'.tr,
      },
      onTap: () => _showHijriAdjustment(context),
    ),
];

void _showHijriAdjustment(BuildContext context) {
  final settings = AppSettings.instance;
  showNwuSheet<void>(
    context,
    builder: (ctx) => ListenableBuilder(
      listenable: settings,
      builder: (ctx, _) => Padding(
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
            Text('Hijri adjustment'.tr, style: ctx.text.title),
            const SizedBox(height: Space.xs),
            Text(
              'Dates follow the Umm al-Qura calendar. If your country starts the month a day earlier or later, adjust it here.'
                  .tr,
              style: ctx.text.small,
            ),
            const SizedBox(height: Space.lg),
            SegmentedPills(
              labels: [
                'A day earlier'.tr,
                'As calculated'.tr,
                'A day later'.tr,
              ],
              index: settings.hijriOffset.clamp(-1, 1) + 1,
              onChanged: (i) => settings.setHijriOffset(i - 1),
            ),
            const SizedBox(height: Space.sm),
            Text(
              'Today: {date}'.tr.replaceAll(
                '{date}',
                formatHijri(DateTime.now()),
              ),
              style: ctx.text.label,
            ),
          ],
        ),
      ),
    ),
  );
}

void _showAppearance(BuildContext context) {
  final settings = AppSettings.instance;
  showNwuSheet<void>(
    context,
    builder: (ctx) => ListenableBuilder(
      listenable: settings,
      builder: (ctx, _) => Padding(
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
            Text('Appearance'.tr, style: ctx.text.title),
            const SizedBox(height: Space.lg),
            SegmentedPills(
              labels: ['Automatic'.tr, 'Light'.tr, 'Dark'.tr],
              index: switch (settings.mode) {
                ThemeMode.system => 0,
                ThemeMode.light => 1,
                ThemeMode.dark => 2,
              },
              onChanged: (i) => settings.setMode(
                [ThemeMode.system, ThemeMode.light, ThemeMode.dark][i],
              ),
            ),
            const SizedBox(height: Space.xl),
            Text('BACKGROUND'.tr, style: ctx.text.overline),
            const SizedBox(height: Space.sm),
            Row(
              children: [
                for (final backdrop in Backdrop.values) ...[
                  Expanded(
                    child: _BackdropTile(
                      backdrop: backdrop,
                      accent: settings.accent,
                      selected: settings.backdrop == backdrop,
                      onTap: () => settings.setBackdrop(backdrop),
                    ),
                  ),
                  if (backdrop != Backdrop.values.last)
                    const SizedBox(width: Space.sm),
                ],
              ],
            ),
            const SizedBox(height: Space.xl),
            Text('ACCENT'.tr, style: ctx.text.overline),
            const SizedBox(height: Space.sm),
            Row(
              children: [
                for (final accent in Accent.values)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: Space.md),
                    child: _AccentSwatch(
                      accent: accent,
                      selected: settings.accent == accent,
                      onTap: () {
                        settings.setAccent(accent);
                        final session = Session.instance;
                        if (session.isGuest) return;
                        session.users.update(session.uid, {'theme': accent.id});
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final Accent accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = c.isDark ? accent.dark : accent.light;
    final label = accent.label;
    return Pressable(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: Motion.base,
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? color : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: selected
                  ? const Icon(
                      CupertinoIcons.checkmark,
                      color: Colors.white,
                      size: 20,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(label.tr, style: context.text.caption.copyWith(color: c.ink)),
        ],
      ),
    );
  }
}

/// A small preview of a background family: its canvas, a card and the
/// current accent.
class _BackdropTile extends StatelessWidget {
  const _BackdropTile({
    required this.backdrop,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final Backdrop backdrop;
  final Accent accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = NwuColors.of(
      c.isDark ? Brightness.dark : Brightness.light,
      accent,
      backdrop,
    );
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.base,
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(
          color: p.canvas,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: selected ? c.accent : c.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 34,
              decoration: BoxDecoration(
                color: p.raised,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: p.line),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                width: 40,
                height: 6,
                decoration: BoxDecoration(
                  color: p.ink.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: Space.xs),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: p.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  backdrop.label.tr,
                  style: context.text.label.copyWith(color: p.ink),
                ),
                const Spacer(),
                if (selected)
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    size: 18,
                    color: c.accent,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _showLanguage(BuildContext context) {
  final settings = AppSettings.instance;
  showActionSheet(
    context,
    title: 'Language'.tr,
    actions: [
      SheetAction(
        icon: settings.isArabic
            ? CupertinoIcons.circle
            : CupertinoIcons.checkmark_circle_fill,
        label: 'English',
        onTap: () => settings.setLang('en'),
      ),
      SheetAction(
        icon: settings.isArabic
            ? CupertinoIcons.checkmark_circle_fill
            : CupertinoIcons.circle,
        label: 'العربية',
        onTap: () => settings.setLang('ar'),
      ),
    ],
  );
}

Future<void> _deleteAccount(BuildContext context) async {
  final session = Session.instance;
  final usesPassword = session.auth.provider == 'password';
  final password = TextEditingController();
  final ok = await showNwuSheet<bool>(
    context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.xl,
        Space.lg,
        Space.xl,
        Space.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Delete your account?'.tr, style: ctx.text.title),
          const SizedBox(height: Space.xs),
          Text(
            'Your profile, notes, capsules and messages will be permanently deleted. This can’t be undone.'
                .tr,
            style: ctx.text.small,
          ),
          if (usesPassword) ...[
            const SizedBox(height: Space.lg),
            NwuField(
              controller: password,
              label: 'Confirm your password'.tr,
              obscure: true,
              icon: CupertinoIcons.lock,
            ),
          ],
          const SizedBox(height: Space.xl),
          NwuButton(
            label: 'Delete forever'.tr,
            tone: ButtonTone.danger,
            onPressed: () => Navigator.pop(ctx, true),
          ),
          const SizedBox(height: Space.xs),
          NwuButton(
            label: 'Cancel'.tr,
            tone: ButtonTone.ghost,
            onPressed: () => Navigator.pop(ctx, false),
          ),
        ],
      ),
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await session.auth.deleteAccount(password: password.text);
    if (context.mounted) showToast(context, 'Your account was deleted'.tr);
  } on FirebaseAuthException catch (e) {
    if (!context.mounted) return;
    final wrongPassword =
        e.code == 'wrong-password' || e.code == 'invalid-credential';
    showToast(
      context,
      wrongPassword ? 'Wrong password'.tr : 'Couldn’t delete your account'.tr,
      error: true,
    );
  } catch (_) {
    if (context.mounted) {
      showToast(context, 'Couldn’t delete your account'.tr, error: true);
    }
  }
}

/// Optional reminders; both are off unless the user turns them on (capsule
/// alerts default on but only fire for capsules addressed to you).
class _NotificationSettings extends StatelessWidget {
  const _NotificationSettings();

  /// Says why a switch snapped back; debug builds add the raw error.
  static String _problem() {
    final reminders = Reminders.instance;
    final message = switch (reminders.lastProblem) {
      ReminderProblem.unavailable =>
        'Notifications aren’t available right now. Restart the app and try again.',
      ReminderProblem.failed => 'Couldn’t set up the reminder. Try again.',
      _ => 'Allow notifications in Settings',
    }.tr;
    final detail = reminders.lastDetail;
    return kDebugMode && detail != null ? '$message\n$detail' : message;
  }

  Future<void> _toggleDaily(BuildContext context, bool on) async {
    final ok = await Reminders.instance.setDaily(on);
    if (!ok && context.mounted) showToast(context, _problem(), error: true);
  }

  Future<void> _toggleCapsules(BuildContext context, bool on) async {
    final ok = await Reminders.instance.setCapsuleAlerts(on);
    if (!ok && context.mounted) showToast(context, _problem(), error: true);
  }

  Future<void> _pickTime(BuildContext context) async {
    final reminders = Reminders.instance;
    final now = DateTime.now();
    var selected = DateTime(
      now.year,
      now.month,
      now.day,
      reminders.time.hour,
      reminders.time.minute,
    );
    final picked = await showNwuSheet<DateTime>(
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
            Text('Reminder time'.tr, style: ctx.text.title),
            SizedBox(
              height: 200,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: ctx.colors.isDark
                      ? Brightness.dark
                      : Brightness.light,
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: selected,
                  onDateTimeChanged: (d) => selected = d,
                ),
              ),
            ),
            NwuButton(
              label: 'Done'.tr,
              onPressed: () => Navigator.pop(ctx, selected),
            ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await reminders.setTime(TimeOfDay.fromDateTime(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminders = Reminders.instance;
    final t = reminders.time;
    return GroupedList(
      children: [
        ListRow(
          icon: CupertinoIcons.bell,
          title: 'Daily writing reminder'.tr,
          subtitle: 'A gentle nudge to write, once a day'.tr,
          trailing: _PermissionSwitch(
            value: reminders.dailyEnabled,
            onChanged: (on) => _toggleDaily(context, on),
          ),
        ),
        if (reminders.dailyEnabled)
          ListRow(
            icon: CupertinoIcons.clock,
            title: 'Reminder time'.tr,
            value: clockTime(DateTime(2000, 1, 1, t.hour, t.minute)),
            onTap: () => _pickTime(context),
          ),
        if (reminders.dailyEnabled)
          ListRow(
            icon: CupertinoIcons.calendar,
            title: 'Reminder days'.tr,
            value: _daysSummary(reminders.days),
            onTap: () => _pickDays(context),
          ),
        ListRow(
          icon: CupertinoIcons.hourglass,
          title: 'Capsule alerts'.tr,
          subtitle: 'When a capsule sent to you unlocks'.tr,
          trailing: _PermissionSwitch(
            value: reminders.capsuleAlerts,
            onChanged: (on) => _toggleCapsules(context, on),
          ),
        ),
      ],
    );
  }
}

/// A switch that moves the instant it is tapped, even though turning it
/// on may wait on the OS permission prompt. It snaps back to [value] if
/// the action is refused.
class _PermissionSwitch extends StatefulWidget {
  const _PermissionSwitch({required this.value, required this.onChanged});

  final bool value;
  final Future<void> Function(bool on) onChanged;

  @override
  State<_PermissionSwitch> createState() => _PermissionSwitchState();
}

class _PermissionSwitchState extends State<_PermissionSwitch> {
  bool? _pending;

  Future<void> _change(bool on) async {
    setState(() => _pending = on);
    try {
      await widget.onChanged(on);
    } catch (_) {
      if (mounted) showToast(context, 'Something went wrong'.tr, error: true);
    } finally {
      if (mounted) setState(() => _pending = null);
    }
  }

  @override
  Widget build(BuildContext context) => CupertinoSwitch(
    value: _pending ?? widget.value,
    activeTrackColor: context.colors.accent,
    onChanged: _pending == null ? _change : null,
  );
}

/// Short weekday name for 1 (Monday) … 7 (Sunday) in the app language.
String _weekdayName(int weekday) => DateFormat.E(
  L10n.arabic ? 'ar' : 'en',
).format(DateTime(2024, 1, weekday)); // 1 Jan 2024 was a Monday.

String _daysSummary(Set<int> days) {
  if (days.length == 7) return 'Every day'.tr;
  if (days.length == 5 && days.containsAll([1, 2, 3, 4, 5])) {
    return 'Weekdays'.tr;
  }
  if (days.length == 2 && days.containsAll([6, 7])) return 'Weekends'.tr;
  return (days.toList()..sort()).map(_weekdayName).join(', ');
}

void _pickDays(BuildContext context) {
  final reminders = Reminders.instance;
  showNwuSheet<void>(
    context,
    builder: (ctx) => ListenableBuilder(
      listenable: reminders,
      builder: (ctx, _) {
        final c = ctx.colors;
        final days = reminders.days;
        return Padding(
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
              Text('Reminder days'.tr, style: ctx.text.title),
              const SizedBox(height: Space.xs),
              Text(
                'Choose the days you’d like a gentle nudge.'.tr,
                style: ctx.text.small,
              ),
              const SizedBox(height: Space.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var d = 1; d <= 7; d++)
                    Pressable(
                      scale: 0.9,
                      semanticLabel: _weekdayName(d),
                      // Keep at least one day selected.
                      onTap: () => reminders.setDays(
                        days.contains(d)
                            ? (days.length > 1 ? ({...days}..remove(d)) : days)
                            : {...days, d},
                      ),
                      child: AnimatedContainer(
                        duration: Motion.base,
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: days.contains(d) ? c.ink : c.surface,
                          border: Border.all(
                            color: days.contains(d) ? c.ink : c.line,
                          ),
                        ),
                        child: Text(
                          _weekdayName(d),
                          style: ctx.text.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: days.contains(d) ? c.canvas : c.ink,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Space.lg),
              Wrap(
                spacing: Space.xs,
                children: [
                  for (final (label, set) in [
                    ('Every day', {1, 2, 3, 4, 5, 6, 7}),
                    ('Weekdays', {1, 2, 3, 4, 5}),
                    ('Weekends', {6, 7}),
                  ])
                    NwuButton(
                      label: label.tr,
                      tone: ButtonTone.outline,
                      compact: true,
                      expand: false,
                      onPressed: () => reminders.setDays(set),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}
