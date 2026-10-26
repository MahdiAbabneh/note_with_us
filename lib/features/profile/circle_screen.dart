import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import '../messages/people_screen.dart';

/// People who see your circle notes.
class CircleScreen extends StatelessWidget {
  const CircleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Session.instance;
    return Scaffold(
      appBar: TopBar(
        title: 'My circle'.tr,
        actions: [
          CircleIconButton(
            icon: CupertinoIcons.person_add,
            size: 40,
            onPressed: () => Navigator.of(context).push(
              CupertinoPageRoute<void>(builder: (_) => const PeopleScreen()),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final members = session.circleMembers;
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.gutter,
                  Space.xs,
                  Space.gutter,
                  Space.md,
                ),
                child: Text(
                  'Only people you add here can read the notes you share with your circle. They aren’t notified when you add or remove them.'
                      .tr,
                  style: context.text.small,
                ),
              ),
              if (members.isEmpty)
                EmptyState(
                  emoji: '🫶',
                  title: 'Start your circle'.tr,
                  message:
                      'Add friends and family to share notes with just them.'
                          .tr,
                  actionLabel: 'Find people'.tr,
                  onAction: () => Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      builder: (_) => const PeopleScreen(),
                    ),
                  ),
                )
              else
                for (final user in members) PersonTile(user: user),
            ],
          );
        },
      ),
    );
  }
}

/// People you blocked, with an unblock button.
class BlockedScreen extends StatelessWidget {
  const BlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Session.instance;
    return Scaffold(
      appBar: TopBar(title: 'Blocked people'.tr),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final blocked = session.blocked
              .map((id) => session.userOr(id, name: 'Unknown'.tr))
              .toList();
          if (blocked.isEmpty) {
            return EmptyState(
              emoji: '🕊️',
              title: 'No one blocked'.tr,
              message: 'People you block won’t be able to reach you here.'.tr,
            );
          }
          return ListView(
            children: [
              for (final user in blocked)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.gutter,
                    vertical: Space.sm,
                  ),
                  child: Row(
                    children: [
                      Avatar(url: user.image, name: user.username, size: 44),
                      const SizedBox(width: Space.md),
                      Expanded(
                        child: Text(
                          user.username,
                          style: context.text.bodyStrong,
                        ),
                      ),
                      NwuButton(
                        label: 'Unblock'.tr,
                        tone: ButtonTone.outline,
                        compact: true,
                        expand: false,
                        onPressed: () => session.users.setBlocked(
                          session.uid,
                          user.uid,
                          block: false,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
