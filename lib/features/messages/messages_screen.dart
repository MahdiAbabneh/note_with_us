import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import 'chat_screen.dart';
import '../profile/user_profile_screen.dart';
import 'people_screen.dart';

/// Conversations, most recent first.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _session = Session.instance;
  late Stream<List<ChatThread>> _threads = _session.chats.threads(_session.uid);

  void _openPeople() => Navigator.of(
    context,
  ).push(CupertinoPageRoute<void>(builder: (_) => const PeopleScreen()));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          PageHeader(
            overline: 'Stay close'.tr,
            title: 'Messages'.tr,
            actions: [
              CircleIconButton(
                icon: CupertinoIcons.person_add,
                semanticLabel: 'Find people'.tr,
                onPressed: _openPeople,
              ),
            ],
          ),
          const _CircleRequests(),
          _CircleStrip(onFind: _openPeople),
          Expanded(
            child: ListenableBuilder(
              listenable: _session,
              builder: (context, _) => StreamBuilder<List<ChatThread>>(
                stream: _threads,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return ErrorState(
                      onRetry: () => setState(
                        () => _threads = _session.chats.threads(_session.uid),
                      ),
                    );
                  }
                  final threads = (snap.data ?? const <ChatThread>[])
                      .where((t) => _session.isVisible(t.userId))
                      .toList();
                  if (snap.hasData && threads.isEmpty) {
                    return EmptyState(
                      emoji: '💬',
                      title: 'No messages yet'.tr,
                      message: 'Say hi to someone from your circle.'.tr,
                      actionLabel: 'Find people'.tr,
                      onAction: _openPeople,
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.only(
                      top: Space.xs,
                      bottom: MediaQuery.of(context).padding.bottom + 110,
                    ),
                    itemCount: threads.length,
                    itemBuilder: (context, i) => _ThreadRow(thread: threads[i])
                        .animate(delay: (i.clamp(0, 8) * 30).ms)
                        .fadeIn()
                        .slideX(begin: 0.04),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleStrip extends StatelessWidget {
  const _CircleStrip({required this.onFind});

  final VoidCallback onFind;

  @override
  Widget build(BuildContext context) {
    final session = Session.instance;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final members = session.circleMembers;
        return SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            children: [
              _StripItem(
                label: 'Add'.tr,
                onTap: onFind,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: context.colors.line, width: 1.5),
                  ),
                  child: Icon(CupertinoIcons.add, color: context.colors.ink),
                ),
              ),
              for (final user in members)
                _StripItem(
                  label: user.firstName,
                  onTap: () => openChat(context, user),
                  child: Avatar(
                    url: user.image,
                    name: user.username,
                    size: 52,
                    ring: true,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StripItem extends StatelessWidget {
  const _StripItem({
    required this.label,
    required this.child,
    required this.onTap,
  });

  final String label;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: Space.md),
      child: Pressable(
        onTap: onTap,
        child: SizedBox(
          width: 60,
          child: Column(
            children: [
              child,
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.caption.copyWith(color: context.colors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({required this.thread});

  final ChatThread thread;

  @override
  Widget build(BuildContext context) {
    final session = Session.instance;
    final user = session.userOr(
      thread.userId,
      name: thread.username,
      image: thread.userImage,
    );
    return Pressable(
      scale: 0.99,
      onTap: () => openChat(context, user),
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
              size: 52,
              ring: session.circle.contains(user.uid),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodyStrong,
                        ),
                      ),
                      if (thread.lastTime != null)
                        Text(
                          relativeTime(thread.lastTime!),
                          style: context.text.caption,
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    thread.lastMessage.isEmpty
                        ? 'Tap to chat'.tr
                        : thread.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.small,
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

/// Pending invitations to join circles, with accept and decline.
class _CircleRequests extends StatelessWidget {
  const _CircleRequests();

  @override
  Widget build(BuildContext context) {
    final session = Session.instance;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final requests = session.incomingRequests
            .where((r) => session.isVisible(r.from))
            .toList();
        if (requests.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.gutter,
                0,
                Space.gutter,
                Space.xs,
              ),
              child: Text('CIRCLE REQUESTS'.tr, style: context.text.overline),
            ),
            for (final request in requests) _RequestRow(request: request),
            const SizedBox(height: Space.sm),
          ],
        ).animate().fadeIn(duration: Motion.base);
      },
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request});

  final CircleRequest request;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final session = Session.instance;
    final user = session.userOr(
      request.from,
      name: request.fromName,
      image: request.fromImage,
    );
    Future<void> run(Future<void> Function() action, String done) async {
      try {
        await action();
        if (context.mounted) showToast(context, done);
      } catch (_) {
        if (context.mounted) {
          showToast(context, 'Something went wrong'.tr, error: true);
        }
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(
        Space.gutter,
        0,
        Space.gutter,
        Space.xs,
      ),
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: c.accentSoft,
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Row(
        children: [
          Pressable(
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (_) => UserProfileScreen(user: user),
              ),
            ),
            child: Avatar(url: user.image, name: user.username, size: 44),
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyStrong,
                ),
                Text(
                  'Wants to join your circle'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.xs),
          NwuButton(
            label: 'Decline'.tr,
            tone: ButtonTone.ghost,
            compact: true,
            expand: false,
            onPressed: () => run(
              () => session.users.declineCircleRequest(request),
              'Request declined'.tr,
            ),
          ),
          NwuButton(
            label: 'Accept'.tr,
            tone: ButtonTone.accent,
            compact: true,
            expand: false,
            onPressed: () => run(
              () => session.users.acceptCircleRequest(
                request,
                alsoSent: session.requested.contains(request.from),
              ),
              'You and {name} are in each other’s circle'.tr.replaceAll(
                '{name}',
                user.firstName,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
