import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:mahdeko/Compouents/constants.dart';
import 'package:mahdeko/Compouents/widgets.dart';
import 'package:mahdeko/Layout/Home/cubit/cubit.dart';
import 'package:mahdeko/Layout/Home/cubit/states.dart';
import 'package:mahdeko/network/cache_helper.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});


  @override
  Widget build(BuildContext context) {
    var cubit = HomeCubit.get(context);
    return BlocConsumer<HomeCubit, HomeStates>(
      listener: (context, state) {
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
              title:  Text(homepage.tr)),
          body:Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(alignment: Alignment.center,
                  children:[
                    Opacity(

                      opacity: 0.3,
                      child: Image.asset("assets/images/NWU.png",
                        fit: BoxFit.cover,height: responsive(context, 250.0, 500.0),),),
                    Stack(alignment:CacheHelper.getData(key:"lang")=="ar"?Alignment.topRight:Alignment.topLeft ,
                      children: [
                        Container(
                        decoration: const BoxDecoration(
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            CircleAvatar(
                                backgroundColor:Theme.of(context).primaryColor,
                                minRadius: 95.0,
                                child:CircleAvatar(
                                  radius: 90.0,
                                  backgroundImage:
                                  AssetImage("assets/images/NWU.png",),
                                )),
                            const SizedBox(
                              height: 5,
                            ),
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(15.0)),
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              child: Text(
                                textAlign: TextAlign.center,
                                "Mahdi Ababneh  ",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                        IconButton(
                            onPressed: (){
                            },
                            icon: Icon(Icons.camera_alt_outlined,color: Theme.of(context).primaryColor,size: 35,)),
                      ]
                    ),
                  ]
              ),
            ],
          ),
        );

      });
  }


}

