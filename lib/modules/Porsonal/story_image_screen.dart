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
            showToastFailed(toast5, context);
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
              padding: const EdgeInsets.only(left: 10.0,right: 10),
              child: ElevatedButton(onPressed: (){
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
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
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
                            SizedBox(height: MediaQuery.of(context).size.height,
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 1,
                                    childAspectRatio: 2,
                                    mainAxisSpacing: 0,
                                    crossAxisSpacing: 20,
                                    mainAxisExtent: 200),
                                itemBuilder: (context, index) =>
                                    Stack(
                                      alignment:
                                      AlignmentDirectional.topStart,
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(border:Border.all(color: Theme.of(context).primaryColor,width: 2) ,
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
                                itemCount: cubit.imagesUserProfile!.length,
                              ),
                            ),
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

