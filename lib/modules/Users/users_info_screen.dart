import 'package:awesome_dialog/awesome_dialog.dart';
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
import 'package:mahdeko/modules/Porsonal/story_user_screen.dart';
import 'package:mahdeko/modules/Users/chat_screen.dart';
import 'package:mahdeko/network/cache_helper.dart';
import 'package:status_view/status_view.dart';

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
              actions: [IconButton(
                  onPressed: (){
                    showModalBottomSheet(isScrollControlled: true,context: context, builder: (context) =>
                        SizedBox(
                          width: double.infinity,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children:  [
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Text(
                                    reportText.tr,
                                    style: TextStyle(
                                      fontSize: responsive(
                                          context, 16.0, 22.0),
                                    ),
                                  ),
                                ),
                                const Divider(),
                                Padding(
                                  padding: const EdgeInsets.only(right: 10,left: 10),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reportNotePost.tr,
                                        style: TextStyle(
                                          fontSize: responsive(
                                              context, 16.0, 22.0),
                                        ),
                                      ),
                                      const SizedBox(height: 10,),
                                      Row(
                                        children: [
                                          Expanded(
                                            child:
                                            ElevatedButton(
                                              onPressed:
                                                  () {
                                                HomeCubit.get(context)
                                                    .reportUser(cubit.usersList[indexUser!].uId!)
                                                    .whenComplete(() {
                                                  AwesomeDialog(
                                                    customHeader: Icon(FontAwesomeIcons.circleCheck,size:100,color: Theme.of(context).primaryColor,),
                                                    btnOkColor: Theme.of(context).primaryColor,
                                                    btnOkText: okText.tr,
                                                    context: context,
                                                    animType: AnimType.leftSlide,
                                                    headerAnimationLoop: false,
                                                    dialogType: DialogType.success,
                                                    title: reportUserDone.tr,
                                                    btnOkOnPress: () {},
                                                    btnOkIcon: Icons.check_circle,
                                                    onDismissCallback: (type) {},
                                                  ).show().whenComplete(() =>Navigator.pop(context)
                                                  );
                                                });
                                              },
                                              style: ElevatedButton
                                                  .styleFrom(
                                                shape: const RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.all(
                                                      Radius.circular(15.0),
                                                    )),
                                                padding: const EdgeInsets
                                                    .only(
                                                    top:
                                                    3,
                                                    right:
                                                    3,
                                                    left:
                                                    3), backgroundColor: Theme.of(
                                                  context)
                                                  .primaryColor,
                                              ),
                                              child:  Text(
                                                yesText.tr,
                                                style: const TextStyle(
                                                    color: Colors
                                                        .white,
                                                    fontWeight:
                                                    FontWeight
                                                        .bold,
                                                    fontSize:
                                                    20),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 20,
                                          ),
                                          Expanded(
                                            child:
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              style: ElevatedButton
                                                  .styleFrom(
                                                shape: const RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.all(
                                                      Radius.circular(15.0),
                                                    )),
                                                padding: const EdgeInsets
                                                    .only(
                                                    top:
                                                    3,
                                                    right:
                                                    3,
                                                    left:
                                                    3), backgroundColor: Colors
                                                  .white,
                                              ),
                                              child:  Text(
                                                back.tr,
                                                style: const TextStyle(
                                                    color: Colors
                                                        .black,
                                                    fontWeight:
                                                    FontWeight
                                                        .bold,
                                                    fontSize:
                                                    20),
                                              ),
                                            ),
                                          ),

                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding:  EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom,),
                                  child: const SizedBox(height: 20,),
                                ),


                              ],
                            ),
                          ),
                        ));


                  }, icon:const  Icon(FontAwesomeIcons.circleExclamation))],

            ),
            body: ListView(
              children: <Widget>[
                if(state is UserGetImageStoryUsersLoading)
                  LinearProgressIndicator(color: Theme.of(context).primaryColor,backgroundColor:Colors.white ),
                const SizedBox(height: 20,),
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
                                  if(albumUserImages.isEmpty)
                                    CircleAvatar(
                                        backgroundColor:Colors.grey,
                                        minRadius:responsive(context, 93.0, 190.0),
                                        child:CircleAvatar(
                                          backgroundColor: Theme.of(context).primaryColor,
                                          radius:  responsive(context, 90.0, 180.0),
                                          backgroundImage:CachedNetworkImageProvider('${cubit.usersList[indexUser!].image}'),
                                        )),
                                  if(albumUserImages.isNotEmpty)
                                    GestureDetector(onTap: (){
                                   //   navigateTo(context, const StoryUserScreen());
                                    },
                                      child: StatusView(
                                        radius: 90,
                                        spacing: 15,
                                        strokeWidth: 2,
                                        numberOfStatus: albumUserImages.length,
                                        padding: 4,
                                        centerImageUrl: '${cubit.usersList[indexUser!].image}',
                                        seenColor: Colors.grey,
                                        unSeenColor:Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(children: [
                                      SizedBox(height: 20,),
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