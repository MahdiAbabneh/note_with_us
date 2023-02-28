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
import 'package:mahdeko/models/message_model.dart';
import 'package:mahdeko/models/user_data_model.dart';

class ChatScreen extends StatefulWidget {
  final UserDataModel userDataModel;

  const ChatScreen({ Key? key,
    required this.userDataModel,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String chatUser = "";
  @override
  void initState() {
    super.initState();
    HomeCubit.get(context).getMessages(widget.userDataModel);

  }
  @override
  Widget build(BuildContext context) {
    var cubit = HomeCubit.get(context);
    return BlocConsumer<HomeCubit, HomeStates>(
        listener: (context, state) {},
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              actions: [
                Padding(
                  padding: const EdgeInsets.only(left: 10,right: 10),
                  child: IconButton(onPressed: ()async{
                    if(cubit.usersList[indexUser!].phoneNumber != ""){
                      await FlutterPhoneDirectCaller.callNumber('${cubit.usersList[indexUser!].phoneNumber}');
                    }else{
                      showToastFailed(toast8.tr,context);
                    }
                  },
                      icon:  const Icon(FontAwesomeIcons.phone,)),
                ),

              ],
              title: Row(
                children: [
                  CachedNetworkImage(
                    imageUrl: widget.userDataModel.image!,
                    imageBuilder: (context, imageProvider) => Container(
                      width: 50,
                      height:50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                            image: imageProvider),
                      ),
                    ),
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                  const SizedBox(width: 10,),
                  Text(
                    widget.userDataModel.username!,
                  ),
                ],
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  if (cubit.messagesList.isNotEmpty)
                    Expanded(
                      child: ListView.separated(
                        reverse: true,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          if (cubit.messagesList[index].senderId == cubit.user!.uId) {
                            return MyItem(
                              model: cubit.messagesList[index],
                            );
                          }
                          return UserItem(
                            model:cubit.messagesList[index],
                          );
                        },
                        separatorBuilder: (context, index) =>
                        const SizedBox(height: 3,),
                        itemCount: cubit.messagesList.length,
                      ),
                    ),
                  if (cubit.messagesList.isEmpty)
                     Expanded(
                      child: Container(),
                    ),
                  const SizedBox(height: 20,),
                  Row(
                    children: [
                       CircleAvatar(
                        radius: 29,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: CircleAvatar(
                            radius: 27,
                            backgroundImage: NetworkImage(
                                cubit.user!.image!)),
                      ),

                      const SizedBox(width: 5,),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: TextFormField(
                            controller:cubit.messageController,
                            cursorColor: Theme.of(context).primaryColor,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.newline,
                            onChanged: (value){
                              setState(() {
                                chatUser = cubit.messageController.text;
                              });
                            },
                            decoration:  InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide:  BorderSide(color:Theme.of(context).primaryColor,),),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide:  BorderSide(color:Theme.of(context).primaryColor, ),
                              ),
                            ),
                            style: const TextStyle(
                                fontSize: 16.0),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: chatUser.isNotEmpty,
                        child: MaterialButton(
                          minWidth: 1,
                          onPressed: () {
                            cubit.sendMessage(widget.userDataModel);
                            chatUser ="";
                          },
                          child:  Icon(
                            Icons.send,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          );
        },
    );
  }
}

class MyItem extends StatelessWidget {
  final MessageDataModel model;

  const MyItem({
    Key? key,
    required this.model,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 5.0,
            ),
            decoration:  BoxDecoration(
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(
                  15.0,
                ),
                topEnd: Radius.circular(
                  15.0,
                ),
                bottomStart: Radius.circular(
                  15.0,
                ),
              ),
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.message,
                  style: const TextStyle(
                      color: Colors.white,fontSize: 16
                  ),
                ),
                const SizedBox(height: 5,),
                Text(HomeCubit.get(context).dateAndTimeFormat(model.time),
                  style: const TextStyle(color: Colors.white,fontSize: 12),)
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class UserItem extends StatelessWidget {
  final MessageDataModel model;

  const UserItem({
    Key? key,
    required this.model,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 5.0,
            ),
            decoration: BoxDecoration(
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(
                  15.0,
                ),
                topEnd: Radius.circular(
                  15.0,
                ),
                bottomEnd: Radius.circular(
                  15.0,
                ),
              ),
              color: darkMoodData! ?  Colors.grey :  Colors.grey[200],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.message,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 5,),
                Text(HomeCubit.get(context).dateAndTimeFormat(model.time),
                  style: const TextStyle(fontSize: 12),)
              ],
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}