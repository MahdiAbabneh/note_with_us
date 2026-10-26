import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../data/session.dart';
import '../../data/users_repository.dart';
import '../../design/design.dart';

/// Edit name, bio, phone, location and avatar.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _session = Session.instance;
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: _session.me.username);
  late final _bio = TextEditingController(text: _session.me.bio);
  late final _phone = TextEditingController(text: _session.me.phoneNumber);
  late final _location = TextEditingController(text: _session.me.location);
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _bio, _phone, _location]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _session.users.update(_session.uid, {
        'username': _name.text.trim(),
        'bio': _bio.text.trim(),
        'phoneNumber': _phone.text.trim(),
        'location': _location.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      showToast(context, 'Profile saved'.tr);
    } catch (_) {
      if (mounted) showToast(context, 'Something went wrong'.tr, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: TopBar(title: 'Edit profile'.tr),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            Space.md,
            Space.gutter,
            Space.xxxl,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Center(
              child: Pressable(
                semanticLabel: 'Choose an avatar'.tr,
                onTap: () => pickAvatar(context),
                child: ListenableBuilder(
                  listenable: _session,
                  builder: (context, _) => Stack(
                    alignment: Alignment.center,
                    children: [
                      Avatar(
                        url: _session.me.image,
                        name: _session.me.username,
                        size: 108,
                      ),
                      PositionedDirectional(
                        bottom: 0,
                        end: 0,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: c.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.canvas, width: 3),
                          ),
                          child: Icon(
                            CupertinoIcons.pencil,
                            size: 15,
                            color: c.onAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: Space.xl),
            NwuField(
              controller: _name,
              label: 'Name'.tr,
              icon: CupertinoIcons.person,
              maxLength: 24,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v ?? '').trim().length < 3
                  ? 'Name must be at least 3 characters'.tr
                  : null,
            ),
            const SizedBox(height: Space.lg),
            NwuField(
              controller: _bio,
              label: 'Bio'.tr,
              hint: 'A line about you'.tr,
              icon: CupertinoIcons.text_quote,
              maxLines: 3,
              maxLength: 140,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: Space.lg),
            NwuField(
              controller: _location,
              label: 'Location'.tr,
              icon: CupertinoIcons.location,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: Space.lg),
            NwuField(
              controller: _phone,
              label: 'Phone'.tr,
              icon: CupertinoIcons.phone,
              keyboardType: TextInputType.phone,
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                return v!.isNotEmpty && digits.length < 7
                    ? 'Enter a valid phone number'.tr
                    : null;
              },
            ),
            const SizedBox(height: Space.xs),
            Text(
              'People who open your profile can call this number. Leave it empty to keep it private.'
                  .tr,
              style: context.text.caption,
            ),
            const SizedBox(height: Space.xxl),
            NwuButton(label: 'Save'.tr, loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

/// Built-in avatars: the two classic cartoon faces plus emoji on soft
/// colours. Choosing one never uploads anything.
final List<String> avatarChoices = [
  maleAvatar,
  femaleAvatar,
  for (final (i, emoji) in [
    '🦊',
    '🐼',
    '🦁',
    '🐨',
    '🐸',
    '🐙',
    '🌻',
    '🌙',
    '⭐️',
    '🌿',
    '☕️',
    '🎧',
  ].indexed)
    emojiAvatar(emoji, i % avatarColors.length),
];

/// Lets the signed-in user pick one of [avatarChoices].
Future<void> pickAvatar(BuildContext context) {
  final session = Session.instance;
  return showNwuSheet<void>(
    context,
    builder: (ctx) => ListenableBuilder(
      listenable: session,
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
            Text('Choose an avatar'.tr, style: ctx.text.title),
            const SizedBox(height: Space.lg),
            Wrap(
              spacing: Space.md,
              runSpacing: Space.md,
              children: [
                for (final choice in avatarChoices)
                  Pressable(
                    scale: 0.9,
                    onTap: () async {
                      try {
                        await session.users.setAvatar(session.uid, choice);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          showToast(context, 'Avatar updated'.tr);
                        }
                      } catch (_) {
                        if (ctx.mounted) {
                          showToast(
                            ctx,
                            'Something went wrong'.tr,
                            error: true,
                          );
                        }
                      }
                    },
                    child: AnimatedContainer(
                      duration: Motion.base,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: session.me.image == choice
                              ? ctx.colors.accent
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: Avatar(
                        url: choice,
                        name: session.me.username,
                        size: 58,
                      ),
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
