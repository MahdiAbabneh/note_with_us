import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import '../auth/join_sheet.dart';
import 'note_card.dart';

/// A note with its reactions and comments.
class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({super.key, required this.note});

  final Note note;

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final _comment = TextEditingController();
  final _session = Session.instance;
  late Stream<Note?> _noteStream = _session.notes.watch(widget.note);
  late Stream<List<Comment>> _comments = _session.notes.comments(widget.note);

  void _retry() => setState(() {
    _noteStream = _session.notes.watch(widget.note);
    _comments = _session.notes.comments(widget.note);
  });
  bool _sending = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _comment.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _session.notes.addComment(widget.note, _session.me, text);
      _comment.clear();
    } catch (_) {
      if (mounted) {
        showToast(context, 'Couldn’t post your reply'.tr, error: true);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(
        title: 'Note'.tr,
        actions: [
          CircleIconButton(
            icon: CupertinoIcons.ellipsis,
            size: 40,
            onPressed: () => showNoteActions(
              context,
              widget.note,
              onDeleted: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
      body: StreamBuilder<Note?>(
        stream: _noteStream,
        initialData: widget.note,
        builder: (context, snap) {
          if (snap.hasError) return ErrorState(onRetry: _retry);
          final note = snap.data;
          if (note == null) {
            return EmptyState(
              emoji: '🍃',
              title: 'This note is gone'.tr,
              message: 'Its author may have deleted it.'.tr,
            );
          }
          return Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Comment>>(
                  stream: _comments,
                  builder: (context, commentSnap) {
                    if (commentSnap.hasError) {
                      return ErrorState(onRetry: _retry);
                    }
                    final comments = (commentSnap.data ?? const <Comment>[])
                        .where((c) => _session.isVisible(c.ownerId))
                        .toList();
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(
                        Space.gutter,
                        Space.xs,
                        Space.gutter,
                        Space.xl,
                      ),
                      children: [
                        NoteCard(
                          note: note,
                          inDetail: true,
                        ).animate().fadeIn(duration: Motion.base),
                        if (note.reactionTotal > 0)
                          _ReactionSummary(note: note),
                        SectionLabel(
                          comments.isEmpty
                              ? 'Replies'.tr
                              : '${'Replies'.tr} · ${comments.length}',
                          inset: false,
                        ),
                        if (comments.isEmpty &&
                            commentSnap.connectionState !=
                                ConnectionState.waiting)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: Space.md,
                            ),
                            child: Text(
                              'Be the first to reply.'.tr,
                              style: context.text.small,
                            ),
                          ),
                        for (var i = 0; i < comments.length; i++)
                          _CommentTile(note: note, comment: comments[i])
                              .animate(delay: (i * 25).ms)
                              .fadeIn()
                              .slideY(begin: 0.1),
                      ],
                    );
                  },
                ),
              ),
              if (_session.isGuest)
                const _GuestReplyBar()
              else
                _CommentBar(
                  controller: _comment,
                  sending: _sending,
                  onSend: _send,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ReactionSummary extends StatelessWidget {
  const _ReactionSummary({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: Space.md),
      child: Wrap(
        spacing: Space.xs,
        runSpacing: Space.xs,
        children: [
          for (final entry in note.reactionCounts)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: c.raised,
                borderRadius: BorderRadius.circular(Radii.pill),
                border: Border.all(color: c.line),
              ),
              child: Text(
                '${entry.key}  ${entry.value}',
                style: context.text.label,
              ),
            ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.note, required this.comment});

  final Note note;
  final Comment comment;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final session = Session.instance;
    final author = session.userOr(
      comment.ownerId,
      name: comment.ownerName,
      image: comment.ownerImage,
    );
    final canDelete =
        comment.ownerId == session.uid || note.ownerId == session.uid;
    return Pressable(
      scale: 1,
      onLongPress: canDelete
          ? () async {
              final ok = await confirm(
                context,
                title: 'Delete reply?'.tr,
                message: 'This can’t be undone.'.tr,
                confirmLabel: 'Delete'.tr,
                destructive: true,
              );
              if (ok) await session.notes.deleteComment(note, comment);
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Avatar(url: author.image, name: author.username, size: 34),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  Space.md,
                  Space.sm,
                  Space.md,
                  Space.sm,
                ),
                decoration: BoxDecoration(
                  color: c.raised,
                  borderRadius: const BorderRadiusDirectional.only(
                    topEnd: Radius.circular(Radii.md),
                    bottomStart: Radius.circular(Radii.md),
                    bottomEnd: Radius.circular(Radii.md),
                    topStart: Radius.circular(4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            author.username,
                            style: context.text.label,
                          ),
                        ),
                        Text(
                          relativeTime(comment.time),
                          style: context.text.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ContentText(comment.text, style: context.text.body),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// In place of the reply box for guests.
class _GuestReplyBar extends StatelessWidget {
  const _GuestReplyBar();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.canvas,
        border: Border(top: BorderSide(color: c.line)),
      ),
      padding: EdgeInsets.fromLTRB(
        Space.md,
        Space.sm,
        Space.md,
        Space.sm + MediaQuery.of(context).padding.bottom,
      ),
      child: NwuButton(
        label: 'Join to reply'.tr,
        icon: CupertinoIcons.chat_bubble,
        tone: ButtonTone.outline,
        compact: true,
        onPressed: () => showJoinSheet(context, title: 'Join to reply'.tr),
      ),
    );
  }
}

class _CommentBar extends StatelessWidget {
  const _CommentBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.canvas,
        border: Border(top: BorderSide(color: c.line)),
      ),
      padding: EdgeInsets.fromLTRB(
        Space.md,
        Space.sm,
        Space.md,
        Space.sm + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Avatar(
            url: Session.instance.me.image,
            name: Session.instance.me.username,
            size: 34,
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              decoration: BoxDecoration(
                color: c.raised,
                borderRadius: BorderRadius.circular(Radii.pill),
                border: Border.all(color: c.line),
              ),
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => TextField(
                  controller: controller,
                  textDirection: inputDirection(context, controller.text),
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: context.text.body,
                  decoration: InputDecoration(
                    hintText: 'Write a reply…'.tr,
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
            builder: (context, _) => CircleIconButton(
              icon: CupertinoIcons.arrow_up,
              color: controller.text.trim().isEmpty ? c.line : c.accent,
              iconColor: c.onAccent,
              onPressed: sending ? null : onSend,
            ),
          ),
        ],
      ),
    );
  }
}
