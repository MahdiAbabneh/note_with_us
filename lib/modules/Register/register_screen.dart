import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mahdeko/Compouents/adaptive_indicator.dart';
import 'package:mahdeko/Compouents/constant_empty.dart';
import 'package:mahdeko/Compouents/constants.dart';
import 'package:mahdeko/Compouents/widgets.dart';
import 'package:mahdeko/Layout/Home/home_layout.dart';
import 'package:mahdeko/Locale/locale_controller.dart';
import 'package:mahdeko/network/cache_helper.dart';
import 'cubit/cubit.dart';
import 'cubit/states.dart';

TextEditingController userNameController = TextEditingController();
TextEditingController emailController = TextEditingController();
TextEditingController passwordController = TextEditingController();
TextEditingController confirmPasswordController = TextEditingController();

final formKey = GlobalKey<FormState>();


class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    var cubit = RegisterCubit.get(context);
    return BlocConsumer<RegisterCubit, RegisterStates>(
      listener: (context, state) {
        if(state is UserRegisterSuccess)
        {
          CacheHelper.sharedPreferences?.clear().whenComplete(() =>
              CacheHelper.sharedPreferences?.setString("id", FirebaseAuth.instance.currentUser!.uid.toString()))
              .whenComplete(() => {
            idForUser = CacheHelper.getData(key:'id'),
          })
              .whenComplete(() => {
            showToastSuccess(toast2.tr, context),
            navigatePushReplacement(context, const HomeLayout())
          });
        }
        if(state is UserRegisterError)
        {
          showToastFailed(toast4.tr,context);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title:  Text(createAccount.tr),backgroundColor: Theme.of(context).primaryColor,),
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(children: [
                const SizedBox(height: 10,),
                Container(
                  height: responsive(context, 180.0, 400.0),
                  color: Colors.white,
                  width: double.infinity,
                  child: Image.asset("assets/images/NWU2.png"),
                ),
                const SizedBox(height: 30),
                Form(
                  key: formKey,
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
                        onChanged: (value) { cubit.selectedGenderValue = value.toString();},
                      ),
                      const SizedBox(height: 20,),
                      TextFormField(
                        controller: userNameController,
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
                      ),//
                      const SizedBox(height: 20,),
                      TextFormField(
                        controller: emailController,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return regex2.tr;
                          }

                          return null;
                        },
                        cursorColor: Theme.of(context).primaryColor,
                        keyboardType:
                        TextInputType.emailAddress,
                        textInputAction:
                        TextInputAction.newline,
                        decoration:  InputDecoration(
                          prefixIcon: Icon(Icons.email,color: Theme.of(context).primaryColor,),

                          labelStyle: TextStyle(
                              color: Colors.grey,
                              fontSize:  responsive(context, 14.0, 18.0)),
                          contentPadding: const EdgeInsets.only(right: 10),
                          labelText: email.tr,
                          border:  OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide(color: Theme.of(context).primaryColor,),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide(color:Theme.of(context).primaryColor,),
                          ),
                        ),
                        style: const TextStyle(
                            fontSize: 20.0,
                            color: Colors.black),
                      ),//
                      const SizedBox(height: 20,),
                      TextFormField(
                        controller: passwordController,
                        validator: (value) {
                          if(value!.length < 6 || value.length > 10){
                            return regex3.tr;
                          }else{
                            return null;
                          }
                        },
                        cursorColor:Theme.of(context).primaryColor,
                        keyboardType:
                        TextInputType.visiblePassword,
                        textInputAction:
                        TextInputAction.newline,
                        obscureText: cubit.isPassword,
                        decoration:  InputDecoration(
                          errorMaxLines: 2,
                          suffixIcon: InkWell(onTap: (){
                            cubit.changePasswordVisibility();
                          },child: Icon(cubit.suffixPassword,color: Theme.of(context).primaryColor,)),
                          prefixIcon:  Icon(Icons.lock,color:Theme.of(context).primaryColor,),

                          labelStyle:  TextStyle(
                              color: Colors.grey,
                              fontSize:  responsive(context, 14.0, 18.0)),
                          contentPadding: const EdgeInsets.only(right: 10),
                          labelText: (password.tr),
                          border:  OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide(color: Theme.of(context).primaryColor,),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide:  BorderSide(color: Theme.of(context).primaryColor,),
                          ),
                        ),
                        style: const TextStyle(
                            fontSize: 20.0,
                            color: Colors.black),
                      ),//
                      const SizedBox(height: 20,),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: cubit.isConfirmPassword,
                        validator: (value) {
                          if (value != passwordController.text) {
                            return regex4.tr;
                          }

                          return null;
                        },
                        cursorColor:Theme.of(context).primaryColor,
                        keyboardType:
                        TextInputType.visiblePassword,
                        textInputAction:
                        TextInputAction.newline,
                        decoration:  InputDecoration(
                          suffixIcon: InkWell(onTap: (){
                           cubit.changeConfirmPasswordVisibility();
                          },
                              child: Icon(cubit.suffixConfirmPassword,color:Theme.of(context).primaryColor,)),
                          prefixIcon:  Icon(Icons.lock,color: Theme.of(context).primaryColor,),

                          labelStyle:  TextStyle(
                              color: Colors.grey,
                              fontSize:  responsive(context, 14.0, 18.0)),
                          contentPadding: const EdgeInsets.only(right: 10),
                          labelText: (confirmPasswordText.tr),
                          border:  OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide(color: Theme.of(context).primaryColor,),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide(color:Theme.of(context).primaryColor,),
                          ),
                        ),
                        style: const TextStyle(
                            fontSize: 20.0,
                            color: Colors.black),
                      ),//
                      const SizedBox(height: 40,),
                      SizedBox(width: double.infinity,child: SizedBox(
                        height: 50,
                        child:ConditionalBuilder(
                          fallback: (context) =>
                          const Center(child: AdaptiveIndicator()),
                          condition: state is! UserRegisterLoading,
                          builder:(context) =>   ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor,

                              ),onPressed: (){

                            if (formKey.currentState!.validate()) {
                              cubit.registerForUser(emailController.text, passwordController.text);
                              print(emailController.text);
                              print(passwordController.text);

                            }


                          },
                              child:
                              Text(createAccount.tr,style: TextStyle(fontWeight: FontWeight.bold,fontSize:  responsive(context, 14.0, 18.0)),)),
                        ),

                      )),



                    ],
                  ),
                )

              ],),
            ),
          ),
        );
      },
    );
  }
}
