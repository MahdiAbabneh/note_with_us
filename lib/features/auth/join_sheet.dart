import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/l10n.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import 'welcome_screen.dart';

/// For guests: shows the join sheet and returns true, so the caller can
/// stop. Returns false for signed-in people.
///
/// ```dart
/// if (needsAccount(context, 'Join to react to notes'.tr)) return;
/// ```
bool needsAccount(BuildContext context, String title) {
  if (!Session.instance.isGuest) return false;
  showJoinSheet(context, title: title);
  return true;
}

/// Invites a guest to create an account, with the sign-in buttons right
/// there. Signing in closes it (see the root widget).
Future<void> showJoinSheet(BuildContext context, {String? title}) {
  return showNwuSheet<void>(
    context,
    builder: (ctx) {
      final c = ctx.colors;
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          Space.lg,
          Space.gutter,
          Space.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.accentSoft,
                shape: BoxShape.circle,
              ),
              child: const Text('🌱', style: TextStyle(fontSize: 30)),
            ).animate().scale(
              begin: const Offset(0.6, 0.6),
              curve: Motion.pop,
              duration: Motion.slow,
            ),
            const SizedBox(height: Space.md),
            Text(
              title ?? 'Create your free account'.tr,
              style: ctx.text.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.xs),
            Text(
              'It takes a few seconds. Write, react, keep a private journal and stay close to your circle.'
                  .tr,
              style: ctx.text.small,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.lg),
            const SignInOptions(),
            const SizedBox(height: Space.xs),
            const LegalLine(),
          ],
        ),
      );
    },
  );
}
