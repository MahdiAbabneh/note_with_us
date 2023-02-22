import 'package:alarm/alarm.dart';
import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:mahdeko/Compouents/adaptive_indicator.dart';
import 'package:mahdeko/Compouents/constant_empty.dart';
import 'package:mahdeko/Compouents/constants.dart';
import 'package:mahdeko/Compouents/widgets.dart';
import 'package:mahdeko/Layout/Home/cubit/cubit.dart';
import 'package:mahdeko/Layout/Home/cubit/states.dart';
import 'package:mahdeko/Locale/locale_controller.dart';
import 'package:mahdeko/modules/CreateNote/create_note_screen.dart';
import 'package:mahdeko/modules/Login/login_screen.dart';
import 'package:mahdeko/modules/Porsonal/profile_screen.dart';
import 'package:mahdeko/network/cache_helper.dart';
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
    super.initState();
    Alarm.init();
  }

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
              title:  Text(homepage.tr)),
          body: ConditionalBuilder(
            condition:state is! UserGetPostOnlyMeLoading&&cubit.usersList.isNotEmpty ,
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
                            cubit.postsListOnlyMe[index]
                                .values
                                .single.reminder,
                          ),
                      separatorBuilder: (context, index) => const SizedBox(
                        height: 8.0,
                      ),

                      itemCount:cubit.postsListOnlyMe.length
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

  Widget buildPostItem(context,index,ownerImage,ownerName,time,text,imagePosts,numImages,likes,post,cubit,reminder)

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
              IconButton(
                onPressed:(){
                  cubit.pickTime(context,index).whenComplete(() => {
                    if(cubit.selectedTime[index] != null)
                    cubit.postReminder(post,cubit.selectedTime[index],cubit.isRinging[index]),
                  });

                } ,
                icon: Icon(FontAwesomeIcons.bell,color:cubit.selectedTime[index] != null?Theme.of(context).primaryColor:Colors.grey ,),

              ),
              const SizedBox(width: 10,),

              IconButton(onPressed: (){
                HomeCubit.get(context).deletePostOnlyMe(post).whenComplete(() => HomeCubit.get(context).getPostsOnlyMe());

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

            Row(
              children: [
                if (cubit.selectedTime[index] != null)
                Text(
                  'Alarm will ring ${cubit.ringDay(index)} at ${cubit.selectedTime[index]!.format(context)}',
                ),
                if (cubit.isRinging[index]) Text(ringing.tr),
                Spacer(),
                if (cubit.isRinging[index])
                  RawMaterialButton(
                    onPressed: () async {
                      final stop = await Alarm.stop();
                      if (stop && cubit.isRinging[index]) setState(() => cubit.isRinging[index] = false);
                      cubit.updatePostReminder(post);
                    },
                    fillColor: Theme.of(context).primaryColor,
                    child:  Text(stop.tr,style: const TextStyle(color: Colors.white),),
                  ),
                if (cubit.selectedTime[index] != null)
                  RawMaterialButton(
                  onPressed: () async {
                    await Alarm.stop();
                      setState((){
                        cubit.isRinging[index] = false;
                        cubit.selectedTime[index]=null;
                    });
                    cubit.updatePostReminder(post);

                  },
                  fillColor: Theme.of(context).primaryColor,
                  child: Text(undo.tr,style: const TextStyle(color: Colors.white),),
                ),

              ],
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
                    backgroundColor:Colors.grey,
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
        ],
      ),
    ),
  );
}
