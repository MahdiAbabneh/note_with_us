import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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




class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    var cubit = RegisterCubit.get(context);
    return BlocConsumer<RegisterCubit, RegisterStates>(
      listener: (context, state) {
        if(state is UserRegisterSuccess)
        {
              CacheHelper.sharedPreferences?.setString("id", FirebaseAuth.instance.currentUser!.uid.toString())
              .whenComplete(() => {
            idForUser = CacheHelper.getData(key:'id'),
          })
              .whenComplete(() => {
            Phoenix.rebirth(Get.context!),
            navigatePushReplacement(context,  const HomeLayout()),
            showToastSuccess(toast2.tr, context),
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
              child: Column(
              children: [
                const SizedBox(height: 10,),
                Container(
                  height: responsive(context, 120.0, 240.0),
                  color: Colors.white,
                  width: double.infinity,
                  child: Image.asset("assets/images/NWU2.png"),
                ),
                const SizedBox(height: 30),
                Form(
                  key: JosKeys.formKeyRegister,
                  child: Column(
                    children: [
                      DropdownButtonFormField2(
                        decoration:  InputDecoration(
                          enabledBorder:OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide:  const BorderSide(color: Colors.grey),
                          ) ,
                          errorMaxLines: 1,
                          prefixIcon: Icon(FontAwesomeIcons.venusMars,color:Theme.of(context).primaryColor,),
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
                        onChanged: (value) { selectedGenderRegisterValue = value.toString();},
                      ),
                      const SizedBox(height: 20,),
                      TextFormField(

                        onTap: (){
                          cubit.selectDateRegister(context);
                        },
                        readOnly: true,
                        controller: dateOfBirthRegisterController,
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

                          enabledBorder:OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide:  const BorderSide(color: Colors.grey),
                          ) ,
                          errorMaxLines: 2,
                          prefixIcon: Icon(FontAwesomeIcons.solidCalendarDays,color:Theme.of(context).primaryColor,),

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
                        ),
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
                          enabledBorder:OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide:  const BorderSide(color: Colors.grey),
                          ) ,
                          errorMaxLines: 2,
                          prefixIcon: Icon(FontAwesomeIcons.userLarge,color:Theme.of(context).primaryColor,),

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
                            ),
                      ),
                      const SizedBox(height: 20,),
                      TextFormField(
                        controller: emailRegisterController,
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
                          enabledBorder:OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide:  const BorderSide(color: Colors.grey),
                          ) ,
                          prefixIcon: Icon(FontAwesomeIcons.envelopeCircleCheck,color: Theme.of(context).primaryColor,),

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
                        ),
                      ),
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
                          enabledBorder:OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide:  const BorderSide(color: Colors.grey),
                          ) ,
                          errorMaxLines: 2,
                          suffixIcon: InkWell(onTap: (){
                            cubit.changePasswordVisibility();
                          },child: Icon(cubit.suffixPassword,color: Theme.of(context).primaryColor,)),
                          prefixIcon:  Icon(FontAwesomeIcons.lock,color:Theme.of(context).primaryColor,),

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
                           ),
                      ),
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
                          enabledBorder:OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide:  const BorderSide(color: Colors.grey),
                          ) ,
                          suffixIcon: InkWell(onTap: (){
                           cubit.changeConfirmPasswordVisibility();
                          },
                              child: Icon(cubit.suffixConfirmPassword,color:Theme.of(context).primaryColor,)),
                          prefixIcon:  Icon(FontAwesomeIcons.unlock,color: Theme.of(context).primaryColor,),

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
                            ),
                      ),
                      const SizedBox(height: 20,),
                      Text(
                        byClick.tr,
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          InkWell(
                            onTap: (){
                              cubit.launchURLBrowserSignUp("https://github.com/MahdiAbabneh/note-privacy/blob/main/prvacy-policy.md");
                            },
                            child: Text(
                              dataPolicy.tr,style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                            ),
                          ),
                          SizedBox(
                            width: 2,
                          ),
                          InkWell(
                            onTap: (){
                              cubit.launchURLBrowserSignUp("https://github.com/MahdiAbabneh/Terms-of-Use/blob/main/Note%20app%20Terms%20of%20Use");
                            },
                            child:  Text(
                              terms.tr,style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40,),
                      SizedBox(width: double.infinity,child: SizedBox(
                        height: 50,
                        child:ConditionalBuilder(
                          fallback: (context) =>
                          const Center(child: AdaptiveIndicator()),
                          condition: state is! UserRegisterLoading,
                          builder:(context) =>   ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor,
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(15.0),
                                    )),

                              ),onPressed: (){

                            if (JosKeys.formKeyRegister.currentState!.validate()) {
                              cubit.registerForUser(emailRegisterController.text, passwordController.text);
                            }
                          },
                              child:
                              Text(createAccount.tr,style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize:  responsive(context, 14.0, 18.0)),)),
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
