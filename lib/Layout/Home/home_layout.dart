import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:clipboard/clipboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:mahdeko/Compouents/adaptive_indicator.dart';
import 'package:mahdeko/Compouents/constant_empty.dart';
import 'package:mahdeko/Compouents/constants.dart';
import 'package:mahdeko/Compouents/widgets.dart';
import 'package:mahdeko/modules/CreateNote/create_note_screen.dart';
import 'package:mahdeko/modules/Games/games_screen.dart';
import 'package:mahdeko/modules/Porsonal/profile_screen.dart';
import 'package:mahdeko/modules/PostOnlyMe/post_only_me_screen.dart';
import 'package:mahdeko/modules/Users/users_screen.dart';
import 'package:mahdeko/network/cache_helper.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:readmore/readmore.dart';
import 'package:status_view/status_view.dart';
import 'cubit/cubit.dart';
import 'cubit/states.dart';

class HomeLayout extends StatelessWidget {
  const HomeLayout({super.key});


  @override
  Widget build(BuildContext context) {

    var cubit = HomeCubit.get(context);
    return BlocConsumer<HomeCubit, HomeStates>(
      listener: (context, state) {},
      builder: (context, state) {
        if(state is UserGetGetUsers)
          {
            cubit.getUserData().then((value) => cubit.getPosts());
          }
        return Scaffold(
          appBar: AppBar(
              automaticallyImplyLeading: false,
            actions: [const Icon(FontAwesomeIcons.moon),Switch(value: darkMoodData!, onChanged: (val){
              Get.changeThemeMode(val?ThemeMode.dark:ThemeMode.light);
              CacheHelper.sharedPreferences?.setBool("darkMood", val);
              darkMoodData=val;
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid).update(
                  {"darkMood": val});

              
            })],
              title:  Text(homepage.tr)),
          bottomNavigationBar: ConvexAppBar(
              color: Colors.white,
              activeColor: Colors.white,
              style:TabStyle.fixedCircle,
              initialActiveIndex: 0,
              backgroundColor: Theme.of(context).primaryColor,
              items:  [
                const TabItem(icon: Icon(FontAwesomeIcons.childReaching,color: Colors.white, )),
                const TabItem(icon: Icon(FontAwesomeIcons.users,color: Colors.white, )),
                TabItem(icon: Icon(FontAwesomeIcons.add,color: Theme.of(context).primaryColor, )),
                const TabItem(icon: Icon(FontAwesomeIcons.userClock,color: Colors.white, )),
                const TabItem(icon: Icon(FontAwesomeIcons.userPen,color: Colors.white, )),

              ],
              onTap: (int i) {
                if(i==0)
                {
                 navigateTo(context, const GamesScreen());
                }
                if(i==1)
                {
                  navigateTo(context,const UsersScreen());
                }
                if(i==2)
                {
                  selectedTypeNoteValue=null;
                 navigateTo(context, const CreateNoteScreen());
                }
                if(i==3)
                {
                  navigateTo(context, const PostOnlyMeScreen());
                }
                if(i==4)
                {
                  navigateTo(context, const ProfileScreen());
                }
              }
          ),
          body: ConditionalBuilder(
              condition:state is! UserGetPostLoading,
              builder: (context) => SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    if(state is  UserSaveImageInGalleryLoading)
                      LinearProgressIndicator(color: Theme.of(context).primaryColor,backgroundColor:Colors.white ),
                    const SizedBox(height: 20,),
                    EasyRefresh(onRefresh: ()async {
                      await cubit.getPosts();
                    },
                      child: SizedBox(height:MediaQuery.of(context).size.height-160,
                        child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),

                            shrinkWrap: true,
                          itemBuilder: (context, index,) =>
                                buildPostItem(
                                  context,
                                    index,
                                    cubit
                                        .usersMap[cubit
                                        .postsList[index]
                                        .values
                                        .single
                                        .ownerId].image!,
                                    cubit
                                        .usersMap[cubit
                                        .postsList[index]
                                        .values
                                        .single
                                        .ownerId].username!,
                                  cubit.postsList[index]
                                      .values
                                      .single.time,
                                  cubit.postsList[index]
                                      .values
                                      .single
                                      .text,
                                    cubit
                                    .postsList[index]
                                    .values
                                    .single
                                    .image,
                                        cubit.postsList[index]
                                    .values
                                    .single
                                    .numOfImages,
                                    cubit.postsList[index]
                                        .values
                                        .single
                                        .likes,
                                    cubit.postsList[index],
                                    cubit.postsList[index].values.single.ownerId,
                                ),
                            separatorBuilder: (context, index) => const SizedBox(
                              height: 8.0,
                            ),

                            itemCount:cubit.postsList.length
                        ),
                      ),
                    ),
                    const SizedBox(height: 40,),
                  ],
                ),
              ),
              fallback: (BuildContext context) =>
                  const Center(child:AdaptiveIndicator()),
            ),

        );

      });
  }


  Widget buildPostItem(context,index,ownerImage,ownerName,time,text,imagePosts,numImages,likes,post,ownerId)

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
                unSeenColor:Theme.of(context).primaryColor,
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
              Visibility(visible:ownerId==idForUser ,child: IconButton(
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
                                              () { HomeCubit.get(context)
                                                            .deletePost(post)
                                                            .whenComplete(() {
                                                Navigator.pop(context);
                                                HomeCubit.get(
                                                    context)
                                                    .getPosts();
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
                                ),
                                Padding(
                                  padding:  EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom,),
                                  child: const SizedBox(height: 20,),
                                ),


                              ],
                            ),
                          ),
                        ));


              }, icon:const  Icon(FontAwesomeIcons.trash))),
              Visibility(visible:ownerId!=idForUser ,child: IconButton(
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
                                                  .reportPostUser(post)
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


                  }, icon:const  Icon(FontAwesomeIcons.circleExclamation)))
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
                trimLines: 6,
                trimMode: TrimMode.Line,
                trimCollapsedText: showMore.tr,
                trimExpandedText:"... ${showLess.tr}",
                moreStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                lessStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(
                  Icons.thumb_up_off_alt_rounded,
                  size: 16.0,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(
                  width: 5.0,
                ),
                Padding(
                  padding:
                  const EdgeInsets.only(top: 4.0),
                  child: Text("${likes.length}"),
                ),


              ],
            ),
          ),

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
              IconButton(
                  onPressed: (){
                   HomeCubit.get(context).updatePostLikes(post);
                  },
                  icon:
                  likes
                      .any((element) => element.ownerId ==
                     idForUser)
                      ? Icon ( Icons.thumb_up_off_alt_rounded,color: Theme.of(context).primaryColor,)
                      :
                  const Icon ( Icons.thumb_up_off_alt_rounded,color: Colors.grey,)
              ),
              Text(
                likeText.tr,
              ),
              const Spacer(),
              if(text!="")
              IconButton(
                  onPressed: (){
                    FlutterClipboard.copy(text);
                    showToastSuccess(copyText.tr, context);
                    AwesomeDialog(
                      customHeader: Icon(FontAwesomeIcons.circleCheck,size:100,color: Theme.of(context).primaryColor,),
                      btnOkColor: Theme.of(context).primaryColor,
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
                        customHeader: Icon(FontAwesomeIcons.circleCheck,size:100,color: Theme.of(context).primaryColor,),
                        btnOkColor: Theme.of(context).primaryColor,
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
            ]),
          ),
        ],
      ),
    ),
  );
}
