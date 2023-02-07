
import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mahdeko/Compouents/adaptive_indicator.dart';
import 'package:mahdeko/Compouents/constants.dart';
import 'package:mahdeko/Compouents/widgets.dart';
import 'package:mahdeko/Locale/locale_controller.dart';
import 'package:mahdeko/modules/Login/login_screen.dart';
import 'package:mahdeko/modules/Porsonal/profile_screen.dart';
import 'package:mahdeko/network/cache_helper.dart';
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
                          navigatePushReplacement(context, const LoginScreen())
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
                TabItem(icon: Icons.notifications),
                TabItem(icon: Icons.add),
                TabItem(icon: Icons.person),
                TabItem(icon: Icons.people),
              ],
              onTap: (int i) {
                if(i==0)
                {
                  // SocialCubit.get(context).getPosts();
                }
                if(i==1)
                {
                  // navigateTo(context,const NotificationsAdminScreen());
                }
                if(i==2)
                {
                  // mobadrahNameController.text="";
                  // mobadrahTextController.text="";
                  // SocialCubit.get(context).postImage=null;
                  // SocialCubit.get(context).numberOfHours=1;
                  // SocialCubit.get(context).postType=SocialCubit.get(context).post2;

                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) =>  PostScreen(),
                  //   ),
                  // );
                }
                if(i==3)
                {
                 navigateTo(context, const ProfileScreen());
                }
                if(i==4)
                {
                  // SocialCubit.get(context).getUsers();
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) =>  const UsersAdminScreen(),
                  //   ),
                  // );
                }
              }
          ),
          body: ConditionalBuilder(
            condition:true,
            builder: (context) => SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20,),
                  ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) =>
                          buildPostItem(
                            context,
                          ),
                      separatorBuilder: (context, index) => const SizedBox(
                        height: 8.0,
                      ),

                      itemCount:10 // it will be change),
                  ),
                ],
              ),
            ),
            fallback: (BuildContext context) =>
                const Center(child:AdaptiveIndicator()),
          ),
        );

      });
  }

  Widget buildPostItem(context,)

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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor:Theme.of(context).primaryColor,
                minRadius: 31.0,
                child:
                const CircleAvatar(
                  radius: 30.0,
                  backgroundImage:
                AssetImage("assets/images/NWU.png",),
                )
                ,
              ),
              const SizedBox(
                width: 10.0,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(padding: const EdgeInsets.only(top: 15),child:  Text(" {ownerName} ",style: (TextStyle(fontWeight: FontWeight.bold)),)),
                  SizedBox(height: 3,),
                  //SocialCubit.get(context).dateAndTimeFormat(time)
                  Text("2/2/2020",style: TextStyle(fontSize: 12),)
                ],
              ),
              const Spacer(),
              IconButton(onPressed: (){
                // SocialCubit.get(context).getPosts();
              }, icon:const Icon (Icons.delete,size: 30,))
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
          Text("text"),
          const SizedBox(height: 20,),
          // if(image != '')
            // Padding(
            //     padding: const EdgeInsetsDirectional.only(top: 5.0),
            //     child: Stack(
            //       alignment: Alignment.bottomRight,
            //       children: [
            //         Stack(alignment: Alignment.centerLeft, children: [
            //           SizedBox(
            //             height:375,
            //             width: MediaQuery.of(context).size.width.toInt()<=560?double.infinity:double.infinity,
            //             child:
            //             Image.network(
            //               '${image}',fit: BoxFit.cover,
            //             ),
            //
            //           ),
            //         ]),
            //       ],
            //     )),

          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 5.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 5.0,
                      ),
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
                            child: Text("10"),
                          ),


                        ],
                      ),
                    ),
                    onTap: () {
                      // postToWorkWithComment = post;
                      // likesForOnePost = likes;
                      // indexForOnePost = index;
                      // navigateTo(context, const LikesAdminScreen());

                    },
                  ),
                ),
                Expanded(
                  child: InkWell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 5.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.chat,
                            size: 16.0,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(
                            width: 5.0,
                          ),
                          Row(
                            children:  [
                              const Text(
                                "56",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      // postToWorkWithComment = post;
                      // commentsForOnePost = comments;
                      // indexForOnePost = index;
                      // navigateTo(context,  CommentAdminScreen());

                    },
                  ),
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
          Row(children: [
            Expanded(
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    IconButton(
                        onPressed: (){
                         // SocialCubit.get(context).updatePostLikes(post);
                        },
                        icon:
                        // SocialCubit.get(context).postsList[index].values.single.likes
                        //     .any((element) => element.ownerName ==
                        //     SocialCubit.get(context).user!.username)
                        //     ? Icon ( Icons.thumb_up_off_alt_rounded,color: Theme.of(context).primaryColor,)
                        //     :
                        const Icon ( Icons.thumb_up_off_alt_rounded)
                    ),
                    Text(
                      likeText.tr,
                    ),
                    const Spacer(),
                    const VerticalDivider(
                      color: Colors.grey,
                    ),
                    const Spacer(),
                    IconButton(
                        onPressed: (){
                          // postToWorkWithComment = post;
                          // commentsForOnePost = comments;
                          // indexForOnePost = index;
                          // navigateTo(context,  CommentAdminScreen());

                        },
                        icon:const Icon (Icons.chat_outlined,
                        )),
                     Text(
                       commentText.tr,
                    ),
                    const Spacer(),

                    // if(isMobadrah == true)
                    //   InkWell(
                    //     onTap: (){
                    //       postToWorkWithComment = post;
                    //       numberOfHoursForCurrentMobadrah = numberOfHours;
                    //       navigateTo(context, AcceptRejectOrderScreen(
                    //         noResponseUsers: noResponseUsers,
                    //         acceptedUsers: acceptedUsers,
                    //         rejectedUsers: rejectedUsers,
                    //         mobadrahName: mobadrahName,
                    //       ));
                    //
                    //     },
                    //     child: Row(
                    //       children: [
                    //         const VerticalDivider(
                    //           color: Colors.grey,
                    //         ),
                    //         Icon (Icons.task_outlined,size: 30,color: Theme.of(context).primaryColor),
                    //         Text(
                    //           " الطلبات",style: TextStyle(color: Theme.of(context).primaryColor),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    //
                    // if(isMobadrah == true)
                    //   const Spacer(),
                  ],
                ),
              ),
            ),
          ]),
        ],
      ),
    ),
  );
}

