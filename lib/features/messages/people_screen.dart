import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/l10n.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import '../profile/user_profile_screen.dart';

/// Search everyone and add people to your circle.
class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = Session.instance;
    return Scaffold(
      appBar: TopBar(title: 'Find people'.tr),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              Space.xs,
              Space.gutter,
              Space.sm,
            ),
            child: SearchField(
              controller: _search,
              hint: 'Search by name'.tr,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: session,
              builder: (context, _) {
                final people = session.people
                    .where((p) => p.username.toLowerCase().contains(_query))
                    .toList();
                if (people.isEmpty) {
                  return EmptyState(
                    emoji: '🔎',
                    title: 'No one found'.tr,
                    message: 'Try a different name.'.tr,
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + Space.xl,
                  ),
                  itemCount: people.length,
                  itemBuilder: (context, i) => PersonTile(
                    user: people[i],
                  ).animate(delay: (i.clamp(0, 10) * 25).ms).fadeIn(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A person with an add-to-circle toggle.
class PersonTile extends StatelessWidget {
  const PersonTile({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final session = Session.instance;
    final inCircle = session.circle.contains(user.uid);
    final details = [
      if (user.age != null) '${user.age}',
      if (user.location.isNotEmpty) user.location,
    ].join(' · ');
    return Pressable(
      scale: 0.99,
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute<void>(builder: (_) => UserProfileScreen(user: user)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.gutter,
          vertical: Space.sm,
        ),
        child: Row(
          children: [
            Avatar(
              url: user.image,
              name: user.username,
              size: 48,
              ring: inCircle,
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.username, style: context.text.bodyStrong),
                  if (details.isNotEmpty)
                    Text(details, style: context.text.caption),
                ],
              ),
            ),
            CircleToggle(user: user, compact: true),
          ],
        ),
      ),
    );
  }
}

/// Circle button with four states: add (sends a request), requested
/// (tap to withdraw), accept (they asked you), and in circle (tap to
/// remove, which removes you from each other's circles).
class CircleToggle extends StatelessWidget {
  const CircleToggle({super.key, required this.user, this.compact = false});

  final AppUser user;
  final bool compact;

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String done,
  ) async {
    try {
      await action();
      if (context.mounted) showToast(context, done);
    } catch (_) {
      if (context.mounted) {
        showToast(context, 'Something went wrong'.tr, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Session.instance;
    final name = user.firstName;
    final incoming = session.incomingRequests
        .where((r) => r.from == user.uid)
        .firstOrNull;
    final (label, icon, tone, onPressed) = switch (()) {
      _ when session.circle.contains(user.uid) => (
        'In circle'.tr,
        CupertinoIcons.checkmark,
        ButtonTone.outline,
        () async {
          final ok = await confirm(
            context,
            title: 'Remove {name} from your circle?'.tr.replaceAll(
              '{name}',
              name,
            ),
            message: 'You’ll both stop seeing each other’s circle notes.'.tr,
            confirmLabel: 'Remove'.tr,
            destructive: true,
          );
          if (!ok || !context.mounted) return;
          await _run(
            context,
            () => session.users.removeFromCircle(session.uid, user.uid),
            '{name} left your circle'.tr.replaceAll('{name}', name),
          );
        },
      ),
      _ when incoming != null => (
        'Accept'.tr,
        CupertinoIcons.person_crop_circle_badge_checkmark,
        ButtonTone.accent,
        () => _run(
          context,
          () => session.users.acceptCircleRequest(
            incoming,
            alsoSent: session.requested.contains(user.uid),
          ),
          'You and {name} are in each other’s circle'.tr.replaceAll(
            '{name}',
            name,
          ),
        ),
      ),
      _ when session.requested.contains(user.uid) => (
        'Requested'.tr,
        CupertinoIcons.clock,
        ButtonTone.outline,
        () => _run(
          context,
          () => session.users.cancelCircleRequest(session.uid, user.uid),
          'Request withdrawn'.tr,
        ),
      ),
      _ => (
        'Add to circle'.tr,
        CupertinoIcons.add,
        ButtonTone.ink,
        () => _run(
          context,
          () => session.users.sendCircleRequest(session.me, user),
          'Request sent to {name}'.tr.replaceAll('{name}', name),
        ),
      ),
    };
    return NwuButton(
      label: label,
      icon: icon,
      tone: tone,
      compact: compact,
      expand: !compact,
      onPressed: onPressed,
    );
  }
}
