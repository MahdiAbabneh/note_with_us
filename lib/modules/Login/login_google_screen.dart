import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mahdeko/Compouents/adaptive_indicator.dart';
import 'package:mahdeko/Compouents/constant_empty.dart';
import 'package:mahdeko/Compouents/constants.dart';
import 'package:mahdeko/Compouents/widgets.dart';
import 'package:mahdeko/Layout/Home/home_layout.dart';
import 'package:mahdeko/network/cache_helper.dart';
import 'cubit/cubit.dart';
import 'cubit/states.dart';





class LoginGoogleScreen extends StatelessWidget {
  const LoginGoogleScreen({super.key});
  @override
  Widget build(BuildContext context) {
    var cubit = LoginCubit.get(context);
    return BlocConsumer<LoginCubit, LoginStates>(
      listener: (context, state) {
        if(state is UserLoginGoogleInfoSuccess)
          {
            CacheHelper.sharedPreferences?.setString("id", FirebaseAuth.instance.currentUser!.uid.toString())
                .whenComplete(() => {
              idForUser = CacheHelper.getData(key:'id'),
            })
                .whenComplete(() => {
              Phoenix.rebirth(Get.context!),
              navigatePushReplacement(context,  const HomeLayout()),
              showToastSuccess(toast3.tr, context),
            });
        }
        if(state is UserLoginGoogleInfoError)
          {
            showToastFailed(toast1.tr,context);
          }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(toolbarHeight: 1,),
          backgroundColor: Colors.white,
          body: Dialog(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(loginProcess.tr),
                    const SizedBox(height:20),
                    Form(key:JosKeys.formKeyLogin,
                      child: Column(
                        children: [
                          DropdownButtonFormField2(
                            decoration:  InputDecoration(
                              errorMaxLines: 1,
                              prefixIcon: Icon(Icons.group,color:Theme.of(context).primaryColor,),
                              labelStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize:responsive(context, 14.0, 18.0)),
                              contentPadding: const EdgeInsets.only(right: 10),
                              labelText: genderText.tr,
                              border:  OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: BorderSide(color:Theme.of(context).primaryColor,),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                borderSide: BorderSide(color: Theme.of(context).primaryColor,),
                              ),
                            ),
                            isExpanded: true,
                            icon:  Padding(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: Icon(
                                Icons.arrow_drop_down,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            buttonHeight: 50,
                            dropdownDecoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            items: [
                              male.toString().tr,
                              female.toString().tr,
                            ]
                                .map((item) =>
                                DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(
                                    item,
                                    style:  TextStyle(
                                      fontSize: responsive(context, 14.0, 18.0),
                                    ),
                                  ),
                                ))
                                .toList(),
                            validator: (value) {
                              if (value == null) {
                                return regex5.tr;
                              }
                              return null;
                            },
                            onChanged: (value) { selectedGenderLoginValue = value.toString();},
                          ),
                          const SizedBox(height: 20,),
                          TextFormField(
                            onTap: (){
                              cubit.selectDateLogin(context);
                            },
                            readOnly: true,
                            controller: dateOfBirthLoginController,
                            validator: (value) {
                              if(value!.isEmpty){
                                return regex6.tr;
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
                              prefixIcon: Icon(Icons.date_range,color:Theme.of(context).primaryColor,),

                              labelStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize:  responsive(context, 14.0, 18.0)),
                              contentPadding: const EdgeInsets.only(right: 10),
                              labelText: (dateOfBirthText.tr),
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
                          const SizedBox(height: 20,),
                          TextFormField(
                            controller: userNameLoginController,
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 20,),
                    ConditionalBuilder(
                      fallback: (context) =>
                      const Center(child: AdaptiveIndicator()),
                      condition: state is! UserLoginLoading,
                      builder:(context) =>   ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor:  const Color(
                              0xFFC27D3C),
                          ),
                          onPressed: () {
                            if (JosKeys.formKeyLogin.currentState!.validate())
                            {
                              cubit.signInWithGoogleSuccess();
                            }
                          },
                          child: Text(loginText.tr, style:  TextStyle(
                              fontWeight: FontWeight.bold, fontSize:  responsive(context, 14.0, 18.0)),)),
                    ),


                  ],),
              ),
            ),
          ),
        );


      },
    );
  }

}
