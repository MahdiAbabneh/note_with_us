import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:mahdeko/Compouents/constants.dart';
import 'package:mahdeko/Compouents/widgets.dart';
import 'package:mahdeko/Layout/Home/cubit/cubit.dart';
import 'package:mahdeko/Layout/Home/cubit/states.dart';
import 'package:mahdeko/network/cache_helper.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});


  @override
  Widget build(BuildContext context) {
    var cubit = HomeCubit.get(context);
    return BlocConsumer<HomeCubit, HomeStates>(
      listener: (context, state) {
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
              title:  Text(homepage.tr)),
          body:Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(alignment: Alignment.center,
                  children:[
                    Opacity(

                      opacity: 0.3,
                      child: Image.asset("assets/images/NWU.png",
                        fit: BoxFit.cover,height: responsive(context, 250.0, 500.0),),),
                    Stack(alignment:CacheHelper.getData(key:"lang")=="ar"?Alignment.topRight:Alignment.topLeft ,
                      children: [
                        Container(
                        decoration: const BoxDecoration(
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            CircleAvatar(
                                backgroundColor:Theme.of(context).primaryColor,
                                minRadius: 95.0,
                                child:CircleAvatar(
                                  radius: 90.0,
                                  backgroundImage:
                                  AssetImage("assets/images/NWU.png",),
                                )),
                            const SizedBox(
                              height: 5,
                            ),
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(15.0)),
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              child: Text(
                                textAlign: TextAlign.center,
                                "Mahdi Ababneh  ",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                        IconButton(
                            onPressed: (){
                            },
                            icon: Icon(Icons.camera_alt_outlined,color: Theme.of(context).primaryColor,size: 35,)),
                      ]
                    ),
                  ]
              ),
              SizedBox(height: 20,),
              Row(
                children: [
                  Icon(Icons.phone,color: Theme.of(context).primaryColor,),
                  const SizedBox(width: 5,),
                  Text(
                    'رقم الهاتف',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(onPressed: (){
                   // phoneNumberController = TextEditingController(text: SocialCubit.get(context).user!.phoneNumber);
                    showModalBottomSheet(isScrollControlled: true,context: context, builder: (context) =>
                        SizedBox(
                          width: double.infinity,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children:  [
                                const Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Text("تحديث رقم الهاتف",style: TextStyle(fontSize: 16),),
                                ),
                                const Divider(),
                                const SizedBox(height: 30,),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      right: 10,left: 10),
                                  child: TextFormField(
                                  //  controller: phoneNumberController,
                                    maxLength: 15,
                                    cursorColor: Colors.green,
                                    keyboardType:
                                    TextInputType.number,
                                    textInputAction:
                                    TextInputAction.newline,
                                    decoration: InputDecoration(
                                      labelStyle: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 18),
                                      contentPadding: const EdgeInsets.only(right: 10),
                                      labelText: ('رقم الهاتف'),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                        borderSide: BorderSide(color: Colors.black,),),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                        borderSide: BorderSide(color: Colors.black,),
                                      ),
                                    ),
                                    style: const TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.black),
                                  ),
                                ),
                                const SizedBox(height: 20,),
                                Padding(
                                  padding: const EdgeInsets.only(right: 10,left: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child:
                                        ElevatedButton(
                                          onPressed:
                                              () {
                                            // if(phoneNumberController.text != ""){
                                            //   UserDataModel model = UserDataModel(
                                            //     uId: SocialCubit.get(context).user!.uId!,
                                            //     email: SocialCubit.get(context).user!.email!,
                                            //     username: SocialCubit.get(context).user!.username!,
                                            //     image: SocialCubit.get(context).user!.image!,
                                            //     address: SocialCubit.get(context).user!.address!,
                                            //     token: SocialCubit.get(context).user!.token!,
                                            //     dateOfBirth: SocialCubit.get(context).user!.dateOfBirth!,
                                            //     edu: SocialCubit.get(context).user!.edu!,
                                            //     job: SocialCubit.get(context).user!.job!,
                                            //     nationalNumber: SocialCubit.get(context).user!.nationalNumber!,
                                            //     numberOfHours: SocialCubit.get(context).user!.numberOfHours!,
                                            //     tasksNumber: SocialCubit.get(context).user!.tasksNumber!,
                                            //     phoneNumber: phoneNumberController.text,
                                            //   );
                                            //
                                            //   FirebaseFirestore.instance
                                            //       .collection('users')
                                            //       .doc(SocialCubit.get(context).user!.uId!)
                                            //       .set(model.toJson());
                                            //
                                            //   SocialCubit.get(context).getUserData(SocialCubit.get(context).user!.uId!);
                                            //   showToastSuccess("تمت عملية الحفظ بنجاح", context);
                                            //   Navigator.pop(context);
                                            //   phoneNumberController = TextEditingController(text: "");
                                            //
                                            // }else{
                                            //   showToastFailed("يرجى تعبئة البيانات المطلوبة أولا");
                                            // }

                                          },
                                          child: const Text(
                                            "حفظ",
                                            style: TextStyle(
                                                color: Colors
                                                    .white,
                                                fontWeight:
                                                FontWeight
                                                    .bold,
                                                fontSize:
                                                20),
                                          ),
                                          style: ElevatedButton
                                              .styleFrom(
                                            padding: const EdgeInsets
                                                .only(
                                                top:
                                                3,
                                                right:
                                                3,
                                                left:
                                                3),
                                            primary: Theme.of(
                                                context)
                                                .primaryColor,
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
                                            // phoneNumberController = TextEditingController(text: "");

                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            "إلغاء",
                                            style: TextStyle(
                                                color: Colors
                                                    .black,
                                                fontWeight:
                                                FontWeight
                                                    .bold,
                                                fontSize:
                                                20),
                                          ),
                                          style: ElevatedButton
                                              .styleFrom(
                                            padding: EdgeInsets
                                                .only(
                                                top:
                                                3,
                                                right:
                                                3,
                                                left:
                                                3),
                                            primary: Colors
                                                .white,
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
                  },
                      icon: Icon(Icons.edit,color: Theme.of(context).primaryColor,))
                ],
              ),
              SizedBox(height: 20,),
              Row(
                children: [
                  Icon(Icons.phone,color: Theme.of(context).primaryColor,),
                  const SizedBox(width: 5,),
                  Text(
                    'رقم الهاتف',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(onPressed: (){
                    // phoneNumberController = TextEditingController(text: SocialCubit.get(context).user!.phoneNumber);
                    showModalBottomSheet(isScrollControlled: true,context: context, builder: (context) =>
                        SizedBox(
                          width: double.infinity,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children:  [
                                const Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Text("تحديث رقم الهاتف",style: TextStyle(fontSize: 16),),
                                ),
                                const Divider(),
                                const SizedBox(height: 30,),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      right: 10,left: 10),
                                  child: TextFormField(
                                    //  controller: phoneNumberController,
                                    maxLength: 15,
                                    cursorColor: Colors.green,
                                    keyboardType:
                                    TextInputType.number,
                                    textInputAction:
                                    TextInputAction.newline,
                                    decoration: InputDecoration(
                                      labelStyle: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 18),
                                      contentPadding: const EdgeInsets.only(right: 10),
                                      labelText: ('رقم الهاتف'),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                        borderSide: BorderSide(color: Colors.black,),),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                        borderSide: BorderSide(color: Colors.black,),
                                      ),
                                    ),
                                    style: const TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.black),
                                  ),
                                ),
                                const SizedBox(height: 20,),
                                Padding(
                                  padding: const EdgeInsets.only(right: 10,left: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child:
                                        ElevatedButton(
                                          onPressed:
                                              () {
                                            // if(phoneNumberController.text != ""){
                                            //   UserDataModel model = UserDataModel(
                                            //     uId: SocialCubit.get(context).user!.uId!,
                                            //     email: SocialCubit.get(context).user!.email!,
                                            //     username: SocialCubit.get(context).user!.username!,
                                            //     image: SocialCubit.get(context).user!.image!,
                                            //     address: SocialCubit.get(context).user!.address!,
                                            //     token: SocialCubit.get(context).user!.token!,
                                            //     dateOfBirth: SocialCubit.get(context).user!.dateOfBirth!,
                                            //     edu: SocialCubit.get(context).user!.edu!,
                                            //     job: SocialCubit.get(context).user!.job!,
                                            //     nationalNumber: SocialCubit.get(context).user!.nationalNumber!,
                                            //     numberOfHours: SocialCubit.get(context).user!.numberOfHours!,
                                            //     tasksNumber: SocialCubit.get(context).user!.tasksNumber!,
                                            //     phoneNumber: phoneNumberController.text,
                                            //   );
                                            //
                                            //   FirebaseFirestore.instance
                                            //       .collection('users')
                                            //       .doc(SocialCubit.get(context).user!.uId!)
                                            //       .set(model.toJson());
                                            //
                                            //   SocialCubit.get(context).getUserData(SocialCubit.get(context).user!.uId!);
                                            //   showToastSuccess("تمت عملية الحفظ بنجاح", context);
                                            //   Navigator.pop(context);
                                            //   phoneNumberController = TextEditingController(text: "");
                                            //
                                            // }else{
                                            //   showToastFailed("يرجى تعبئة البيانات المطلوبة أولا");
                                            // }

                                          },
                                          child: const Text(
                                            "حفظ",
                                            style: TextStyle(
                                                color: Colors
                                                    .white,
                                                fontWeight:
                                                FontWeight
                                                    .bold,
                                                fontSize:
                                                20),
                                          ),
                                          style: ElevatedButton
                                              .styleFrom(
                                            padding: const EdgeInsets
                                                .only(
                                                top:
                                                3,
                                                right:
                                                3,
                                                left:
                                                3),
                                            primary: Theme.of(
                                                context)
                                                .primaryColor,
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
                                            // phoneNumberController = TextEditingController(text: "");

                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            "إلغاء",
                                            style: TextStyle(
                                                color: Colors
                                                    .black,
                                                fontWeight:
                                                FontWeight
                                                    .bold,
                                                fontSize:
                                                20),
                                          ),
                                          style: ElevatedButton
                                              .styleFrom(
                                            padding: EdgeInsets
                                                .only(
                                                top:
                                                3,
                                                right:
                                                3,
                                                left:
                                                3),
                                            primary: Colors
                                                .white,
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
                  },
                      icon: Icon(Icons.edit,color: Theme.of(context).primaryColor,))
                ],
              ),
              SizedBox(height: 20,),
              Row(
                children: [
                  Icon(Icons.phone,color: Theme.of(context).primaryColor,),
                  const SizedBox(width: 5,),
                  Text(
                    'رقم الهاتف',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(onPressed: (){
                    // phoneNumberController = TextEditingController(text: SocialCubit.get(context).user!.phoneNumber);
                    showModalBottomSheet(isScrollControlled: true,context: context, builder: (context) =>
                        SizedBox(
                          width: double.infinity,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children:  [
                                const Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Text("تحديث رقم الهاتف",style: TextStyle(fontSize: 16),),
                                ),
                                const Divider(),
                                const SizedBox(height: 30,),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      right: 10,left: 10),
                                  child: TextFormField(
                                    //  controller: phoneNumberController,
                                    maxLength: 15,
                                    cursorColor: Colors.green,
                                    keyboardType:
                                    TextInputType.number,
                                    textInputAction:
                                    TextInputAction.newline,
                                    decoration: InputDecoration(
                                      labelStyle: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 18),
                                      contentPadding: const EdgeInsets.only(right: 10),
                                      labelText: ('رقم الهاتف'),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                        borderSide: BorderSide(color: Colors.black,),),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                        borderSide: BorderSide(color: Colors.black,),
                                      ),
                                    ),
                                    style: const TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.black),
                                  ),
                                ),
                                const SizedBox(height: 20,),
                                Padding(
                                  padding: const EdgeInsets.only(right: 10,left: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child:
                                        ElevatedButton(
                                          onPressed:
                                              () {
                                            // if(phoneNumberController.text != ""){
                                            //   UserDataModel model = UserDataModel(
                                            //     uId: SocialCubit.get(context).user!.uId!,
                                            //     email: SocialCubit.get(context).user!.email!,
                                            //     username: SocialCubit.get(context).user!.username!,
                                            //     image: SocialCubit.get(context).user!.image!,
                                            //     address: SocialCubit.get(context).user!.address!,
                                            //     token: SocialCubit.get(context).user!.token!,
                                            //     dateOfBirth: SocialCubit.get(context).user!.dateOfBirth!,
                                            //     edu: SocialCubit.get(context).user!.edu!,
                                            //     job: SocialCubit.get(context).user!.job!,
                                            //     nationalNumber: SocialCubit.get(context).user!.nationalNumber!,
                                            //     numberOfHours: SocialCubit.get(context).user!.numberOfHours!,
                                            //     tasksNumber: SocialCubit.get(context).user!.tasksNumber!,
                                            //     phoneNumber: phoneNumberController.text,
                                            //   );
                                            //
                                            //   FirebaseFirestore.instance
                                            //       .collection('users')
                                            //       .doc(SocialCubit.get(context).user!.uId!)
                                            //       .set(model.toJson());
                                            //
                                            //   SocialCubit.get(context).getUserData(SocialCubit.get(context).user!.uId!);
                                            //   showToastSuccess("تمت عملية الحفظ بنجاح", context);
                                            //   Navigator.pop(context);
                                            //   phoneNumberController = TextEditingController(text: "");
                                            //
                                            // }else{
                                            //   showToastFailed("يرجى تعبئة البيانات المطلوبة أولا");
                                            // }

                                          },
                                          child: const Text(
                                            "حفظ",
                                            style: TextStyle(
                                                color: Colors
                                                    .white,
                                                fontWeight:
                                                FontWeight
                                                    .bold,
                                                fontSize:
                                                20),
                                          ),
                                          style: ElevatedButton
                                              .styleFrom(
                                            padding: const EdgeInsets
                                                .only(
                                                top:
                                                3,
                                                right:
                                                3,
                                                left:
                                                3),
                                            primary: Theme.of(
                                                context)
                                                .primaryColor,
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
                                            // phoneNumberController = TextEditingController(text: "");

                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            "إلغاء",
                                            style: TextStyle(
                                                color: Colors
                                                    .black,
                                                fontWeight:
                                                FontWeight
                                                    .bold,
                                                fontSize:
                                                20),
                                          ),
                                          style: ElevatedButton
                                              .styleFrom(
                                            padding: EdgeInsets
                                                .only(
                                                top:
                                                3,
                                                right:
                                                3,
                                                left:
                                                3),
                                            primary: Colors
                                                .white,
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
                  },
                      icon: Icon(Icons.edit,color: Theme.of(context).primaryColor,))
                ],
              ),
              SizedBox(height: 20,),
              Row(
                children: [
                  Icon(Icons.phone,color: Theme.of(context).primaryColor,),
                  const SizedBox(width: 5,),
                  Text(
                    'رقم الهاتف',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(onPressed: (){
                    // phoneNumberController = TextEditingController(text: SocialCubit.get(context).user!.phoneNumber);
                    showModalBottomSheet(isScrollControlled: true,context: context, builder: (context) =>
                        SizedBox(
                          width: double.infinity,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children:  [
                                const Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Text("تحديث رقم الهاتف",style: TextStyle(fontSize: 16),),
                                ),
                                const Divider(),
                                const SizedBox(height: 30,),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      right: 10,left: 10),
                                  child: TextFormField(
                                    //  controller: phoneNumberController,
                                    maxLength: 15,
                                    cursorColor: Colors.green,
                                    keyboardType:
                                    TextInputType.number,
                                    textInputAction:
                                    TextInputAction.newline,
                                    decoration: InputDecoration(
                                      labelStyle: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 18),
                                      contentPadding: const EdgeInsets.only(right: 10),
                                      labelText: ('رقم الهاتف'),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                        borderSide: BorderSide(color: Colors.black,),),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                        borderSide: BorderSide(color: Colors.black,),
                                      ),
                                    ),
                                    style: const TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.black),
                                  ),
                                ),
                                const SizedBox(height: 20,),
                                Padding(
                                  padding: const EdgeInsets.only(right: 10,left: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child:
                                        ElevatedButton(
                                          onPressed:
                                              () {
                                            // if(phoneNumberController.text != ""){
                                            //   UserDataModel model = UserDataModel(
                                            //     uId: SocialCubit.get(context).user!.uId!,
                                            //     email: SocialCubit.get(context).user!.email!,
                                            //     username: SocialCubit.get(context).user!.username!,
                                            //     image: SocialCubit.get(context).user!.image!,
                                            //     address: SocialCubit.get(context).user!.address!,
                                            //     token: SocialCubit.get(context).user!.token!,
                                            //     dateOfBirth: SocialCubit.get(context).user!.dateOfBirth!,
                                            //     edu: SocialCubit.get(context).user!.edu!,
                                            //     job: SocialCubit.get(context).user!.job!,
                                            //     nationalNumber: SocialCubit.get(context).user!.nationalNumber!,
                                            //     numberOfHours: SocialCubit.get(context).user!.numberOfHours!,
                                            //     tasksNumber: SocialCubit.get(context).user!.tasksNumber!,
                                            //     phoneNumber: phoneNumberController.text,
                                            //   );
                                            //
                                            //   FirebaseFirestore.instance
                                            //       .collection('users')
                                            //       .doc(SocialCubit.get(context).user!.uId!)
                                            //       .set(model.toJson());
                                            //
                                            //   SocialCubit.get(context).getUserData(SocialCubit.get(context).user!.uId!);
                                            //   showToastSuccess("تمت عملية الحفظ بنجاح", context);
                                            //   Navigator.pop(context);
                                            //   phoneNumberController = TextEditingController(text: "");
                                            //
                                            // }else{
                                            //   showToastFailed("يرجى تعبئة البيانات المطلوبة أولا");
                                            // }

                                          },
                                          child: const Text(
                                            "حفظ",
                                            style: TextStyle(
                                                color: Colors
                                                    .white,
                                                fontWeight:
                                                FontWeight
                                                    .bold,
                                                fontSize:
                                                20),
                                          ),
                                          style: ElevatedButton
                                              .styleFrom(
                                            padding: const EdgeInsets
                                                .only(
                                                top:
                                                3,
                                                right:
                                                3,
                                                left:
                                                3),
                                            primary: Theme.of(
                                                context)
                                                .primaryColor,
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
                                            // phoneNumberController = TextEditingController(text: "");

                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            "إلغاء",
                                            style: TextStyle(
                                                color: Colors
                                                    .black,
                                                fontWeight:
                                                FontWeight
                                                    .bold,
                                                fontSize:
                                                20),
                                          ),
                                          style: ElevatedButton
                                              .styleFrom(
                                            padding: EdgeInsets
                                                .only(
                                                top:
                                                3,
                                                right:
                                                3,
                                                left:
                                                3),
                                            primary: Colors
                                                .white,
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
                  },
                      icon: Icon(Icons.edit,color: Theme.of(context).primaryColor,))
                ],
              ),
              SizedBox(height: 20,),
              Row(
                children: [
                  Icon(Icons.phone,color: Theme.of(context).primaryColor,),
                  const SizedBox(width: 5,),
                  Text(
                    'رقم الهاتف',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(onPressed: (){
                    // phoneNumberController = TextEditingController(text: SocialCubit.get(context).user!.phoneNumber);
                    showModalBottomSheet(isScrollControlled: true,context: context, builder: (context) =>
                        SizedBox(
                          width: double.infinity,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children:  [
                                const Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Text("تحديث رقم الهاتف",style: TextStyle(fontSize: 16),),
                                ),
                                const Divider(),
                                const SizedBox(height: 30,),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      right: 10,left: 10),
                                  child: TextFormField(
                                    //  controller: phoneNumberController,
                                    maxLength: 15,
                                    cursorColor: Colors.green,
                                    keyboardType:
                                    TextInputType.number,
                                    textInputAction:
                                    TextInputAction.newline,
                                    decoration: InputDecoration(
                                      labelStyle: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 18),
                                      contentPadding: const EdgeInsets.only(right: 10),
                                      labelText: ('رقم الهاتف'),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                        borderSide: BorderSide(color: Colors.black,),),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                        borderSide: BorderSide(color: Colors.black,),
                                      ),
                                    ),
                                    style: const TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.black),
                                  ),
                                ),
                                const SizedBox(height: 20,),
                                Padding(
                                  padding: const EdgeInsets.only(right: 10,left: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child:
                                        ElevatedButton(
                                          onPressed:
                                              () {
                                            // if(phoneNumberController.text != ""){
                                            //   UserDataModel model = UserDataModel(
                                            //     uId: SocialCubit.get(context).user!.uId!,
                                            //     email: SocialCubit.get(context).user!.email!,
                                            //     username: SocialCubit.get(context).user!.username!,
                                            //     image: SocialCubit.get(context).user!.image!,
                                            //     address: SocialCubit.get(context).user!.address!,
                                            //     token: SocialCubit.get(context).user!.token!,
                                            //     dateOfBirth: SocialCubit.get(context).user!.dateOfBirth!,
                                            //     edu: SocialCubit.get(context).user!.edu!,
                                            //     job: SocialCubit.get(context).user!.job!,
                                            //     nationalNumber: SocialCubit.get(context).user!.nationalNumber!,
                                            //     numberOfHours: SocialCubit.get(context).user!.numberOfHours!,
                                            //     tasksNumber: SocialCubit.get(context).user!.tasksNumber!,
                                            //     phoneNumber: phoneNumberController.text,
                                            //   );
                                            //
                                            //   FirebaseFirestore.instance
                                            //       .collection('users')
                                            //       .doc(SocialCubit.get(context).user!.uId!)
                                            //       .set(model.toJson());
                                            //
                                            //   SocialCubit.get(context).getUserData(SocialCubit.get(context).user!.uId!);
                                            //   showToastSuccess("تمت عملية الحفظ بنجاح", context);
                                            //   Navigator.pop(context);
                                            //   phoneNumberController = TextEditingController(text: "");
                                            //
                                            // }else{
                                            //   showToastFailed("يرجى تعبئة البيانات المطلوبة أولا");
                                            // }

                                          },
                                          child: const Text(
                                            "حفظ",
                                            style: TextStyle(
                                                color: Colors
                                                    .white,
                                                fontWeight:
                                                FontWeight
                                                    .bold,
                                                fontSize:
                                                20),
                                          ),
                                          style: ElevatedButton
                                              .styleFrom(
                                            padding: const EdgeInsets
                                                .only(
                                                top:
                                                3,
                                                right:
                                                3,
                                                left:
                                                3),
                                            primary: Theme.of(
                                                context)
                                                .primaryColor,
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
                                            // phoneNumberController = TextEditingController(text: "");

                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            "إلغاء",
                                            style: TextStyle(
                                                color: Colors
                                                    .black,
                                                fontWeight:
                                                FontWeight
                                                    .bold,
                                                fontSize:
                                                20),
                                          ),
                                          style: ElevatedButton
                                              .styleFrom(
                                            padding: EdgeInsets
                                                .only(
                                                top:
                                                3,
                                                right:
                                                3,
                                                left:
                                                3),
                                            primary: Colors
                                                .white,
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
                  },
                      icon: Icon(Icons.edit,color: Theme.of(context).primaryColor,))
                ],
              ),


            ],
          ),
        );

      });
  }


}

