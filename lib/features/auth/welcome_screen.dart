import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n.dart';
import '../../core/settings.dart';
import '../../data/auth_service.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import 'sign_in_screen.dart';

/// First screen for signed-out people.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final settings = AppSettings.instance;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.gutter,
                Space.sm,
                Space.gutter,
                0,
              ),
              child: Row(
                children: [
                  Text(
                    'Note With Us',
                    style: context.text.title.copyWith(fontSize: 20),
                  ),
                  const Spacer(),
                  Pressable(
                    onTap: () =>
                        settings.setLang(settings.isArabic ? 'en' : 'ar'),
                    child: Tag(
                      icon: CupertinoIcons.globe,
                      label: settings.isArabic ? 'English' : 'العربية',
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(child: IgnorePointer(child: _HeroStack())),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                        'Notes for the\npeople you love.'.tr,
                        style: context.text.hero,
                      )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: Motion.slow)
                      .slideY(begin: 0.15),
                  const SizedBox(height: Space.sm),
                  Text(
                    'Share with your circle, keep a private journal, and seal notes that open in the future.'
                        .tr,
                    style: context.text.body.copyWith(color: c.inkSoft),
                  ).animate().fadeIn(delay: 300.ms, duration: Motion.slow),
                  const SizedBox(height: Space.xl),
                  const SignInOptions(),
                  const SizedBox(height: Space.xs),
                  Center(
                    child: Pressable(
                      onTap: Session.instance.enterGuest,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.md,
                          vertical: Space.xs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Look around first'.tr,
                              style: context.text.label.copyWith(
                                color: c.accent,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Directionality.of(context) == TextDirection.rtl
                                  ? CupertinoIcons.arrow_left
                                  : CupertinoIcons.arrow_right,
                              size: 15,
                              color: c.accent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  const LegalLine(),
                  const SizedBox(height: Space.md),
                ],
              ).animate().fadeIn(delay: 380.ms, duration: Motion.slow),
            ),
          ],
        ),
      ),
    );
  }
}

/// Apple (on iOS), Google and email sign-in buttons. Used on the welcome
/// screen and wherever a guest is asked to join.
class SignInOptions extends StatefulWidget {
  const SignInOptions({super.key});

  @override
  State<SignInOptions> createState() => _SignInOptionsState();
}

class _SignInOptionsState extends State<SignInOptions> {
  String? _busy;

  Future<void> _run(String key, Future<void> Function() action) async {
    setState(() => _busy = key);
    try {
      await action();
    } on SignInCancelled {
      // The person closed the sheet; nothing to report.
    } on FirebaseAuthException catch (e) {
      if (mounted) showToast(context, authErrorMessage(e), error: true);
    } catch (_) {
      if (mounted) {
        showToast(context, 'Sign-in failed. Please try again.'.tr, error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Session.instance.auth;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (Platform.isIOS) ...[
          NwuButton(
            label: 'Continue with Apple'.tr,
            icon: Icons.apple,
            loading: _busy == 'apple',
            onPressed: _busy == null
                ? () => _run('apple', auth.signInWithApple)
                : null,
          ),
          const SizedBox(height: Space.sm),
        ],
        NwuButton(
          label: 'Continue with Google'.tr,
          tone: ButtonTone.outline,
          leading: Container(
            width: 26,
            height: 26,
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(child: Image.asset('assets/images/google.png')),
          ),
          loading: _busy == 'google',
          onPressed: _busy == null
              ? () => _run('google', auth.signInWithGoogle)
              : null,
        ),
        const SizedBox(height: Space.sm),
        NwuButton(
          label: 'Continue with email'.tr,
          tone: ButtonTone.ghost,
          icon: CupertinoIcons.mail,
          onPressed: _busy == null
              ? () => Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => const SignInScreen(),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

/// Human-friendly message for an auth error.
String authErrorMessage(FirebaseAuthException e) => switch (e.code) {
  'invalid-email' => 'That email address doesn’t look right.'.tr,
  'user-not-found' ||
  'wrong-password' ||
  'invalid-credential' => 'Email or password is incorrect.'.tr,
  'email-already-in-use' => 'An account with this email already exists.'.tr,
  'weak-password' => 'Choose a stronger password (6+ characters).'.tr,
  'network-request-failed' => 'No internet connection.'.tr,
  'too-many-requests' => 'Too many attempts. Try again later.'.tr,
  _ => 'Sign-in failed. Please try again.'.tr,
};

class LegalLine extends StatelessWidget {
  const LegalLine({super.key});

  @override
  Widget build(BuildContext context) {
    final link = context.text.caption.copyWith(
      color: context.colors.ink,
      decoration: TextDecoration.underline,
    );
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          Text(
            'By continuing you agree to our '.tr,
            style: context.text.caption,
          ),
          GestureDetector(
            onTap: () => launchUrl(
              Uri.parse(
                'https://github.com/MahdiAbabneh/Terms-of-Use/blob/main/Note%20app%20Terms%20of%20Use',
              ),
            ),
            child: Text('Terms'.tr, style: link),
          ),
          Text(' & '.tr, style: context.text.caption),
          GestureDetector(
            onTap: () => launchUrl(
              Uri.parse(
                'https://github.com/MahdiAbabneh/note-privacy/blob/main/prvacy-policy.md',
              ),
            ),
            child: Text('Privacy Policy'.tr, style: link),
          ),
        ],
      ),
    );
  }
}

/// Three floating sample cards that explain the app at a glance.
class _HeroStack extends StatelessWidget {
  const _HeroStack();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget card({
      required Mood mood,
      required String overline,
      required String text,
      required double angle,
      required Offset offset,
      required int delay,
      IconData? icon,
    }) {
      return Transform.translate(
        offset: offset,
        child: Transform.rotate(
          angle: angle,
          child:
              Container(
                    width: 250,
                    padding: const EdgeInsets.all(Space.lg),
                    decoration: BoxDecoration(
                      color: c.moodTint(mood),
                      borderRadius: BorderRadius.circular(Radii.lg),
                      boxShadow: softShadow(c, strength: 1.4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            if (icon != null) ...[
                              Icon(icon, size: 14, color: c.moodInk(mood)),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              overline.toUpperCase(),
                              style: context.text.overline.copyWith(
                                color: c.moodInk(mood),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Space.xs),
                        Text(
                          text,
                          style: context.text.noteBody.copyWith(fontSize: 17),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: delay.ms, duration: Motion.slow)
                  .slideY(begin: 0.25, curve: Motion.pop, duration: 700.ms)
                  .then()
                  .animate(onPlay: (ctl) => ctl.repeat(reverse: true))
                  .moveY(
                    begin: 0,
                    end: -6,
                    duration: (2200 + delay).ms,
                    curve: Curves.easeInOut,
                  ),
        ),
      );
    }

    return Center(
      child: SizedBox(
        height: 330,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            card(
              mood: Mood.dreamy,
              icon: CupertinoIcons.hourglass,
              overline: 'Opens in 1 year'.tr,
              text: 'Dear future me — did you finally learn the guitar? 🎸'.tr,
              angle: -0.09,
              offset: const Offset(-34, -88),
              delay: 0,
            ),
            card(
              mood: Mood.joy,
              icon: CupertinoIcons.sparkles,
              overline: 'Today’s prompt'.tr,
              text: 'What made you smile today?'.tr,
              angle: 0.07,
              offset: const Offset(40, 6),
              delay: 120,
            ),
            card(
              mood: Mood.love,
              icon: CupertinoIcons.circle_grid_hex_fill,
              overline: 'Circle · Mom'.tr,
              text: 'So proud of you. Dinner on Friday? ❤️'.tr,
              angle: -0.03,
              offset: const Offset(-18, 100),
              delay: 240,
            ),
          ],
        ),
      ),
    );
  }
}
