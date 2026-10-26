import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n.dart';
import '../../design/design.dart';

const _games = [
  ('Tower game', 'https://www.towergame.app/'),
  ('Tic-tac-toe', 'https://tmaiadev-tictactoe.netlify.app/'),
  ('Among Us', 'https://amongusplay.online/'),
  ('The cube', 'https://bsehovac.github.io/the-cube/'),
  ('Chess', 'https://cardgames.io/chess/'),
  ('Swooop', 'https://playcanv.as/p/JtL2iqIH/'),
  ('Bubble Pairs', 'https://bubblepairs.apps.in.rs/'),
  (
    'UNO',
    'https://html5.gamedistribution.com/f2520bae00624e93a4f4614732fa259e/?gd_sdk_referrer_url=https%3A%2F%2Fwww.miniplay.com%2Fgame%2Funo&mp_game_id=10635&mp_game_uid=uno&mp_game_url=https%3A%2F%2Fwww.miniplay.com%2Fgame%2Funo%2Fplay&mp_int=1&mp_locale=en_US&mp_mobile=1&mp_player_type=IFRAME&mp_site_name=miniplay.com&mp_site_url=https%3A%2F%2Fwww.miniplay.com%2F&mp_timezone=Europe%2FMadrid',
  ),
];

/// Small browser games, kept from the original app.
class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: TopBar(title: 'For fun'.tr),
      body: GridView.builder(
        padding: const EdgeInsets.all(Space.gutter),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: Space.md,
          crossAxisSpacing: Space.md,
          childAspectRatio: 0.85,
        ),
        itemCount: _games.length,
        itemBuilder: (context, i) {
          final (name, url) = _games[i];
          return Pressable(
            onTap: () => launchUrl(Uri.parse(url)),
            child:
                Container(
                      decoration: BoxDecoration(
                        color: c.raised,
                        borderRadius: BorderRadius.circular(Radii.lg),
                        border: Border.all(
                          color: c.line.withValues(alpha: 0.7),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Image.asset(
                              'assets/images/$name.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(Space.sm),
                            child: Text(name.tr, style: context.text.label),
                          ),
                        ],
                      ),
                    )
                    .animate(delay: (i * 40).ms)
                    .fadeIn()
                    .scale(begin: const Offset(0.95, 0.95), curve: Motion.ease),
          );
        },
      ),
    );
  }
}
