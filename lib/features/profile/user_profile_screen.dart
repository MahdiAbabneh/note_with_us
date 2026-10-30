import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/l10n.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import '../capsules/morning_note_sheet.dart';
import '../compose/compose_screen.dart';
import '../messages/chat_screen.dart';
import '../messages/people_screen.dart';
import '../notes/note_card.dart';

/// Someone else's profile and their public notes.
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _session = Session.instance;
  late Stream<List<Note>> _notes = _session.notes.publicBy(widget.user.uid);

  void _more(AppUser user) {
    final blocked = _session.blocked.contains(user.uid);
    showActionSheet(
      context,
      actions: [
        SheetAction(
          icon: CupertinoIcons.flag,
          label: 'Report {name}'.tr.replaceAll('{name}', user.firstName),
          onTap: () async {
            await _session.users.report(user.uid, _session.uid);
            if (mounted) showToast(context, 'Thanks — we’ll take a look.'.tr);
          },
        ),
        if (blocked)
          SheetAction(
            icon: CupertinoIcons.hand_raised_slash,
            label: 'Unblock'.tr,
            onTap: () async {
              await _session.users.setBlocked(
                _session.uid,
                user.uid,
                block: false,
              );
              if (mounted) {
                showToast(
                  context,
                  '{name} is unblocked'.tr.replaceAll('{name}', user.firstName),
                );
              }
            },
          )
        else
          SheetAction(
            icon: CupertinoIcons.hand_raised,
            label: 'Block {name}'.tr.replaceAll('{name}', user.firstName),
            destructive: true,
            onTap: () => blockUser(context, user.uid, user.username),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) {
        final user = _session.userOr(
          widget.user.uid,
          name: widget.user.username,
          image: widget.user.image,
        );
        final blocked = _session.blocked.contains(user.uid);
        return Scaffold(
          appBar: TopBar(
            actions: [
              CircleIconButton(
                icon: CupertinoIcons.ellipsis,
                size: 40,
                onPressed: () => _more(user),
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _ProfileHero(user: user, blocked: blocked),
              ),
              if (!blocked) ...[
                SliverToBoxAdapter(
                  child: SectionLabel('Shared with everyone'.tr),
                ),
                StreamBuilder<List<Note>>(
                  stream: _notes,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return SliverToBoxAdapter(
                        child: ErrorState(
                          compact: true,
                          onRetry: () => setState(
                            () => _notes = _session.notes.publicBy(
                              widget.user.uid,
                            ),
                          ),
                        ),
                      );
                    }
                    final notes = (snap.data ?? const <Note>[])
                        .where((n) => !n.fromOldApp)
                        .toList();
                    if (snap.hasData && notes.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Space.gutter,
                            vertical: Space.md,
                          ),
                          child: Text(
                            'No public notes yet.'.tr,
                            style: context.text.small,
                          ),
                        ),
                      );
                    }
                    return SliverList.builder(
                      itemCount: notes.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Space.gutter,
                          0,
                          Space.gutter,
                          Space.sm,
                        ),
                        child: NoteCard(
                          note: notes[i],
                        ).animate(delay: (i.clamp(0, 6) * 40).ms).fadeIn(),
                      ),
                    );
                  },
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: Space.xxxl)),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.user, required this.blocked});

  final AppUser user;
  final bool blocked;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final details = [
      if (user.age != null) '${user.age} ${'years'.tr}',
      if (user.location.isNotEmpty) user.location,
    ].join('  ·  ');
    final inCircle = Session.instance.circle.contains(user.uid);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.xs,
        Space.gutter,
        0,
      ),
      child: Column(
        children: [
          Avatar(
            url: user.image,
            name: user.username,
            size: 104,
            ring: inCircle,
          ).animate().scale(
            begin: const Offset(0.85, 0.85),
            curve: Motion.pop,
            duration: Motion.slow,
          ),
          const SizedBox(height: Space.md),
          Text(
            user.username,
            style: context.text.display,
            textAlign: TextAlign.center,
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: Space.xxs),
            Text(details, style: context.text.small),
          ],
          if (user.bio.isNotEmpty) ...[
            const SizedBox(height: Space.sm),
            Text(
              user.bio,
              style: context.text.body.copyWith(color: c.inkSoft),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: Space.lg),
          if (blocked)
            Text('You blocked this person.'.tr, style: context.text.small)
          else ...[
            // Messaging is only for people in each other's circle.
            if (inCircle)
              Row(
                children: [
                  Expanded(
                    child: NwuButton(
                      label: 'Message'.tr,
                      icon: CupertinoIcons.chat_bubble_2,
                      tone: ButtonTone.outline,
                      onPressed: () => openChat(context, user),
                    ),
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(child: CircleToggle(user: user)),
                ],
              )
            else ...[
              CircleToggle(user: user),
              const SizedBox(height: Space.xs),
              Text(
                'Join each other’s circle to send messages and capsules.'.tr,
                style: context.text.caption,
                textAlign: TextAlign.center,
              ),
            ],
            if (inCircle) ...[
              const SizedBox(height: Space.sm),
              NwuButton(
                label: 'Send a time capsule'.tr,
                icon: CupertinoIcons.hourglass,
                tone: ButtonTone.ghost,
                onPressed: () => openComposer(
                  context,
                  target: ComposeTarget.capsule,
                  recipient: user,
                ),
              ),
              NwuButton(
                label: 'Send a morning note'.tr,
                icon: CupertinoIcons.sun_max,
                tone: ButtonTone.ghost,
                onPressed: () => showMorningNoteSheet(context, user),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
