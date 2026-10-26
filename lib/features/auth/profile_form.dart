import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../data/auth_service.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import '../compose/compose_screen.dart';

/// State for the name, birthday and gender fields.
class ProfileFormController extends ChangeNotifier {
  ProfileFormController({String name = ''})
    : name = TextEditingController(text: name);

  final TextEditingController name;
  DateTime? birthDate;
  String? gender;

  String get birthDateString => formatBirthDate(birthDate!);

  void setBirthDate(DateTime date) {
    birthDate = date;
    notifyListeners();
  }

  void setGender(String value) {
    gender = value;
    notifyListeners();
  }

  /// Checks the non-text fields and explains what is missing.
  bool validate(BuildContext context) {
    if (birthDate == null) {
      showToast(context, 'Add your date of birth'.tr, error: true);
      return false;
    }
    if (gender == null) {
      showToast(context, 'Choose an option for gender'.tr, error: true);
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }
}

/// Name, birthday and gender inputs shared by sign-up and onboarding.
class ProfileFields extends StatelessWidget {
  const ProfileFields({super.key, required this.controller});

  final ProfileFormController controller;

  Future<void> _pickBirthDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await pickDate(
      context,
      initial:
          controller.birthDate ?? DateTime(now.year - 20, now.month, now.day),
      minimum: DateTime(now.year - 100),
      maximum: DateTime(now.year - 13, now.month, now.day),
    );
    if (picked != null) controller.setBirthDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NwuField(
            controller: controller.name,
            label: 'Your name'.tr,
            icon: CupertinoIcons.person,
            maxLength: 24,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            validator: (v) => (v ?? '').trim().length < 3
                ? 'Name must be at least 3 characters'.tr
                : null,
          ),
          const SizedBox(height: Space.lg),
          Text(
            'Date of birth'.tr,
            style: context.text.label.copyWith(color: c.inkSoft),
          ),
          const SizedBox(height: Space.xs),
          Pressable(
            onTap: () => _pickBirthDate(context),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: Space.md),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(color: c.line),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.gift, size: 20, color: c.muted),
                  const SizedBox(width: Space.sm),
                  Text(
                    controller.birthDate == null
                        ? 'Choose a date'.tr
                        : fullDate(controller.birthDate!),
                    style: context.text.body.copyWith(
                      color: controller.birthDate == null ? c.muted : c.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.lg),
          Text(
            'Gender'.tr,
            style: context.text.label.copyWith(color: c.inkSoft),
          ),
          const SizedBox(height: Space.xs),
          Row(
            children: [
              for (final (value, label) in const [
                ('Male', 'Male'),
                ('Female', 'Female'),
              ]) ...[
                Expanded(
                  child: Pressable(
                    onTap: () => controller.setGender(value),
                    child: AnimatedContainer(
                      duration: Motion.base,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: controller.gender == value ? c.ink : c.surface,
                        borderRadius: BorderRadius.circular(Radii.md),
                        border: Border.all(
                          color: controller.gender == value ? c.ink : c.line,
                        ),
                      ),
                      child: Text(
                        label.tr,
                        style: context.text.label.copyWith(
                          color: controller.gender == value ? c.canvas : c.ink,
                        ),
                      ),
                    ),
                  ),
                ),
                if (value == 'Male') const SizedBox(width: Space.sm),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Shown after Google or Apple sign-in when no profile exists yet.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _profile = ProfileFormController(
    name: Session.instance.authUser?.displayName ?? '',
  );
  bool _loading = false;

  @override
  void dispose() {
    _profile.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || !_profile.validate(context)) return;
    setState(() => _loading = true);
    final session = Session.instance;
    try {
      await session.users.createProfile(
        uid: session.uid,
        email: session.authUser?.email ?? '',
        username: _profile.name.text.trim(),
        dateOfBirth: _profile.birthDateString,
        gender: _profile.gender!,
        token: await AuthService.pushToken(),
      );
    } catch (_) {
      if (mounted) showToast(context, 'Something went wrong'.tr, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              Space.xxl,
              Space.gutter,
              Space.xxl,
            ),
            children: [
              Text('👋', style: const TextStyle(fontSize: 44)),
              const SizedBox(height: Space.md),
              Text('One last step'.tr, style: context.text.display),
              const SizedBox(height: Space.xs),
              Text(
                'Tell us a little about you so friends can find you.'.tr,
                style: context.text.small,
              ),
              const SizedBox(height: Space.xxl),
              ProfileFields(controller: _profile),
              const SizedBox(height: Space.xxl),
              NwuButton(
                label: 'Continue'.tr,
                loading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: Space.sm),
              NwuButton(
                label: 'Use a different account'.tr,
                tone: ButtonTone.ghost,
                onPressed: () => Session.instance.auth.signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
