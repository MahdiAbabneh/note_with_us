import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:mahdeko/Compouents/constants.dart';
import 'package:mahdeko/Layout/Home/cubit/cubit.dart';
import 'package:mahdeko/Layout/Home/cubit/states.dart';


class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});


  @override
  Widget build(BuildContext context) {
    var cubit = HomeCubit.get(context);
    return BlocConsumer<HomeCubit, HomeStates>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
              title:  Text(funText.tr)),
          body:StatefulBuilder(
            builder: (context, setState) =>
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 2,
                              mainAxisSpacing: 2,
                              crossAxisSpacing: 50,
                              mainAxisExtent: 180),
                          itemBuilder: (context, index) =>
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    switch (index) {
                                      case 0:
                                        cubit.launchURLBrowser("https://www.towergame.app/");
                                        break;
                                      case 1:
                                        cubit.launchURLBrowser("https://tmaiadev-tictactoe.netlify.app/");
                                        break;
                                      case 2:
                                        cubit.launchURLBrowser("https://amongusplay.online/");
                                        break;
                                      case 3:
                                        cubit.launchURLBrowser("https://bsehovac.github.io/the-cube/");
                                        break;
                                      case 4:
                                        cubit.launchURLBrowser("https://cardgames.io/chess/");
                                        break;
                                      case 5:
                                        cubit.launchURLBrowser("https://playcanv.as/p/JtL2iqIH/");
                                        break;
                                      case 6:
                                        cubit.launchURLBrowser("https://bubblepairs.apps.in.rs/");
                                        break;
                                      case 7:
                                        cubit.launchURLBrowser("https://html5.gamedistribution.com/f2520bae00624e93a4f4614732fa259e/?gd_sdk_referrer_url=https%3A%2F%2Fwww.miniplay.com%2Fgame%2Funo&mp_game_id=10635&mp_game_uid=uno&mp_game_url=https%3A%2F%2Fwww.miniplay.com%2Fgame%2Funo%2Fplay&mp_int=1&mp_locale=en_US&mp_mobile=1&mp_player_type=IFRAME&mp_site_name=miniplay.com&mp_site_url=https%3A%2F%2Fwww.miniplay.com%2F&mp_timezone=Europe%2FMadrid");
                                        break;
                                    }
                                  });
                                },
                                child: Column(
                                  children: [
                                    Image.asset('assets/images/${imgGameList[index]}.png',fit: BoxFit.fill),
                                    Expanded(
                                      child: Text(
                                        imgGameList[index].tr,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          itemCount: imgGameList.length,
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        );
      },
    );
}


}

final List<String> imgGameList = [
  "Tower game",
  "Tic-tac-toe",
  "Among Us",
  "The cube",
  "Chess",
  "Swooop",
  "Bubble Pairs",
  "UNO",
];



