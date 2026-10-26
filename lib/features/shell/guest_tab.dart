import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/l10n.dart';
import '../../design/design.dart';
import '../auth/join_sheet.dart';

/// Stands in for a tab that needs an account: what it holds, a few
/// highlights, and a way to join.
class GuestTab extends StatelessWidget {
  const GuestTab({
    super.key,
    required this.overline,
    required this.title,
    required this.emoji,
    required this.headline,
    required this.points,
  });

  final String overline;
  final String title;
  final String emoji;
  final String headline;

  /// (emoji, text) pairs.
  final List<(String, String)> points;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 110,
      ),
      children: [
        PageHeader(overline: overline, title: title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
          child: Container(
            padding: const EdgeInsets.all(Space.lg),
            decoration: BoxDecoration(
              color: c.raised,
              borderRadius: BorderRadius.circular(Radii.lg),
              border: Border.all(color: c.line.withValues(alpha: 0.7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(height: Space.md),
                Text(headline, style: context.text.title),
                const SizedBox(height: Space.md),
                for (final (icon, text) in points)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            icon,
                            style: const TextStyle(fontSize: 17),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            text,
                            style: context.text.body.copyWith(color: c.inkSoft),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: Space.sm),
                NwuButton(
                  label: 'Create your free account'.tr,
                  tone: ButtonTone.accent,
                  onPressed: () => showJoinSheet(context),
                ),
              ],
            ),
          ).animate().fadeIn(duration: Motion.slow).slideY(begin: 0.05),
        ),
      ],
    );
  }
}
