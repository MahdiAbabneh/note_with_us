import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/format.dart';
import '../../core/hijri.dart';
import '../../core/l10n.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import '../auth/join_sheet.dart';
import '../capsules/hug_sheet.dart';
import '../profile/user_profile_screen.dart';
import 'note_detail_screen.dart';
import 'tag_notes_screen.dart';

/// A note rendered as a sheet of mood-tinted paper.
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    this.inDetail = false,
    this.preview = false,
  });

  final Note note;

  /// Detail view shows the full text and no tap-through.
  final bool inDetail;

  /// Composer preview: same look, but no menu, reactions or navigation.
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final session = Session.instance;
    final author = session.userOr(
      note.ownerId,
      name: note.ownerName,
      image: note.ownerImage,
    );
    final social = note.audience != Audience.private && !preview;

    final card = Container(
      padding: const EdgeInsets.fromLTRB(
        Space.lg,
        Space.md,
        Space.md,
        Space.md,
      ),
      decoration: BoxDecoration(
        color: context.paper.tint(
          c.paperTint(note.mood, note.colorSeed),
          dark: c.isDark,
        ),
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            note: note,
            author: author,
            showMenu: !inDetail && !preview,
            detail: inDetail,
          ),
          if (note.prompt.isNotEmpty) ...[
            const SizedBox(height: Space.sm),
            Row(
              children: [
                Icon(CupertinoIcons.sparkles, size: 14, color: c.inkSoft),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    note.prompt,
                    style: t.caption.copyWith(
                      color: c.inkSoft,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (note.text.isNotEmpty) ...[
            const SizedBox(height: Space.sm),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: Space.xs),
              child: PaperBackdrop(
                lineHeight: lineHeightOf(
                  inDetail ? t.noteBody.copyWith(fontSize: 20) : t.noteBody,
                ),
                child: TaggedText(
                  note.text,
                  // Tapping a tag of your own note lists your notes with it.
                  onTag: preview || note.ownerId != Session.instance.uid
                      ? null
                      : (tag) => Navigator.of(context).push(
                          CupertinoPageRoute<void>(
                            builder: (_) => TagNotesScreen(tag: tag),
                          ),
                        ),
                  maxLines: inDetail ? null : 9,
                  overflow: inDetail ? null : TextOverflow.fade,
                  style: inDetail
                      ? t.noteBody.copyWith(fontSize: 20)
                      : t.noteBody,
                ),
              ),
            ),
          ],
          // Photos are no longer supported. A photo-only note from the old
          // app gets a quiet marker instead of looking empty.
          if (note.text.isEmpty && note.images.isNotEmpty) ...[
            const SizedBox(height: Space.sm),
            Tag(icon: CupertinoIcons.photo, label: 'Photo'.tr),
          ],
          if (social) ...[
            const SizedBox(height: Space.md),
            _Footer(note: note, inDetail: inDetail),
          ],
        ],
      ),
    );

    if (inDetail || preview) return card;
    return Pressable(
      scale: 0.985,
      haptic: false,
      onTap: social
          ? () => Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (_) => NoteDetailScreen(note: note),
              ),
            )
          : null,
      child: card,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.note,
    required this.author,
    required this.showMenu,
    this.detail = false,
  });

  final Note note;
  final AppUser author;
  final bool showMenu;

  /// The detail view shows the full date (and its Hijri date).
  final bool detail;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final session = Session.instance;
    final mine = note.ownerId == session.uid;
    // Only a feeling the writer chose; plain notes get colour, not a label.
    final moodLabel = note.mood == Mood.plain
        ? ''
        : ' · ${note.mood.emoji} ${note.mood.label.tr}';

    void openProfile() {
      if (mine) return;
      if (needsAccount(context, 'Join to see profiles'.tr)) return;
      Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => UserProfileScreen(user: author),
        ),
      );
    }

    return Row(
      children: [
        Pressable(
          onTap: mine ? null : openProfile,
          child: Avatar(
            url: author.image,
            name: author.username,
            size: 38,
            ring: session.circle.contains(note.ownerId),
          ),
        ),
        const SizedBox(width: Space.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mine ? 'You'.tr : author.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.label.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                '${detail ? fullDateWithHijri(note.time) : relativeTime(note.time)}$moodLabel',
                style: t.caption.copyWith(color: c.inkSoft),
              ),
            ],
          ),
        ),
        if (note.pinned) ...[
          Icon(CupertinoIcons.pin_fill, size: 14, color: c.accent),
          const SizedBox(width: 6),
        ],
        if (note.comfort) ...[
          Icon(CupertinoIcons.heart_fill, size: 14, color: c.accent),
          const SizedBox(width: 6),
        ],
        ListenableBuilder(
          listenable: Session.instance,
          builder: (context, _) =>
              Session.instance.favoriteKeys.contains(note.key)
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: Icon(
                    CupertinoIcons.star_fill,
                    size: 14,
                    color: c.accent,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        _AudienceTag(audience: note.audience),
        if (showMenu)
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => showNoteActions(context, note),
            icon: Icon(CupertinoIcons.ellipsis, size: 20, color: c.inkSoft),
          )
        else
          const SizedBox(width: Space.xs),
      ],
    );
  }
}

class _AudienceTag extends StatelessWidget {
  const _AudienceTag({required this.audience});

  final Audience audience;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (audience) {
      Audience.private => (CupertinoIcons.lock_fill, 'Only me'),
      Audience.circle => (CupertinoIcons.circle_grid_hex_fill, 'Circle'),
      Audience.everyone => (CupertinoIcons.globe, 'Everyone'),
    };
    return Tag(icon: icon, label: label.tr);
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.note, required this.inDetail});

  final Note note;
  final bool inDetail;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final counts = note.reactionCounts;
    final mine = note.reactionOf(Session.instance.uid);
    final row = Row(
      children: [
        ReactButton(note: note, current: mine),
        const SizedBox(width: Space.xs),
        if (counts.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                counts.take(3).map((e) => e.key).join(),
                style: const TextStyle(fontSize: 14, letterSpacing: -2),
              ),
              const SizedBox(width: 6),
              Text(
                '${note.reactionTotal}',
                style: t.caption.copyWith(color: c.inkSoft),
              ),
            ],
          ),
        const Spacer(),
        Icon(CupertinoIcons.chat_bubble, size: 18, color: c.inkSoft),
        const SizedBox(width: 5),
        Text(
          note.commentCount == 0 ? 'Reply'.tr : '${note.commentCount}',
          style: t.caption.copyWith(color: c.inkSoft),
        ),
        const SizedBox(width: Space.xs),
      ],
    );
    if (!HugButton.shows(note)) return row;
    // A friend writing in a blue mood gets a gentle way to reach out.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row,
        const SizedBox(height: Space.xs),
        HugButton(note: note),
      ],
    );
  }
}

/// Tap toggles ❤️, long-press (or tap when reacted) opens the picker.
class ReactButton extends StatelessWidget {
  const ReactButton({super.key, required this.note, required this.current});

  final Note note;
  final String? current;

  Future<void> _set(BuildContext context, String? emoji) async {
    try {
      await Session.instance.notes.react(note, Session.instance.uid, emoji);
    } catch (_) {
      if (context.mounted) {
        showToast(context, 'Something went wrong'.tr, error: true);
      }
    }
  }

  void _openPicker(BuildContext context) async {
    if (needsAccount(context, 'Join to react to notes'.tr)) return;
    final box = context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset.zero);
    final emoji = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withValues(alpha: 0.08),
      transitionDuration: Motion.fast,
      pageBuilder: (ctx, _, _) =>
          _ReactionPicker(anchor: origin, current: current),
    );
    if (emoji == null || !context.mounted) return;
    await _set(context, emoji == current ? null : emoji);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reacted = current != null;
    return Pressable(
      scale: 0.85,
      onTap: () {
        if (reacted) {
          _openPicker(context);
        } else if (!needsAccount(context, 'Join to react to notes'.tr)) {
          HapticFeedback.lightImpact();
          _set(context, '❤️');
        }
      },
      onLongPress: () => _openPicker(context),
      child: AnimatedContainer(
        duration: Motion.base,
        curve: Motion.ease,
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: reacted ? c.raised : c.ink.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(
            color: reacted
                ? c.accent.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: Motion.base,
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: reacted
                  ? Text(
                      current!,
                      key: ValueKey(current),
                      style: const TextStyle(fontSize: 16),
                    )
                  : Icon(
                      CupertinoIcons.heart,
                      key: const ValueKey('none'),
                      size: 18,
                      color: c.ink,
                    ),
            ),
            const SizedBox(width: 6),
            Text(
              reacted ? 'Reacted'.tr : 'React'.tr,
              style: context.text.caption.copyWith(
                color: c.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionPicker extends StatelessWidget {
  const _ReactionPicker({required this.anchor, required this.current});

  final Offset anchor;
  final String? current;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = (anchor.dy - 64).clamp(
      MediaQuery.of(context).padding.top + 8,
      double.infinity,
    );
    return Stack(
      children: [
        Positioned(
          top: top,
          left: Space.gutter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: c.raised,
                borderRadius: BorderRadius.circular(Radii.pill),
                boxShadow: softShadow(c, strength: 2.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < reactionEmojis.length; i++)
                    Pressable(
                      scale: 0.8,
                      onTap: () => Navigator.pop(context, reactionEmojis[i]),
                      child:
                          Container(
                                width: 46,
                                height: 46,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: reactionEmojis[i] == current
                                      ? c.accentSoft
                                      : Colors.transparent,
                                ),
                                child: Text(
                                  reactionEmojis[i],
                                  style: const TextStyle(fontSize: 28),
                                ),
                              )
                              .animate(delay: (i * 30).ms)
                              .scale(
                                begin: const Offset(0.3, 0.3),
                                curve: Motion.pop,
                                duration: Motion.base,
                              )
                              .fadeIn(),
                    ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: Motion.fast).slideY(begin: 0.3),
        ),
      ],
    );
  }
}

/// Copy, delete, report and block, depending on who wrote the note.
/// Runs a note action and reports the result as a toast.
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

void showNoteActions(
  BuildContext context,
  Note note, {
  VoidCallback? onDeleted,
}) {
  final session = Session.instance;
  if (session.isGuest) return _showGuestNoteActions(context, note);
  final mine = note.ownerId == session.uid;
  showActionSheet(
    context,
    actions: [
      if (note.text.isNotEmpty)
        SheetAction(
          icon: CupertinoIcons.doc_on_doc,
          label: 'Copy text'.tr,
          onTap: () {
            Clipboard.setData(ClipboardData(text: note.text));
            showToast(context, 'Copied'.tr);
          },
        ),
      if (session.favoriteKeys.contains(note.key))
        SheetAction(
          icon: CupertinoIcons.star_slash,
          label: 'Remove from favorites'.tr,
          onTap: () => _run(
            context,
            () => session.notes.setFavorite(session.uid, note, favorite: false),
            'Removed from favorites'.tr,
          ),
        )
      else
        SheetAction(
          icon: CupertinoIcons.star,
          label: 'Add to favorites'.tr,
          onTap: () => _run(
            context,
            () => session.notes.setFavorite(session.uid, note, favorite: true),
            'Saved to favorites ⭐'.tr,
          ),
        ),
      if (mine && note.audience == Audience.private)
        SheetAction(
          icon: note.archived
              ? CupertinoIcons.tray_arrow_up
              : CupertinoIcons.archivebox,
          label: note.archived ? 'Unarchive'.tr : 'Archive'.tr,
          onTap: () => _run(
            context,
            () => session.notes.setArchived(note, archived: !note.archived),
            note.archived ? 'Note restored'.tr : 'Note archived'.tr,
          ),
        ),
      if (mine && note.audience == Audience.private)
        SheetAction(
          icon: note.comfort
              ? CupertinoIcons.heart_slash
              : CupertinoIcons.heart,
          label: note.comfort
              ? 'Remove from comfort box'.tr
              : 'Keep for hard days'.tr,
          onTap: () => _run(
            context,
            () => session.notes.setComfort(note, comfort: !note.comfort),
            note.comfort
                ? 'Removed from your comfort box'.tr
                : 'Kept for hard days 🤍'.tr,
          ),
        ),
      if (mine && note.audience == Audience.private)
        SheetAction(
          icon: note.pinned ? CupertinoIcons.pin_slash : CupertinoIcons.pin,
          label: note.pinned ? 'Unpin'.tr : 'Pin to top'.tr,
          onTap: () async {
            try {
              await session.notes.setPinned(note, pinned: !note.pinned);
            } catch (_) {
              if (context.mounted) {
                showToast(context, 'Something went wrong'.tr, error: true);
              }
            }
          },
        ),
      if (mine)
        SheetAction(
          icon: CupertinoIcons.trash,
          label: 'Delete note'.tr,
          destructive: true,
          onTap: () async {
            final ok = await confirm(
              context,
              title: 'Delete this note?'.tr,
              message: 'This can’t be undone.'.tr,
              confirmLabel: 'Delete'.tr,
              destructive: true,
            );
            if (!ok) return;
            await session.notes.delete(note);
            onDeleted?.call();
            if (context.mounted) showToast(context, 'Note deleted'.tr);
          },
        ),
      if (!mine) ...[
        SheetAction(
          icon: CupertinoIcons.flag,
          label: 'Report note'.tr,
          onTap: () async {
            await session.notes.report(note, session.uid);
            if (context.mounted) {
              showToast(context, 'Thanks — we’ll review this note.'.tr);
            }
          },
        ),
        SheetAction(
          icon: CupertinoIcons.hand_raised,
          label: 'Block {name}'.tr.replaceAll('{name}', note.ownerName),
          destructive: true,
          onTap: () => blockUser(context, note.ownerId, note.ownerName),
        ),
      ],
    ],
  );
}

/// What a guest can do with someone's note: copy it, hide that person
/// on this device, or join to report it.
void _showGuestNoteActions(BuildContext context, Note note) {
  showActionSheet(
    context,
    actions: [
      if (note.text.isNotEmpty)
        SheetAction(
          icon: CupertinoIcons.doc_on_doc,
          label: 'Copy text'.tr,
          onTap: () {
            Clipboard.setData(ClipboardData(text: note.text));
            showToast(context, 'Copied'.tr);
          },
        ),
      SheetAction(
        icon: CupertinoIcons.flag,
        label: 'Report note'.tr,
        onTap: () => showJoinSheet(context, title: 'Join to report notes'.tr),
      ),
      SheetAction(
        icon: CupertinoIcons.eye_slash,
        label: 'Hide notes from {name}'.tr.replaceAll('{name}', note.ownerName),
        destructive: true,
        onTap: () {
          Session.instance.hideForGuest(note.ownerId);
          showToast(context, 'You won’t see their notes on this phone.'.tr);
        },
      ),
    ],
  );
}

/// Confirms and blocks a user.
Future<void> blockUser(BuildContext context, String uid, String name) async {
  final ok = await confirm(
    context,
    title: 'Block {name}?'.tr.replaceAll('{name}', name),
    message:
        'You won’t see their notes or messages, and they’ll be removed from your circle.'
            .tr,
    confirmLabel: 'Block'.tr,
    destructive: true,
  );
  if (!ok) return;
  final session = Session.instance;
  await session.users.setBlocked(session.uid, uid, block: true);
  if (context.mounted) {
    showToast(context, '{name} is blocked'.tr.replaceAll('{name}', name));
  }
}
