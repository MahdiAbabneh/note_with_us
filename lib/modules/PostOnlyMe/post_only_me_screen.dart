import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:clipboard/clipboard.dart';
import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:empty_widget/empty_widget.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:mahdeko/Compouents/adaptive_indicator.dart';
import 'package:mahdeko/Compouents/constants.dart';
import 'package:mahdeko/Compouents/widgets.dart';
import 'package:mahdeko/Layout/Home/cubit/cubit.dart';
import 'package:mahdeko/Layout/Home/cubit/states.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:readmore/readmore.dart';
import 'package:status_view/status_view.dart';



class PostOnlyMeScreen extends StatefulWidget {
  const PostOnlyMeScreen({super.key});

  @override
  State<PostOnlyMeScreen> createState() => _PostOnlyMeScreenState();
}

class _PostOnlyMeScreenState extends State<PostOnlyMeScreen> {
  @override
  void initState() {
    HomeCubit.get(context).getPostsOnlyMe();
    super.initState();
  }


  @override
  Widget build(BuildContext context) {

    var cubit = HomeCubit.get(context);
    return BlocConsumer<HomeCubit, HomeStates>(
      listener: (context, state) {
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            actions: [  IconButton(
              onPressed:(){
                cubit.pickTime(context).whenComplete(() => {
                  if(cubit.selectedTime!= null)
                    cubit.addReminder(),
                });

              } ,
              icon: const Icon(FontAwesomeIcons.bell,),

            ),],
              title:  Text(personalPage.tr)),
          body: ConditionalBuilder(
            condition:state is! UserGetPostOnlyMeLoading&&cubit.usersList.isNotEmpty ,
            builder: (context) => SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    if(state is  UserSaveImageInGalleryLoading)
                      LinearProgressIndicator(color: Theme.of(context).primaryColor,backgroundColor:Colors.white ),
                    Row(
                      children: [
                        if (cubit.selectedTime!= null)
                          Text(
                            'Alarm will ring ${cubit.ringDay()} at ${cubit.selectedTime!.format(context)}',
                          ),
                        if (cubit.isRinging) Text("'🔔 ${ringing.tr} 🔔'"),
                        const Spacer(),
                        if (cubit.isRinging)
                          RawMaterialButton(
                            onPressed: () async {
                              final stop = await Alarm.stop();
                              if (stop && cubit.isRinging) setState(() => cubit.isRinging = false);
                              cubit.deleteReminder();
                            },
                            fillColor: Theme.of(context).primaryColor,
                            child:  Text(stop.tr,style: const TextStyle(color: Colors.white),),
                          ),
                        if (cubit.selectedTime!= null)
                          RawMaterialButton(
                            onPressed: () async {
                              await Alarm.stop();
                              setState((){
                                cubit.isRinging= false;
                                cubit.selectedTime=null;
                              });
                              cubit.deleteReminder();

                            },
                            fillColor: Theme.of(context).primaryColor,
                            child: Text(undo.tr,style: const TextStyle(color: Colors.white),),
                          ),

                      ],
                    ),
                    if (cubit.selectedTime!= null)
                      const Divider(),
                    if (cubit.selectedTime!= null)
                      const SizedBox(height: 10,),
                    if(cubit.postsListOnlyMe.isEmpty)
                  Center(
                    child: EmptyWidget(
                      hideBackgroundAnimation: true,
                    image: null,
                    packageImage: PackageImage.Image_3,
                    title: noteInfoText.tr,
                    subTitle: noteInfoText2.tr,
                    titleTextStyle: const TextStyle(
                      fontSize: 22,
                      color: Color(0xff9da9c7),
                      fontWeight: FontWeight.w500,
                    ),
                    subtitleTextStyle: const TextStyle(
                      fontSize: 14,
                      color: Color(0xffabb8d6),
                    ),
                ),
                  ),
                    const SizedBox(height: 20,),
                    if(cubit.postsListOnlyMe.isNotEmpty)
                    ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index,) =>
                            buildPostItem(
                              context,
                                index,
                              cubit
                                  .usersMap[cubit
                                  .postsListOnlyMe[index]
                                  .values
                                  .single
                                  .ownerId].image!,
                              cubit
                                  .usersMap[cubit
                                  .postsListOnlyMe[index]
                                  .values
                                  .single
                                  .ownerId].username!,
                              cubit.postsListOnlyMe[index]
                                  .values
                                  .single.time,
                              cubit.postsListOnlyMe[index]
                                  .values
                                  .single
                                  .text,
                                cubit
                                .postsListOnlyMe[index]
                                .values
                                .single
                                .image,
                                    cubit.postsListOnlyMe[index]
                                .values
                                .single
                                .numOfImages,
                                cubit.postsListOnlyMe[index]
                                    .values
                                    .single
                                    .likes,
                                cubit.postsListOnlyMe[index],
                              cubit,
                            ),
                        separatorBuilder: (context, index) => const SizedBox(
                          height: 8.0,
                        ),

                        itemCount:cubit.postsListOnlyMe.length
                    ),
                    const SizedBox(height: 40,),
                  ],
                ),
              ),
            ),
            fallback: (BuildContext context) =>
                const Center(child:AdaptiveIndicator()),
          ),
        );

      });
  }

  Widget buildPostItem(context,index,ownerImage,ownerName,time,text,imagePosts,numImages,likes,post,cubit)

  =>Card(
    shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        borderRadius: BorderRadius.circular(15.0)),
    clipBehavior: Clip.antiAliasWithSaveLayer,
    margin: const EdgeInsets.symmetric(
      horizontal: 8.0,
    ),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusView(
                radius: 40,
                spacing: 15,
                strokeWidth: 2,
                indexOfSeenStatus:numImages,
                numberOfStatus: 3,
                padding: 4,
                centerImageUrl: ownerImage!,
                seenColor: Colors.grey,
                unSeenColor: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 10,),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ownerName!,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor
                    ),
                  ),
                  const SizedBox(height: 3,),
                   Text(HomeCubit.get(context).dateAndTimeFormat(time),style: const TextStyle(fontSize: 12),)
                ],
              ),
              const Spacer(),
              IconButton(onPressed: (){
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
                                deleteNotePostText.tr,
                                style: TextStyle(
                                  fontSize: responsive(
                                      context, 16.0, 22.0),
                                ),
                              ),
                            ),
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.only(right: 10,left: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child:
                                    ElevatedButton(
                                      onPressed:
                                          () {
                                                    HomeCubit.get(context)
                                                        .deletePostOnlyMe(post)
                                                        .whenComplete(() {
                                                      Navigator.pop(context);
                                                      HomeCubit.get(context)
                                                          .getPostsOnlyMe();});
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
                            ),
                            Padding(
                              padding:  EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom,),
                              child: const SizedBox(height: 20,),
                            ),


                          ],
                        ),
                      ),
                    ));



              }, icon:const Icon(FontAwesomeIcons.trash))
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 15.0,
            ),
            child: Container(
              width: double.infinity,
              height: 1.0,
              color: Colors.grey[300],
            ),
          ),


               ReadMoreText(
                 text,
                trimLines: 8,
                colorClickableText: Colors.pink,
                trimMode: TrimMode.Line,
                trimCollapsedText: showMore.tr,
                trimExpandedText: showLess.tr,
                moreStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10,),
          SizedBox(height:imagePosts.length!=0? 300:0,
            child: PhotoViewGallery.builder(
              itemCount: imagePosts.length,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider:NetworkImage(imagePosts[index],),
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 2,
                );
              },
              scrollPhysics: const BouncingScrollPhysics(),
              backgroundDecoration: BoxDecoration(
                borderRadius:const BorderRadius.all(Radius.circular(20)),
                color: Theme.of(context).canvasColor,
              ),
              enableRotation:true,
              loadingBuilder: (context, event) => Center(
                child: SizedBox(
                  width: 30.0,
                  height: 30.0,
                  child: CircularProgressIndicator(
                    backgroundColor:Colors.grey,
                    value: event == null
                        ? 0
                        : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10,),

          Padding(
            padding: const EdgeInsets.only(
              bottom: 10.0,
            ),
            child: Container(
              width: double.infinity,
              height: 1.0,
              color: Colors.grey[300],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(children: [
              Spacer(),
              if(text!="")
                IconButton(
                    onPressed: (){
                      FlutterClipboard.copy(text);
                      showToastSuccess(copyText.tr, context);
                      AwesomeDialog(
                        btnOkText: okText.tr,
                        context: context,
                        animType: AnimType.leftSlide,
                        headerAnimationLoop: false,
                        dialogType: DialogType.success,
                        showCloseIcon: true,
                        title: copiedTextDone.tr,
                        btnOkOnPress: () {},
                        btnOkIcon: Icons.check_circle,
                        onDismissCallback: (type) {},
                      ).show();
                    },
                    icon:  Icon ( FontAwesomeIcons.fileText,color: Theme.of(context).primaryColor,)
                ),
              if(imagePosts.isNotEmpty)
                IconButton(
                    onPressed: (){
                      showToastSuccess(saveText.tr, context);
                      HomeCubit.get(context).saveImageInGallery(imagePosts).whenComplete((){
                        AwesomeDialog(
                          btnOkText: okText.tr,
                          context: context,
                          animType: AnimType.leftSlide,
                          headerAnimationLoop: false,
                          dialogType: DialogType.success,
                          showCloseIcon: true,
                          title: saveImageDone.tr,
                          btnOkOnPress: () {},
                          btnOkIcon: Icons.check_circle,
                          onDismissCallback: (type) {},
                        ).show();
                      });
                    },
                    icon:  Icon ( FontAwesomeIcons.fileImage,color: Theme.of(context).primaryColor,)
                ),
              Spacer(),
            ]),
          ),
        ],
      ),
    ),
  );
}
