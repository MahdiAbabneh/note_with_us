import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:mahdeko/Compouents/constant_empty.dart';
import 'package:mahdeko/Compouents/constants.dart';
import 'package:mahdeko/Compouents/widgets.dart';
import 'package:mahdeko/Layout/Home/cubit/cubit.dart';
import 'package:mahdeko/Layout/Home/cubit/states.dart';
import 'package:mahdeko/modules/Users/chat_screen.dart';
import 'package:mahdeko/network/cache_helper.dart';

class UsersInfoScreen extends StatelessWidget {
  const UsersInfoScreen({super.key});


  @override
  Widget build(BuildContext context) {
    var cubit = HomeCubit.get(context);
    return BlocConsumer<HomeCubit, HomeStates>(
        listener: (context, state) {},
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title:  Text(cubit.usersList[indexUser!].username!),

            ),
            body: ListView(
              children: <Widget>[
                const SizedBox(height: 8,),
                Stack(alignment: Alignment.center,
                    children:[
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
                                      minRadius:responsive(context, 93.0, 190.0),
                                      child:CircleAvatar(
                                        backgroundColor: Theme.of(context).primaryColor,
                                        radius:  responsive(context, 90.0, 180.0),
                                        backgroundImage:CachedNetworkImageProvider('${cubit.usersList[indexUser!].image}'),
                                      )),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(children: [
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor,
                                            borderRadius: BorderRadius.circular(15.0)),
                                        clipBehavior: Clip.antiAliasWithSaveLayer,
                                        child: Text(
                                          textAlign: TextAlign.center,
                                          cubit.usersList[indexUser!].username!,
                                          style:  TextStyle(
                                            fontSize: responsive(context, 20.0, 26.0),
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10,),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor,
                                            borderRadius: BorderRadius.circular(15.0)),
                                        clipBehavior: Clip.antiAliasWithSaveLayer,
                                        child: Text(
                                          textAlign: TextAlign.center,
                                          "${cubit.durationUserAge!.years} ${years.tr}",
                                          style:  TextStyle(
                                            fontSize:  responsive(context, 20.0, 26.0),
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10,),
                                      if(cubit.usersList[indexUser!].location!="")
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor,
                                            borderRadius: BorderRadius.circular(15.0)),
                                        clipBehavior: Clip.antiAliasWithSaveLayer,
                                        child: Text(
                                          textAlign: TextAlign.center,
                                          cubit.usersList[indexUser!].location!,
                                          style:  TextStyle(
                                            fontSize:  responsive(context, 20.0, 26.0),
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],),
                                  ),
                                  const Divider(),
                                ],
                              ),
                            ),
                          ]
                      ),
                    ]
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    IconButton(onPressed: (){
                      cubit.messageController.text = "";
                      navigateTo(context,  ChatScreen(userDataModel: cubit.usersList[indexUser!]));
                    },
                        icon:  Icon(FontAwesomeIcons.commenting,color: Theme.of(context).primaryColor,size: 45,)),
                    const Spacer(),
                    IconButton(onPressed: ()async{
                      if(cubit.usersList[indexUser!].phoneNumber != ""){
                        await FlutterPhoneDirectCaller.callNumber('${cubit.usersList[indexUser!].phoneNumber}');
                      }else{
                        showToastFailed(toast8.tr,context);
                      }
                    },
                        icon: Icon(FontAwesomeIcons.phone,color: Theme.of(context).primaryColor,size: 45,)),
                    const Spacer(),
                  ],),
                const SizedBox(height: 8,),
                const Divider(),
              ],
            ),
          );

        });
  }


}