import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show InputBorder, InputDecoration, Scaffold, TextField;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/l10n.dart';
import '../../core/tags.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';

/// Rejects any change that deletes text or pastes a lot at once, so
/// free writing keeps moving forward: no editing, just letting it out.
class ForwardOnlyFormatter extends TextInputFormatter {
  /// Most characters one change may add; autocorrect and emoji stay under
  /// this, a paste does not.
  static const maxAdded = 12;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final grew = newValue.text.length - oldValue.text.length;
    if (grew < 0 || grew > maxAdded) return oldValue;
    // Typing only ever happens at the end.
    if (!newValue.text.startsWith(oldValue.text)) return oldValue;
    return newValue.copyWith(
      selection: TextSelection.collapsed(offset: newValue.text.length),
    );
  }
}

/// Number of words in [text], in any script.
int wordCount(String text) =>
    RegExp(r'[\p{L}\p{N}]+', unicode: true).allMatches(text).length;

enum _Stage { setup, writing, done }

/// Write without stopping for a few minutes, with no deleting, to get
/// what is in your head out. Afterwards keep it in your journal or let
/// it go. Pops `true` if a note was saved.
class FreeWriteScreen extends StatefulWidget {
  const FreeWriteScreen({super.key});

  @override
  State<FreeWriteScreen> createState() => _FreeWriteScreenState();
}

class _FreeWriteScreenState extends State<FreeWriteScreen> {
  static const _durations = [3, 5, 10];

  final _session = Session.instance;
  final _text = TextEditingController();
  final _focus = FocusNode();
  _Stage _stage = _Stage.setup;
  int _minutes = 5;
  late DateTime _endsAt;
  Timer? _timer;
  Duration _left = Duration.zero;
  DateTime _lastTyped = DateTime.now();
  Mood _mood = Mood.plain;
  bool _saving = false;

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _start() {
    HapticFeedback.mediumImpact();
    setState(() {
      _stage = _Stage.writing;
      _endsAt = DateTime.now().add(Duration(minutes: _minutes));
      _left = Duration(minutes: _minutes);
      _lastTyped = DateTime.now();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _focus.requestFocus();
  }

  void _tick() {
    final left = _endsAt.difference(DateTime.now());
    if (left <= Duration.zero) {
      _finish();
    } else {
      setState(() => _left = left);
    }
  }

  void _finish() {
    _timer?.cancel();
    _focus.unfocus();
    HapticFeedback.heavyImpact();
    setState(() => _stage = _Stage.done);
  }

  Future<bool> _confirmLeave() async {
    if (_stage != _Stage.writing || _text.text.trim().isEmpty) return true;
    return confirm(
      context,
      title: 'Leave free writing?'.tr,
      message: 'What you have written so far will be lost.'.tr,
      confirmLabel: 'Leave'.tr,
      destructive: true,
    );
  }

  Future<void> _save() async {
    final text = _text.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await _session.notes.create(
        author: _session.me,
        audience: Audience.private,
        text: text,
        mood: _mood,
        prompt: 'Free writing'.tr,
      );
      RecentTags.record(text);
      if (!mounted) return;
      Navigator.pop(context, true);
      showToast(context, 'Saved to your journal'.tr);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showToast(context, 'Something went wrong'.tr, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _stage != _Stage.writing || _text.text.trim().isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: TopBar(close: true, title: 'Free writing'.tr),
        body: switch (_stage) {
          _Stage.setup => _setup(context),
          _Stage.writing => _writing(context),
          _Stage.done => _done(context),
        },
      ),
    );
  }

  Widget _setup(BuildContext context) {
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.all(Space.gutter),
      children: [
        Text('Let it all out'.tr, style: context.text.display),
        const SizedBox(height: Space.xs),
        Text(
          'Write without stopping. You can’t delete, so there is nothing to fix. Don’t judge it, just keep going.'
              .tr,
          style: context.text.body.copyWith(color: c.inkSoft),
        ),
        const SizedBox(height: Space.xl),
        Text('HOW LONG'.tr, style: context.text.overline),
        const SizedBox(height: Space.sm),
        SegmentedPills(
          labels: [
            for (final m in _durations) '{n} min'.tr.replaceAll('{n}', '$m'),
          ],
          index: _durations.indexOf(_minutes),
          onChanged: (i) => setState(() => _minutes = _durations[i]),
        ),
        const SizedBox(height: Space.xl),
        NwuButton(
          label: 'Start writing'.tr,
          icon: CupertinoIcons.timer,
          tone: ButtonTone.accent,
          onPressed: _start,
        ),
        const SizedBox(height: Space.md),
        Text(
          'It is saved only if you choose to keep it.'.tr,
          style: context.text.caption,
          textAlign: TextAlign.center,
        ),
      ],
    ).animate().fadeIn(duration: Motion.slow);
  }

  Widget _writing(BuildContext context) {
    final c = context.colors;
    final total = Duration(minutes: _minutes);
    final progress = 1 - _left.inMilliseconds / total.inMilliseconds;
    final idle = DateTime.now().difference(_lastTyped).inSeconds >= 6;
    final mm = _left.inMinutes.toString();
    final ss = (_left.inSeconds % 60).toString().padLeft(2, '0');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            0,
            Space.gutter,
            Space.xs,
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.pill),
                child: SizedBox(
                  height: 6,
                  child: Stack(
                    children: [
                      Container(color: c.line),
                      FractionallySizedBox(
                        widthFactor: progress.clamp(0, 1),
                        child: Container(color: c.accent),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Space.xs),
              Row(
                children: [
                  Text('$mm:$ss', style: context.text.title),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: Motion.base,
                    opacity: idle ? 1 : 0,
                    child: Text(
                      'Keep going, write whatever comes…'.tr,
                      style: context.text.caption.copyWith(color: c.accent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
            child: TextField(
              controller: _text,
              focusNode: _focus,
              autofocus: true,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              textDirection: inputDirection(context, _text.text),
              autocorrect: false,
              enableSuggestions: false,
              enableInteractiveSelection: false,
              contextMenuBuilder: (context, state) => const SizedBox.shrink(),
              inputFormatters: [ForwardOnlyFormatter()],
              onChanged: (_) => setState(() => _lastTyped = DateTime.now()),
              style: context.text.noteBody.copyWith(fontSize: 20),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Start anywhere…'.tr,
                hintStyle: context.text.noteBody.copyWith(
                  fontSize: 20,
                  color: c.muted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _done(BuildContext context) {
    final c = context.colors;
    final words = wordCount(_text.text);
    final empty = _text.text.trim().isEmpty;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        Space.gutter,
        Space.sm,
        Space.gutter,
        MediaQuery.of(context).padding.bottom + Space.xl,
      ),
      children: [
        Text('Well done'.tr, style: context.text.display),
        const SizedBox(height: Space.xs),
        Text(
          (words == 1 ? '1 word in {n} minutes.' : '{w} words in {n} minutes.')
              .tr
              .replaceAll('{w}', '$words')
              .replaceAll('{n}', '$_minutes'),
          style: context.text.body.copyWith(color: c.inkSoft),
        ),
        const SizedBox(height: Space.lg),
        if (!empty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Space.md),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(Radii.lg),
            ),
            child: ContentText(
              _text.text.trim(),
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
              style: context.text.noteBody.copyWith(fontSize: 16),
            ),
          ),
          const SizedBox(height: Space.lg),
          Text('HOW DO YOU FEEL NOW?'.tr, style: context.text.overline),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final mood in Mood.values.where((m) => m != Mood.plain))
                Pressable(
                  onTap: () =>
                      setState(() => _mood = _mood == mood ? Mood.plain : mood),
                  child: AnimatedContainer(
                    duration: Motion.base,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _mood == mood ? c.moodTint(mood) : null,
                      borderRadius: BorderRadius.circular(Radii.pill),
                      border: Border.all(
                        color: _mood == mood ? c.moodInk(mood) : c.line,
                      ),
                    ),
                    child: Text(
                      '${mood.emoji} ${mood.label.tr}',
                      style: context.text.caption.copyWith(color: c.ink),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.xl),
          NwuButton(
            label: 'Keep it in my journal'.tr,
            tone: ButtonTone.accent,
            loading: _saving,
            onPressed: _save,
          ),
          const SizedBox(height: Space.xs),
        ],
        NwuButton(
          label: (empty ? 'Close' : 'Let it go').tr,
          tone: ButtonTone.ghost,
          onPressed: () => Navigator.pop(context, false),
        ),
      ],
    );
  }
}
