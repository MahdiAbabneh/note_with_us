import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/l10n.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import 'profile_form.dart';
import 'welcome_screen.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? _validateEmail(String? v) =>
    _emailPattern.hasMatch((v ?? '').trim()) ? null : 'Enter a valid email'.tr;

/// Email sign-in, with a link to create an account.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Session.instance.auth.signInWithEmail(
        _email.text.trim(),
        _password.text,
      );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      if (mounted) showToast(context, authErrorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    if (_validateEmail(_email.text) != null) {
      showToast(context, 'Type your email first'.tr, error: true);
      return;
    }
    try {
      await Session.instance.auth.sendPasswordReset(_email.text.trim());
      if (mounted) showToast(context, 'Check your inbox for a reset link'.tr);
    } on FirebaseAuthException catch (e) {
      if (mounted) showToast(context, authErrorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(),
      body: Form(
        key: _form,
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              Space.md,
              Space.gutter,
              Space.xxl,
            ),
            children:
                [
                      Text('Welcome back'.tr, style: context.text.display),
                      const SizedBox(height: Space.xs),
                      Text(
                        'Sign in to see what your circle shared.'.tr,
                        style: context.text.small,
                      ),
                      const SizedBox(height: Space.xxl),
                      NwuField(
                        controller: _email,
                        label: 'Email'.tr,
                        icon: CupertinoIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: Space.lg),
                      NwuField(
                        controller: _password,
                        label: 'Password'.tr,
                        icon: CupertinoIcons.lock,
                        obscure: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => _submit(),
                        validator: (v) => (v ?? '').length < 6
                            ? 'At least 6 characters'.tr
                            : null,
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: _reset,
                          child: Text(
                            'Forgot password?'.tr,
                            style: context.text.label.copyWith(
                              color: context.colors.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.md),
                      NwuButton(
                        label: 'Sign in'.tr,
                        loading: _loading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: Space.lg),
                      Center(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('New here? '.tr, style: context.text.small),
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                CupertinoPageRoute<void>(
                                  builder: (_) => const SignUpScreen(),
                                ),
                              ),
                              child: Text(
                                'Create an account'.tr,
                                style: context.text.label.copyWith(
                                  color: context.colors.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                    .animate(interval: 40.ms)
                    .fadeIn(duration: Motion.base)
                    .slideY(begin: 0.05),
          ),
        ),
      ),
    );
  }
}

/// Email sign-up with profile details.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _profile = ProfileFormController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _profile.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || !_profile.validate(context)) return;
    setState(() => _loading = true);
    try {
      await Session.instance.auth.signUpWithEmail(
        email: _email.text.trim(),
        password: _password.text,
        username: _profile.name.text.trim(),
        dateOfBirth: _profile.birthDateString,
        gender: _profile.gender!,
      );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      if (mounted) showToast(context, authErrorMessage(e), error: true);
    } catch (_) {
      if (mounted) showToast(context, 'Something went wrong'.tr, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBar(),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            Space.md,
            Space.gutter,
            Space.xxl,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Text('Create your account'.tr, style: context.text.display),
            const SizedBox(height: Space.xs),
            Text('It takes less than a minute.'.tr, style: context.text.small),
            const SizedBox(height: Space.xxl),
            ProfileFields(controller: _profile),
            const SizedBox(height: Space.lg),
            NwuField(
              controller: _email,
              label: 'Email'.tr,
              icon: CupertinoIcons.mail,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: _validateEmail,
            ),
            const SizedBox(height: Space.lg),
            NwuField(
              controller: _password,
              label: 'Password'.tr,
              icon: CupertinoIcons.lock,
              obscure: true,
              autofillHints: const [AutofillHints.newPassword],
              validator: (v) =>
                  (v ?? '').length < 6 ? 'At least 6 characters'.tr : null,
            ),
            const SizedBox(height: Space.xxl),
            NwuButton(
              label: 'Create account'.tr,
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
