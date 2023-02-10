
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:mahdeko/Compouents/constant_empty.dart';
import 'package:mahdeko/Compouents/constants.dart';
import 'package:mahdeko/Compouents/widgets.dart';
import 'package:mahdeko/Layout/Home/cubit/cubit.dart';
import 'package:mahdeko/Layout/Home/cubit/states.dart';
import 'package:mahdeko/models/user_data_model.dart';
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
          body:Padding(
            padding: const EdgeInsets.all(10.0),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
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
                                    minRadius:responsive(context, 95.0, 190.0),
                                    child:CircleAvatar(
                                      radius:  responsive(context, 90.0, 180.0),
                                      backgroundImage:
                                      genderData=="Male"? const AssetImage("assets/images/boy.png",):const AssetImage("assets/images/giral.png",),
                                    )),
                                const SizedBox(
                                  height: 5,
                                ),
                                Column(children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        borderRadius: BorderRadius.circular(15.0)),
                                    clipBehavior: Clip.antiAliasWithSaveLayer,
                                    child: Text(
                                      textAlign: TextAlign.center,
                                      usernameData!,
                                      style:  TextStyle(
                                        fontSize: responsive(context, 20.0, 26.0),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10,),
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        borderRadius: BorderRadius.circular(15.0)),
                                    clipBehavior: Clip.antiAliasWithSaveLayer,
                                    child: Text(
                                      textAlign: TextAlign.center,
                                      "${cubit.durationAge!.years} ${years.tr}",
                                      style:  TextStyle(
                                        fontSize:  responsive(context, 20.0, 26.0),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],),

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
                  const SizedBox(height: 20,),
                  Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey,width: 0.7),
                        borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 5,),
                        Icon(Icons.person,color:Theme.of(context).primaryColor),
                        const SizedBox(width: 5,),
                        Text(
                          userNameText.tr,
                          style: TextStyle(
                            color:Theme.of(context).primaryColor,
                            fontSize: responsive(context, 16.0, 22.0),

                          ),
                        ),
                        const SizedBox(width: 10,),
                        Expanded(
                          child: Text(
                            usernameData!,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize:  responsive(context, 18.0, 24.0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20,),
                        IconButton(onPressed: (){
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
                                        child: Text(userNameText.tr,style: TextStyle(fontSize: responsive(context, 16.0, 22.0),),),
                                      ),
                                      const Divider(),
                                      const SizedBox(height: 30,),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            right: 10,left: 10),
                                        child:  Form(key: JosKeys.formKeyUserNameProfile,
                                          child: TextFormField(
                                            controller: userNameProfileController,
                                            validator: (value) {
                                              if(value!.length < 3 || value.length > 15){
                                                return regex1.tr;
                                              }else{
                                                return null;
                                              }
                                            },
                                            cursorColor: Theme.of(context).primaryColor,
                                            keyboardType:
                                            TextInputType.text,
                                            textInputAction:
                                            TextInputAction.newline,
                                            decoration:  InputDecoration(
                                              errorMaxLines: 2,
                                              prefixIcon: Icon(Icons.person,color:Theme.of(context).primaryColor,),

                                              labelStyle: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize:  responsive(context, 14.0, 18.0)),
                                              contentPadding: const EdgeInsets.only(right: 10),
                                              labelText: (userNameText.tr),
                                              border:  OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(15.0),
                                                borderSide: BorderSide(color:Theme.of(context).primaryColor,),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(15.0),
                                                borderSide: BorderSide(color: Theme.of(context).primaryColor,),
                                              ),
                                            ),
                                            style: const TextStyle(
                                                fontSize: 20.0,
                                                color: Colors.black),
                                          ),
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
                                                  if(JosKeys.formKeyUserNameProfile.currentState!.validate())
                                                    {
                                                      Navigator.pop(context);
                                                      cubit.updateUserData("username", userNameProfileController.text);
                                                    }
                                                },
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
                                                child:  Text(
                                                  save.tr,
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
                                                  padding: const EdgeInsets
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
                        },
                            icon: Icon(Icons.edit,color: Theme.of(context).primaryColor,))
                      ],
                    ),
                  ),
                  const SizedBox(height: 20,),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey,width: 0.7),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 5,),
                        Icon(Icons.phone,color: Theme.of(context).primaryColor,),
                        const SizedBox(width: 5,),
                        Expanded(flex: 1,
                          child: Text(
                            phoneText.tr,
                            style: TextStyle(
                              color:Theme.of(context).primaryColor,
                              fontSize: responsive(context, 16.0, 22.0),

                            ),
                          ),
                        ),
                        Expanded(flex: 2,
                          child: Text(
                            phoneNumberData!,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize:  responsive(context, 18.0, 24.0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20,),
                        IconButton(onPressed: (){
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
                                        child: Text(phoneText.tr,style: TextStyle(fontSize: responsive(context, 16.0, 22.0),),),
                                      ),
                                      const Divider(),
                                      const SizedBox(height: 30,),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            right: 10,left: 10),
                                        child:  Form(key: JosKeys.formKeyPhoneNumberProfile,
                                          child: TextFormField(maxLength: 10,
                                            controller: userPhoneProfileController,
                                            validator: (value) {
                                              if((value!.length < 10&&value.isNotEmpty)){
                                                return regex7.tr;
                                              }else{
                                                return null;
                                              }
                                            },
                                            cursorColor: Theme.of(context).primaryColor,
                                            keyboardType:
                                            TextInputType.number,
                                            textInputAction:
                                            TextInputAction.newline,
                                            decoration:  InputDecoration(
                                              errorMaxLines: 2,
                                              prefixIcon: Icon(Icons.phone,color:Theme.of(context).primaryColor,),
                                              labelStyle: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize:  responsive(context, 14.0, 18.0)),
                                              contentPadding: const EdgeInsets.only(right: 10),
                                              labelText: (phoneText.tr),
                                              border:  OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(15.0),
                                                borderSide: BorderSide(color:Theme.of(context).primaryColor,),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(15.0),
                                                borderSide: BorderSide(color: Theme.of(context).primaryColor,),
                                              ),
                                            ),
                                            style: const TextStyle(
                                                fontSize: 20.0,
                                                color: Colors.black),
                                          ),
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
                                                      if(JosKeys.formKeyPhoneNumberProfile.currentState!.validate())
                                                      {
                                                        Navigator.pop(context);
                                                        cubit.updateUserData("phoneNumber", userPhoneProfileController.text??"");
                                                      }
                                                },
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
                                                child:  Text(
                                                  save.tr,
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
                                                  padding: const EdgeInsets
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
                        },
                            icon: Icon(phoneNumberData==""?Icons.add_circle:Icons.edit,color: Theme.of(context).primaryColor,))
                      ],
                    ),
                  ),
                  const SizedBox(height: 20,),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey,width: 0.7),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 5,),
                        Icon(Icons.pin_drop,color: Theme.of(context).primaryColor,),
                        const SizedBox(width: 5,),
                        Expanded(flex: 1,
                          child: Text(
                            addressText.tr,
                            style: TextStyle(
                              color:Theme.of(context).primaryColor,
                              fontSize: responsive(context, 16.0, 22.0),

                            ),
                          ),
                        ),
                        Expanded(flex: 2,
                          child: Text(
                            addressData!,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize:  responsive(context, 18.0, 24.0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20,),
                        IconButton(onPressed: (){
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
                                        child: Text(addressText.tr,style: TextStyle(fontSize: responsive(context, 16.0, 22.0),),),
                                      ),
                                      const Divider(),
                                      const SizedBox(height: 30,),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            right: 10,left: 10),
                                        child:  TextFormField(
                                          maxLength: 10,
                                          controller: userAddressProfileController,
                                          cursorColor: Theme.of(context).primaryColor,
                                          keyboardType:
                                          TextInputType.text,
                                          textInputAction:
                                          TextInputAction.newline,
                                          decoration:  InputDecoration(
                                            errorMaxLines: 2,
                                            prefixIcon: Icon(Icons.pin_drop,color:Theme.of(context).primaryColor,),
                                            labelStyle: TextStyle(
                                                color: Colors.grey,
                                                fontSize:  responsive(context, 14.0, 18.0)),
                                            contentPadding: const EdgeInsets.only(right: 10),
                                            labelText: (addressText.tr),
                                            border:  OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(15.0),
                                              borderSide: BorderSide(color:Theme.of(context).primaryColor,),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(15.0),
                                              borderSide: BorderSide(color: Theme.of(context).primaryColor,),
                                            ),
                                          ),
                                          style: const TextStyle(
                                              fontSize: 20.0,
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

                                                        Navigator.pop(context);
                                                        cubit.updateUserData("location", userAddressProfileController.text??"");

                                                },
                                                style: ElevatedButton
                                                    .styleFrom(
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
                                                  save.tr,
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
                                                  padding: const EdgeInsets
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
                        },
                            icon: Icon(addressData==""?Icons.add_circle:Icons.edit,color: Theme.of(context).primaryColor,))
                      ],
                    ),
                  ),


                ],
              ),
            ),
          ),
        );

      });
  }


}

