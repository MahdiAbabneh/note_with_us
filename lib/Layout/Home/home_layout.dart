import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:mahdeko/Compouents/adaptive_indicator.dart';
import 'package:mahdeko/Compouents/constant_empty.dart';
import 'package:mahdeko/Compouents/constants.dart';
import 'package:mahdeko/Compouents/widgets.dart';
import 'package:mahdeko/Locale/locale_controller.dart';
import 'package:mahdeko/modules/CreateNote/create_note_screen.dart';
import 'package:mahdeko/modules/Login/login_screen.dart';
import 'package:mahdeko/modules/Porsonal/profile_screen.dart';
import 'package:mahdeko/modules/PostOnlyMe/post_only_me_screen.dart';
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
    MyLocaleController controllerLang= Get.find();
    return BlocConsumer<HomeCubit, HomeStates>(
      listener: (context, state) {
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
              title:  Text(homepage.tr))
          ,drawer: Drawer(
          backgroundColor: Theme.of(context).primaryColor,
          child: SafeArea(
            child: ListTileTheme(
              textColor: Colors.white,
              iconColor: Colors.white,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      width: 150.0,
                      height: 150.0,
                      margin: const EdgeInsets.only(
                        top: 100.0,
                        bottom: 64.0,
                      ),
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                      ),
                      child:Image.asset("assets/images/NWU.png",),
                    ),
                    ListTile(
                      onTap: () {
                        // SocialCubit.get(context).getPosts();
                        // Navigator.pop(context);
                      },
                      leading: const Icon(Icons.home),
                      title:  Text(homepage.tr,style: TextStyle(fontSize: responsive(context, 16.0, 20.0))),
                    ),
                    ListTile(
                      onTap: () {
                        // mobadrahNameController.text="";
                        // mobadrahTextController.text="";
                        // SocialCubit.get(context).postImage=null;
                        // SocialCubit.get(context).numberOfHours=1;
                        // SocialCubit.get(context).postType=SocialCubit.get(context).post2;
                        //
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) =>  PostScreen(),
                        //   ),
                        // );
                      },
                      leading: const Icon(Icons.add),
                      title:  Text(createNoteText.tr,style: TextStyle(fontSize: responsive(context, 16.0, 20.0))),
                    ),
                    ListTile(
                      onTap: () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) =>  MyProfileAdminScreen(),
                        //   ),
                        // );
                      },
                      leading: const Icon(Icons.person),
                      title:  Text(personalPage.tr,style: TextStyle(fontSize: responsive(context, 16.0, 20.0))),
                    ),
                    ListTile(
                      onTap: () {
                        // Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //       builder: (context) => const UsersAdminScreen(),
                        //     ));
                      },
                      leading: const Icon(Icons.people),
                      title:  Text(usersText.tr,style: TextStyle(fontSize: responsive(context, 16.0, 20.0))),
                    ),
                    ListTile(
                      onTap: () {
                        // navigateTo(context,const NotificationsAdminScreen());

                      },
                      leading: const Icon(Icons.circle_notifications),
                      title:  Text(notificationText.tr,style: TextStyle(fontSize: responsive(context, 16.0, 20.0))),
                    ),
                    ListTile(
                      onTap: () {
                        if(CacheHelper.getData(key:"lang")=="ar")
                        {
                          controllerLang.changeLang("en");
                        }
                        else{
                          controllerLang.changeLang("ar");
                        }

                      },
                      leading: const Icon(Icons.language),
                      title:Text(CacheHelper.getData(key:"lang")=="ar"?"العربية":"English",style: TextStyle(fontSize: responsive(context, 16.0, 20.0)),),
                    ),
                    ListTile(
                      onTap: () {
                        FirebaseAuth.instance.signOut().whenComplete(() => {
                          CacheHelper.sharedPreferences?.remove("id"),
                          CacheHelper.sharedPreferences!.clear()
                        }).whenComplete(() => {
                          navigatePushReplacement(context, const LoginScreen()),
                        });

                      },
                      leading: const Icon(Icons.exit_to_app),
                      title:  Text(logoutText.tr),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
          bottomNavigationBar: ConvexAppBar(
              color: Colors.white,
              activeColor: Colors.white,
              style:TabStyle.fixedCircle,
              initialActiveIndex: 0,
              backgroundColor: Theme.of(context).primaryColor,
              items: const [
                TabItem(icon: Icons.home),
                TabItem(icon: Icons.people),
                TabItem(icon: Icons.add),
                TabItem(icon: Icons.person_pin_outlined),
                TabItem(icon: Icons.person),

              ],
              onTap: (int i) {
                if(i==0)
                {
                  cubit.getPosts();
                }
                if(i==1)
                {
                  // navigateTo(context,const NotificationsAdminScreen());
                }
                if(i==2)
                {
                 navigateTo(context, const CreateNoteScreen());
                }
                if(i==3)
                {
                 navigateTo(context, const ProfileScreen());
                }
                if(i==4)
                {
                 navigateTo(context, PostOnlyMeScreen());
                 cubit.getPostsOnlyMe();
                }
              }
          ),
          body: ConditionalBuilder(
            condition:state is! UserGetPostLoading,
            builder: (context) => SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20,),
                  ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index,) =>
                          buildPostItem(
                            context,
                              index,
                           cubit.postsList[index]
                                .values
                                .single
                                .ownerImage,
                            cubit.postsList[index]
                                .values
                                .single.ownerName,
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
                              cubit.postsList[index]
                          ),
                      separatorBuilder: (context, index) => const SizedBox(
                        height: 8.0,
                      ),

                      itemCount:cubit.postsList.length
                  ),
                  SizedBox(height: 40,),
                ],
              ),
            ),
            fallback: (BuildContext context) =>
                const Center(child:AdaptiveIndicator()),
          ),
        );

      });
  }


  Widget buildPostItem(context,index,ownerImage,ownerName,time,text,imagePosts,numImages,likes,post)

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
                unSeenColor: Colors.red,
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
              Visibility(visible:HomeCubit.get(context).postsList[index].values.single.ownerId==idForUser ,child: IconButton(onPressed: (){
                HomeCubit.get(context).deletePost(post).whenComplete(() => HomeCubit.get(context).getPosts());

              }, icon:const Icon(Icons.delete)))
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
                trimLines: 2,
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
              scrollPhysics: BouncingScrollPhysics(),
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
                    backgroundColor:Colors.red,
                    value: event == null
                        ? 0
                        : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 10,),

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
                  HomeCubit.get(context).postsList[index].values.single.likes
                      .any((element) => element.ownerName ==
                      HomeCubit.get(context).user!.username)
                      ? Icon ( Icons.thumb_up_off_alt_rounded,color: Theme.of(context).primaryColor,)
                      :
                  const Icon ( Icons.thumb_up_off_alt_rounded)
              ),
              Text(
                likeText.tr,
              ),
              Spacer(),
              Row(
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
            ]),
          ),
        ],
      ),
    ),
  );
}

final imageList = [
  "assets/images/NWU.png",
  "assets/images/NWU.png",
  "assets/images/NWU.png",
];