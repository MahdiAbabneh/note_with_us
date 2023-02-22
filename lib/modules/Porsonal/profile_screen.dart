
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:mahdeko/Compouents/constant_empty.dart';
import 'package:mahdeko/Compouents/constants.dart';
import 'package:mahdeko/Compouents/widgets.dart';
import 'package:mahdeko/Layout/Home/cubit/cubit.dart';
import 'package:mahdeko/Layout/Home/cubit/states.dart';
import 'package:mahdeko/Locale/locale_controller.dart';
import 'package:mahdeko/models/user_data_model.dart';
import 'package:mahdeko/modules/Login/login_screen.dart';
import 'package:mahdeko/network/cache_helper.dart';
import 'package:toggle_switch/toggle_switch.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});


  @override
  Widget build(BuildContext context) {
    var cubit = HomeCubit.get(context);
    MyLocaleController controllerLang= Get.find();
    return BlocConsumer<HomeCubit, HomeStates>(
      listener: (context, state) {
        if(state is UserSelectProfileImageSuccess){
          cubit.uploadUserProfileImage(context);
        }
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
                  if(state is  UserProfileImageUploadLoading||state is UserUpdateDataLoading)
                     LinearProgressIndicator(color: Theme.of(context).primaryColor,backgroundColor:Colors.white ),
                  SizedBox(height: 10,),
                  Center(
                    child: ToggleSwitch(
                      minWidth: double.infinity,
                      initialLabelIndex: 0,
                      cornerRadius: 15.0,
                      activeFgColor: Colors.white,
                      inactiveBgColor: Colors.grey,
                      inactiveFgColor: Colors.white,
                      totalSwitches: 2,
                      labels:CacheHelper.getData(key:"lang")=="ar"? ['العربية', 'English']:['English', 'العربية'],
                      onToggle: (index) {
                        if(CacheHelper.getData(key:"lang")=="ar")
                        {
                          controllerLang.changeLang("en");
                        }
                        else{
                          controllerLang.changeLang("ar");
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10,),
                  Divider(),
                  Stack(alignment: Alignment.center,
                      children:[

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
                                    minRadius:responsive(context, 93.0, 190.0),
                                    child:CircleAvatar(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      radius:  responsive(context, 90.0, 180.0),
                                      backgroundImage:CachedNetworkImageProvider(profileImage!),
                                    )),
                                SizedBox(height: 20,),
                                Column(children: [
                                  Container(
                                    width: double.infinity,
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
                                    width: double.infinity,
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
                                  const SizedBox(height: 10,),
                                ],),

                              ],
                            ),
                          ),
                            IconButton(
                                onPressed: (){
                                  AwesomeDialog(
                                    customHeader: Icon(FontAwesomeIcons.circleInfo,size: responsive(context, 50.0, 150.0),color: Theme.of(context).primaryColor,),
                                    showCloseIcon: true,
                                    btnCancel: null,
                                    btnOk: null,
                                    body:Column(children: [
                                       Text(
                                        selectImageText.tr,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: responsive(context, 18.0, 28)),
                                      ),
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                              onPressed: () {
                                               cubit.selectProfileImageFromCamera();
                                                Navigator.of(context).pop();
                                              },
                                              icon:  Icon(
                                                FontAwesomeIcons.cameraRetro,color: Theme.of(context).primaryColor,
                                                size: responsive(context, 35.0, 70.0),
                                              )),
                                          const SizedBox(
                                            width: 50,
                                          ),
                                          IconButton(
                                              onPressed: () {
                                               cubit.selectProfileImageFromGallery();
                                                Navigator.of(context).pop();
                                              },
                                              icon:  Icon(
                                                FontAwesomeIcons.image,
                                                color: Theme.of(context).primaryColor,
                                                size: responsive(context, 35.0, 70.0),
                                              )),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 40,
                                      ),
                                    ]),
                                      context: context,
                                      dialogType: DialogType.question,
                                      animType: AnimType.scale,
                                      title:selectImageText.tr,
                                  ).show();
                                },
                                icon: Icon( FontAwesomeIcons.camera,color: Theme.of(context).primaryColor,size:  responsive(context, 35.0, 70.0),)),
                          ]
                        ),
                      ]
                  ),
                  Divider(),
                  const SizedBox(height: 5,),
                  Container(
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey,width: 0.7),
                        borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 5,),
                        Icon(FontAwesomeIcons.userLarge,color:Theme.of(context).primaryColor),
                        const SizedBox(width: 10,),
                        Text(
                          nameText.tr,
                          style: TextStyle(
                            color:Theme.of(context).primaryColor,
                            fontSize: responsive(context, 16.0, 22.0),

                          ),
                        ),
                        const SizedBox(width: 35,),
                        Expanded(
                          child: Text(
                            usernameData!,
                            style: TextStyle(
                              decoration: TextDecoration.underline,
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
                                               ),
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
                            icon: Icon(FontAwesomeIcons.edit,color: Theme.of(context).primaryColor,))
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
                        Icon(FontAwesomeIcons.phone,color: Theme.of(context).primaryColor,),
                        const SizedBox(width: 10,),
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
                              decoration: TextDecoration.underline,
                              color: Theme.of(context).primaryColor,
                              fontSize:  responsive(context, 18.0, 24.0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 35,),
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
                                      const SizedBox(height: 10,),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                              child: Row(
                                                children: [
                                                  const Icon(FontAwesomeIcons.circleInfo,color: Colors.red,),
                                                  const SizedBox(width: 10,),
                                                  Text(
                                                    thePhoneInfo.tr,
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
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
                                               ),
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
                            icon: Icon(phoneNumberData==""?Icons.add_circle_outline:FontAwesomeIcons.edit,color: Theme.of(context).primaryColor,))
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
                        Icon(FontAwesomeIcons.locationArrow,color: Theme.of(context).primaryColor,),
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
                              decoration: TextDecoration.underline,
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
                                          readOnly: true,
                                          onTap: (){
                                            showCountryPicker(
                                              exclude: <String>['IL'],
                                              showSearch:false,
                                              countryListTheme: CountryListThemeData(
                                                borderRadius: BorderRadius.all(Radius.circular(1)),
                                                bottomSheetHeight: MediaQuery.of(context).size.width,
                                              ),
                                              context: context,
                                              showPhoneCode: false,
                                              onSelect: (Country country) {
                                                userAddressProfileController.text= country.name;
                                              },
                                            );
                                          },
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
                            icon: Icon(addressData==""?Icons.add_circle_outline:FontAwesomeIcons.edit,color: Theme.of(context).primaryColor,))
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
                        Icon(FontAwesomeIcons.eyeDropper,color:Theme.of(context).primaryColor),
                        const SizedBox(width: 10,),
                        Text(
                          themeText.tr,
                          style: TextStyle(
                            color:Theme.of(context).primaryColor,
                            fontSize: responsive(context, 16.0, 22.0),

                          ),
                        ),
                        const SizedBox(width: 38,),
                        Expanded(
                          child: Text(
                            themeData!,
                            style: TextStyle(
                              decoration: TextDecoration.underline,
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
                                        child: Text(themeText.tr,style: TextStyle(fontSize: responsive(context, 16.0, 22.0),),),
                                      ),
                                      const Divider(),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child:  Row(
                                          children: [
                                            const Icon(FontAwesomeIcons.infoCircle,color: Colors.red,),
                                            const SizedBox(width: 10,),
                                                  Text(
                                                    theThemeInfo.tr,
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                    ),
                                                  ),
                                                ],
                                        ),
                                      ),

                                      const SizedBox(height: 30,),
                                      Center(
                                        child: ToggleSwitch(
                                          minWidth: double.infinity,
                                          initialLabelIndex:themeData == 'origin'
                                              ? 0
                                              : themeData == 'blue'
                                              ? 1
                                              : themeData == 'pink'
                                              ? 2
                                              : 0,
                                          cornerRadius: 15.0,
                                          activeFgColor: Colors.white,
                                          inactiveBgColor: Colors.grey,
                                          inactiveFgColor: Colors.white,
                                          totalSwitches: 3,
                                          labels: [
                                            originColor.tr,
                                            blueColor.tr,
                                            pinkColor.tr
                                          ],
                                          activeBgColors: const [[Colors.amber], [Colors.blue], [Colors.pink]],
                                          onToggle: (index) {
                                            if(index==0)
                                              {
                                               themeData='origin';
                                               }
                                            else if(index==1)
                                              {
                                                themeData='blue';
                                              }
                                            else if(index==2){
                                              themeData='pink';
                                            }
                                            Get.changeTheme(FlexThemeData.light(
                                              scheme: themeData == 'origin'
                                                  ? FlexScheme.mango
                                                  : themeData == 'blue'
                                                  ? FlexScheme.ebonyClay
                                                  : themeData == 'pink'
                                                  ? FlexScheme.sakura
                                                  : FlexScheme.mango,
                                              fontFamily:
                                              CacheHelper.getData(key: "lang") == "ar" ? "Almarai" : "mali",
                                            ),);
                                                CacheHelper.sharedPreferences?.setString("theme", themeData!);
                                                FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(FirebaseAuth.instance.currentUser!.uid).update(
                                                    {"theme": themeData!});
                                                Navigator.pop(context);

                                          },
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
                            icon: Icon(FontAwesomeIcons.edit,color: Theme.of(context).primaryColor,))
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
                        Icon(FontAwesomeIcons.circleInfo,color:Theme.of(context).primaryColor),
                        const SizedBox(width: 10,),
                        Text(
                          logoutText.tr,
                          style: TextStyle(
                            color:Theme.of(context).primaryColor,
                            fontSize: responsive(context, 16.0, 22.0),

                          ),
                        ),
                       Spacer(),
                        IconButton(onPressed: (){
                          FirebaseAuth.instance.signOut().whenComplete(() => {
                            CacheHelper.sharedPreferences?.remove("id"),
                            CacheHelper.sharedPreferences!.clear()
                          }).whenComplete(() => {
                            navigatePushReplacement(context, const LoginScreen()),
                          });
                        },
                            icon: Icon(FontAwesomeIcons.signOutAlt,color: Theme.of(context).primaryColor,))
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

