import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:mahdeko/Compouents/constant_empty.dart';
import 'package:mahdeko/Compouents/constants.dart';
import 'package:mahdeko/Compouents/widgets.dart';
import 'package:mahdeko/Layout/Home/cubit/cubit.dart';
import 'package:mahdeko/Layout/Home/cubit/states.dart';
import 'package:status_view/status_view.dart';



class StoryImageScreen extends StatelessWidget {
  const StoryImageScreen({super.key});


  @override
  Widget build(BuildContext context) {
    var cubit = HomeCubit.get(context);
    return BlocConsumer<HomeCubit, HomeStates>(
      listener: (context, state) {
        if(state is UserSelectImageError)
          {
            showToastFailed(toast5.tr, context);
          }
        if(state is UserAddImageStorySuccess)
          {
          Navigator.pop(context);
          }

      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            actions: [Padding(
              padding: const EdgeInsets.all(8),
              child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor:  Theme.of(context).primaryColor,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(15.0),
                      ))),onPressed: (){
                cubit.addImageStory();
              }, child: Text(save.tr)),
            )],
              title:  Text(imagesScreen.tr)),
          body:StatefulBuilder(
            builder: (BuildContext context, void Function(void Function()) setState) {
              return Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    if(state is  UserAddImageStoryLoading||state is UserGetImageStoryLoading)
                      LinearProgressIndicator(color: Theme.of(context).primaryColor,backgroundColor:Colors.white ),
                    Column(
                      children: [
                        const Divider(),
                        Row(
                          children: [
                            StatusView(
                              radius: 40,
                              spacing: 15,
                              strokeWidth: 2,
                              indexOfSeenStatus: cubit.imagesUserProfile!.isEmpty?3:3-cubit.imagesUserProfile!.length,
                              numberOfStatus: 3,
                              padding: 4,
                              centerImageUrl: profileImage!,
                              seenColor: Colors.grey,
                              unSeenColor: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 10,),
                            Text(
                              usernameData!,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor
                              ),
                            ),
                            const Spacer(),
                            IconButton(onPressed:cubit.imagesUserProfile!.length==3?null: (){
                              cubit.selectImagesUserProfile();
                            }, icon: Icon(FontAwesomeIcons.images,color:cubit.imagesUserProfile!.length==3?Colors.grey: Theme.of(context).primaryColor, )),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 20,),

                      ],
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            GridView.builder(
                              primary: false,
                              scrollDirection: Axis.vertical,
                              shrinkWrap: true,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 1,

                                  mainAxisSpacing: 10,
                                  mainAxisExtent: 300),
                              itemBuilder: (context, index) =>
                                  Center(
                                    child: Stack(
                                      alignment:
                                      AlignmentDirectional.topStart,
                                      children: [

                                        Container(
                                          width:250,
                                          decoration: BoxDecoration(border:Border.all(color: Theme.of(context).primaryColor,width: 3) ,
                                            borderRadius: BorderRadius.circular(15),
                                            image:
                                            DecorationImage(
                                              image: FileImage(File(cubit.imagesUserProfile![index].path)) ,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: CircleAvatar(
                                            backgroundColor:
                                            Theme.of(context)
                                                .primaryColor,
                                            radius: 20.0,
                                            child: const Icon(
                                              Icons.close,
                                              size: 16.0,color: Colors.white,
                                            ),
                                          ),
                                          onPressed: () {
                                            cubit.removeImagesUserProfile(index);
                                          },
                                        ),
                                      ],

                                    ),
                                  ),
                              itemCount: cubit.imagesUserProfile!.length,
                            ),
                            const SizedBox(height: 40,),
                          ],
                        ),
                      ),
                    ),

                  ],
                ),
              );
            },
          ),
        );

      });
  }


}

