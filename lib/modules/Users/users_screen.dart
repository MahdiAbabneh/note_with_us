import 'package:cached_network_image/cached_network_image.dart';
import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
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
import 'package:mahdeko/modules/Users/users_info_screen.dart';



class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  var searchControllerForUsers = TextEditingController();
  String searchStringForUsers = "";
  @override
  Widget build(BuildContext context) {

    var cubit = HomeCubit.get(context);
    return BlocConsumer<HomeCubit, HomeStates>(
      listener: (context, state) {},
      builder: (context, state) {
        return  Scaffold(
          appBar: AppBar(
            title:  Text(usersText.tr),
          ),
          body:ConditionalBuilder(
            condition: true,
            builder: (context) => SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: searchControllerForUsers,
                      keyboardType: TextInputType.text,
                      onChanged: (value) {
                        setState(() {
                          searchStringForUsers = value.toLowerCase();
                        });
                      },
                      decoration:  InputDecoration(
                        prefixIcon:  Icon(FontAwesomeIcons.userLarge, color:Theme.of(context).primaryColor),
                        labelStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: responsive(context, 14.0, 18.0)),
                        labelText: searchText.tr,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide: BorderSide(color:  Theme.of(context).primaryColor),),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide:  BorderSide(color: Theme.of(context).primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) =>
                        cubit.usersList[index].username!.toLowerCase().contains(searchStringForUsers)?
                        InkWell(
                          onTap: ()async{
                            indexUser = index;
                            cubit.ageCalculatorUsers(cubit.usersList[indexUser!].dateOfBirth!);
                            navigateTo(context,const UsersInfoScreen());
                            await cubit.getImageUserStory();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Padding(
                                    padding: const EdgeInsets.only(top: 3.0,right: 10),
                                    child: CircleAvatar(
                                      backgroundColor:Theme.of(context).primaryColor,
                                      minRadius: 42.0,
                                      child:CachedNetworkImage(
                                        imageUrl: cubit.usersList[index].image!,
                                        imageBuilder: (context, imageProvider) => Container(
                                          width: 80.0,
                                          height: 80.0,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: DecorationImage(
                                                image: imageProvider),
                                          ),
                                        ),
                                        placeholder: (context, url) => const CircularProgressIndicator(),
                                        errorWidget: (context, url, error) => const Icon(Icons.error),
                                      )
                                    )
                                ),
                                const SizedBox(width: 10,),
                                Text(cubit.usersList[index].username!,style: TextStyle(color: Theme.of(context).primaryColor,fontWeight: FontWeight.bold,fontSize: 18),),

                              ],
                            ),
                          ),
                        )
                            : Container(),
                        itemCount: cubit.usersList.length // it will be change),
                    ),
                  ],
                ),
              ),
            ),
            fallback: (BuildContext context) =>
                const Center(child: AdaptiveIndicator()),
          ),
        );

      });
  }


}

