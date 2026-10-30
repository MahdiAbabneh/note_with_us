import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/hijri.dart';
import '../../core/islamic.dart';
import '../../core/l10n.dart';
import '../../core/settings.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import '../compose/compose_screen.dart';
import 'ramadan_screen.dart';

/// Whether today's writing prompt is Ramadan's: during Ramadan, with
/// Ramadan and Eid features on, it replaces the usual daily prompt.
bool ramadanPromptShows(DateTime now) =>
    AppSettings.instance.islamic && occasionOn(now) == IslamicOccasion.ramadan;

/// A card on Today for Ramadan, Eid, and the days just after Ramadan.
/// Shows nothing the rest of the year, or when the features are off.
class OccasionCard extends StatelessWidget {
  const OccasionCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppSettings.instance.islamic) return const SizedBox.shrink();
    final now = DateTime.now();
    final occasion = occasionOn(now);
    final Widget? card = switch (occasion) {
      IslamicOccasion.ramadan => _RamadanCard(day: ramadanDay(now) ?? 1),
      IslamicOccasion.eidAlFitr ||
      IslamicOccasion.eidAlAdha => _EidCard(occasion: occasion!),
      _ => isAfterRamadan(now) ? const _RamadanLook() : null,
    };
    if (card == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.md,
        Space.gutter,
        0,
      ),
      child: card,
    ).animate().fadeIn(duration: Motion.slow).slideY(begin: 0.05);
  }
}

void _openRamadan(BuildContext context) => Navigator.of(
  context,
).push(CupertinoPageRoute<void>(builder: (_) => const RamadanScreen()));

class _Shell extends StatelessWidget {
  const _Shell({required this.overline, required this.child});

  final String overline;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: c.accentSoft,
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌙', style: TextStyle(fontSize: 18)),
              const SizedBox(width: Space.xs),
              Expanded(
                child: Text(
                  overline.toUpperCase(),
                  style: context.text.overline.copyWith(color: c.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          child,
        ],
      ),
    );
  }
}

class _RamadanCard extends StatelessWidget {
  const _RamadanCard({required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    final prompt = ramadanPrompt(day);
    final tag = L10n.arabic ? '#رمضان ' : '#ramadan ';
    return _Shell(
      overline: 'Ramadan · day {n}'.tr.replaceAll('{n}', '$day'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(prompt, style: context.text.noteBody.copyWith(fontSize: 17)),
          const SizedBox(height: Space.sm),
          Row(
            children: [
              NwuButton(
                label: 'Write'.tr,
                tone: ButtonTone.accent,
                compact: true,
                expand: false,
                onPressed: () => openComposer(
                  context,
                  prompt: prompt,
                  target: ComposeTarget.private,
                  text: tag,
                ),
              ),
              const SizedBox(width: Space.xs),
              NwuButton(
                label: 'Your Ramadan'.tr,
                tone: ButtonTone.ghost,
                compact: true,
                expand: false,
                onPressed: () => _openRamadan(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EidCard extends StatelessWidget {
  const _EidCard({required this.occasion});

  final IslamicOccasion occasion;

  @override
  Widget build(BuildContext context) {
    final fitr = occasion == IslamicOccasion.eidAlFitr;
    final session = Session.instance;
    return _Shell(
      overline: occasion.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Eid Mubarak!'.tr, style: context.text.title),
          const SizedBox(height: 2),
          Text(
            'Share a greeting with the people you love.'.tr,
            style: context.text.small,
          ),
          const SizedBox(height: Space.sm),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              NwuButton(
                label: 'Write an Eid note'.tr,
                tone: ButtonTone.accent,
                compact: true,
                expand: false,
                onPressed: () => openComposer(
                  context,
                  target: session.circle.isEmpty
                      ? ComposeTarget.private
                      : ComposeTarget.circle,
                  text: eidGreeting(occasion),
                ),
              ),
              if (fitr)
                NwuButton(
                  label: 'Your Ramadan'.tr,
                  tone: ButtonTone.ghost,
                  compact: true,
                  expand: false,
                  onPressed: () => _openRamadan(context),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A nudge to look back at Ramadan in the days after Eid al-Fitr.
class _RamadanLook extends StatelessWidget {
  const _RamadanLook();

  @override
  Widget build(BuildContext context) {
    final year = hijriYearOf(DateTime.now());
    return _Shell(
      overline: 'Your Ramadan'.tr,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Look back at Ramadan {year}'.tr.replaceAll('{year}', '$year'),
              style: context.text.label,
            ),
          ),
          NwuButton(
            label: 'Open'.tr,
            tone: ButtonTone.accent,
            compact: true,
            expand: false,
            onPressed: () => _openRamadan(context),
          ),
        ],
      ),
    );
  }
}
