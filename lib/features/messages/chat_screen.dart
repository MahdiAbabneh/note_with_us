import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import '../profile/user_profile_screen.dart';
import 'people_screen.dart';

/// Pushes a conversation with [user].
void openChat(BuildContext context, AppUser user) {
  Navigator.of(
    context,
  ).push(CupertinoPageRoute<void>(builder: (_) => ChatScreen(user: user)));
}

/// One-to-one conversation.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

/// A message typed here that the server hasn't confirmed yet.
class _Outgoing {
  _Outgoing(this.text);

  final String text;
  final DateTime time = DateTime.now();
  bool failed = false;
}

class _ChatScreenState extends State<ChatScreen> {
  final _session = Session.instance;
  final _input = TextEditingController();
  late Stream<List<Message>> _messages = _subscribe();

  /// Messages shown immediately while they send; removed once confirmed.
  final List<_Outgoing> _outbox = [];

  Stream<List<Message>> _subscribe() =>
      _session.chats.messages(_session.uid, widget.user.uid);

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    final outgoing = _Outgoing(text);
    setState(() => _outbox.add(outgoing));
    await _deliver(outgoing);
  }

  /// Sends (or re-sends) a message. Offline writes stay "sending" until the
  /// connection returns; a rejected write is marked failed for a retry.
  Future<void> _deliver(_Outgoing outgoing) async {
    setState(() => outgoing.failed = false);
    try {
      await _session.chats.send(_session.me, widget.user, outgoing.text);
      if (mounted) setState(() => _outbox.remove(outgoing));
    } catch (_) {
      if (mounted) setState(() => outgoing.failed = true);
    }
  }

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: widget.user.phoneNumber);
    if (!await launchUrl(uri) && mounted) {
      showToast(context, 'Calling isn’t available'.tr, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _session.userOr(
      widget.user.uid,
      name: widget.user.username,
      image: widget.user.image,
    );
    final blocked = !_session.isVisible(user.uid);
    return Scaffold(
      appBar: TopBar(
        titleWidget: Pressable(
          onTap: () => Navigator.of(context).push(
            CupertinoPageRoute<void>(
              builder: (_) => UserProfileScreen(user: user),
            ),
          ),
          child: Row(
            children: [
              Avatar(url: user.image, name: user.username, size: 36),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  user.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.headline,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (user.phoneNumber.isNotEmpty)
            CircleIconButton(
              icon: CupertinoIcons.phone,
              size: 40,
              onPressed: _call,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messages,
              builder: (context, snap) {
                if (snap.hasError) {
                  return ErrorState(
                    onRetry: () => setState(() => _messages = _subscribe()),
                  );
                }
                final messages = snap.data ?? const <Message>[];
                final pending = _outbox.reversed.toList();
                if (snap.hasData && messages.isEmpty && pending.isEmpty) {
                  return EmptyState(
                    emoji: '👋',
                    title: 'Say hello'.tr,
                    message: 'Start your conversation with {name}.'.tr
                        .replaceAll('{name}', user.firstName),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.md,
                    vertical: Space.md,
                  ),
                  itemCount: pending.length + messages.length,
                  itemBuilder: (context, i) {
                    if (i < pending.length) {
                      return _PendingBubble(
                        outgoing: pending[i],
                        onRetry: () => _deliver(pending[i]),
                      );
                    }
                    i -= pending.length;
                    final message = messages[i];
                    final older = i + 1 < messages.length
                        ? messages[i + 1]
                        : null;
                    final newDay =
                        older == null ||
                        older.time.day != message.time.day ||
                        older.time.month != message.time.month;
                    return Column(
                      children: [
                        if (newDay) _DayDivider(time: message.time),
                        _Bubble(
                          message: message,
                          mine: message.senderId == _session.uid,
                          animate: i == 0,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          // Rebuilds when circle or block lists change, so the composer
          // appears as soon as a request is accepted.
          ListenableBuilder(
            listenable: _session,
            builder: (context, _) {
              if (blocked) {
                return _ChatNotice(text: 'You blocked this person.'.tr);
              }
              if (!_session.circle.contains(user.uid)) {
                return _ChatNotice(
                  text: 'You can message people in your circle.'.tr,
                  action: CircleToggle(user: user, compact: true),
                );
              }
              return _Composer(controller: _input, onSend: _send);
            },
          ),
        ],
      ),
    );
  }
}

/// Replaces the composer when messaging isn't allowed.
class _ChatNotice extends StatelessWidget {
  const _ChatNotice({required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        Space.gutter,
        Space.md,
        Space.gutter,
        Space.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.colors.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: context.text.small, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: Space.sm), action!],
        ],
      ),
    );
  }
}

class _PendingBubble extends StatelessWidget {
  const _PendingBubble({required this.outgoing, required this.onRetry});

  final _Outgoing outgoing;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final failed = outgoing.failed;
    return Pressable(
      onTap: failed ? onRetry : null,
      semanticLabel: failed ? 'Not sent. Tap to retry'.tr : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Opacity(
            opacity: failed ? 1 : 0.6,
            child: _Bubble(
              message: Message(
                senderId: '',
                receiverId: '',
                text: outgoing.text,
                time: outgoing.time,
              ),
              mine: true,
              animate: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: Space.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  failed
                      ? CupertinoIcons.exclamationmark_circle_fill
                      : CupertinoIcons.clock,
                  size: 13,
                  color: failed ? c.danger : c.muted,
                ),
                const SizedBox(width: 4),
                Text(
                  failed ? 'Not sent · Tap to retry'.tr : 'Sending…'.tr,
                  style: context.text.caption.copyWith(
                    color: failed ? c.danger : c.muted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayDivider extends StatelessWidget {
  const _DayDivider({required this.time});

  final DateTime time;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today =
        time.year == now.year && time.month == now.month && time.day == now.day;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.md),
      child: Text(
        today ? 'Today'.tr : fullDate(time),
        style: context.text.caption,
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.animate,
  });

  final Message message;
  final bool mine;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bubble = Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: mine ? c.ink : c.raised,
            borderRadius: BorderRadiusDirectional.only(
              topStart: const Radius.circular(20),
              topEnd: const Radius.circular(20),
              bottomStart: Radius.circular(mine ? 20 : 6),
              bottomEnd: Radius.circular(mine ? 6 : 20),
            ),
            border: mine
                ? null
                : Border.all(color: c.line.withValues(alpha: 0.7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ContentText(
                message.text,
                fill: false,
                style: context.text.body.copyWith(
                  color: mine ? c.canvas : c.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                clockTime(message.time),
                style: context.text.caption.copyWith(
                  fontSize: 11,
                  color: mine ? c.canvas.withValues(alpha: 0.55) : c.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!animate) return bubble;
    return bubble
        .animate()
        .fadeIn(duration: Motion.fast)
        .slideY(begin: 0.3, curve: Motion.ease, duration: Motion.base);
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.fromLTRB(
        Space.md,
        Space.sm,
        Space.md,
        Space.sm + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: c.canvas,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              decoration: BoxDecoration(
                color: c.raised,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: c.line),
              ),
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => TextField(
                  controller: controller,
                  textDirection: inputDirection(context, controller.text),
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  style: context.text.body,
                  decoration: InputDecoration(
                    hintText: 'Message'.tr,
                    hintStyle: context.text.body.copyWith(color: c.muted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: Space.xs),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final empty = controller.text.trim().isEmpty;
              return AnimatedScale(
                scale: empty ? 0.85 : 1,
                duration: Motion.base,
                curve: Motion.pop,
                child: CircleIconButton(
                  icon: CupertinoIcons.arrow_up,
                  size: 46,
                  color: empty ? c.line : c.accent,
                  iconColor: c.onAccent,
                  onPressed: empty ? null : onSend,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
