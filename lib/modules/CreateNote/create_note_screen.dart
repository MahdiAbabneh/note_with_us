
import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:mahdeko/Compouents/adaptive_indicator.dart';
import 'package:mahdeko/Compouents/constant_empty.dart';
import 'package:mahdeko/Compouents/constants.dart';
import 'package:mahdeko/Compouents/widgets.dart';
import 'package:mahdeko/Layout/Home/cubit/cubit.dart';
import 'package:mahdeko/Layout/Home/cubit/states.dart';
import 'package:mahdeko/models/user_data_model.dart';
import 'package:mahdeko/network/cache_helper.dart';
import 'package:status_view/status_view.dart';

import '../../Layout/Home/home_layout.dart';


class CreateNoteScreen extends StatelessWidget {
  const CreateNoteScreen({super.key});


  @override
  Widget build(BuildContext context) {
    var cubit = HomeCubit.get(context);
    return BlocConsumer<HomeCubit, HomeStates>(
      listener: (context, state) {
        if(state is UserSelectImagePostError)
          {
            showToastFailed(toast5, context);
          }
        if(state is UserCreatePostSuccess)
          {
            cubit.imageFileListFromGallery!.clear();
            cubit.imagesForPost.clear();
            textPostController.clear();
            showToastSuccess(toast6.tr, context);
            navigatePushReplacement(context, const HomeLayout());
          }

      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
              title:  Text(createNoteText.tr)),
          body:Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
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
                              indexOfSeenStatus: cubit.imageFileListFromGallery!.isEmpty?3:3-cubit.imageFileListFromGallery!.length,
                              numberOfStatus: 3,
                              padding: 4,
                              centerImageUrl: profileImage!,
                              seenColor: Colors.grey,
                              unSeenColor: Colors.red,
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
                            IconButton(onPressed:cubit.imageFileListFromGallery!.length==3?null: (){
                              cubit.selectPostImages();
                            }, icon: Icon(Icons.image,color:cubit.imageFileListFromGallery!.length==3?Colors.grey: Theme.of(context).primaryColor,)),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 10,),
                        TextFormField(
                         controller: textPostController,
                          cursorColor: Theme.of(context).primaryColor,
                          maxLength: 1000,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          maxLines: 7,
                          decoration:   InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: const BorderSide(color:  Color(
                                    0xFFC27D3C),),),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: const BorderSide(color:  Color(
                                    0xFFC27D3C),),
                              ),
                              hintText: writeHere.tr
                          ),
                          style: const TextStyle(
                              fontSize: 20.0, color: Colors.black),
                        ),
                        const SizedBox(height: 10,),
                        const Divider(),
                        const SizedBox(height: 20,),
                        SizedBox(height: 200,
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 2,
                                mainAxisSpacing: 2,
                                crossAxisSpacing: 20,
                                mainAxisExtent: 150),
                            itemBuilder: (context, index) =>
                                Stack(
                                  alignment:
                                  AlignmentDirectional.topStart,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5),
                                          image:
                                         DecorationImage(
                                          image: FileImage(File(cubit.imageFileListFromGallery![index].path)) ,
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
                                        cubit.removePostImage(index);
                                      },
                                    ),
                                  ],

                                ),
                            itemCount: cubit.imageFileListFromGallery!.length,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: double.infinity,
                  child: ConditionalBuilder(
                    fallback: (context) =>
                    const Center(child: AdaptiveIndicator()),
                    condition:state is! UserCreatePostLoading,
                    builder:(context) => ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor:  const Color(
                            0xFFC27D3C),
                        ), onPressed:() {
                          if(textPostController.text.isEmpty&&cubit.imageFileListFromGallery!.isEmpty)
                            {
                              showToastFailed(toast7.tr, context);
                            }
                          else
                            {
                              cubit.createPost();
                            }
                    }, child:Text(createNoteText.tr, style:  TextStyle(
                        fontWeight: FontWeight.bold, fontSize:  responsive(context, 14.0, 18.0)),)),
                  ),
                ),
              ],
            ),
          ),
        );

      });
  }


}

