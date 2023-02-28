import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
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
import 'package:mahdeko/Locale/locale_controller.dart';
import 'package:mahdeko/modules/Login/login_google_screen.dart';
import 'package:mahdeko/network/cache_helper.dart';
import 'package:toggle_switch/toggle_switch.dart';
import '../Register/register_screen.dart';
import 'cubit/cubit.dart';
import 'cubit/states.dart';




class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    var cubit = LoginCubit.get(context);
    MyLocaleController controllerLang= Get.find();
    return BlocConsumer<LoginCubit, LoginStates>(
      listener: (context, state) {
        if(state is UserLoginSuccess)
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
        if(state is UserLoginError)
          {
            showToastFailed(toast1.tr,context);
          }
        if(state is UserLoginGoogleSuccess)
        {
              CacheHelper.sharedPreferences?.setString("id", FirebaseAuth.instance.currentUser!.uid.toString())
              .whenComplete(() => {
            idForUser = CacheHelper.getData(key:'id'),
          })
              .whenComplete(() => {
            navigatePushReplacement(context, const LoginGoogleScreen())
          });
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(toolbarHeight: 1,),
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(children: [
                ToggleSwitch(
                  minWidth: 90.0,
                  initialLabelIndex: 0,
                  cornerRadius: 20.0,
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
                const SizedBox(height: 20,),
                Container(
                  height: responsive(context, 220.0, 400.0),
                  color: Colors.white,
                  width: double.infinity,
                  child: Image.asset("assets/images/NWU.png",),
                ),
                const SizedBox(height: 50,),
                Column(
                  children: [
                    TextFormField(
                      cursorColor: Theme.of(context).primaryColor,
                      controller: emailLoginController,
                      keyboardType:
                      TextInputType.emailAddress,
                      textInputAction:
                      TextInputAction.newline,
                      decoration: InputDecoration(
                        prefixIcon:  Icon(FontAwesomeIcons.envelopeCircleCheck, color:Theme.of(context).primaryColor,),
                        labelStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: responsive(context, 14.0, 18.0)),
                        contentPadding: const EdgeInsets.only(right: 10),
                        labelText: email.tr,
                        enabledBorder:OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide:  const BorderSide(color: Colors.grey),
                        ) ,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide:  BorderSide(color:  Theme.of(context).primaryColor,),),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide:  BorderSide(color:Theme.of(context).primaryColor,),
                        ),
                      ),
                      style: const TextStyle(
                          fontSize: 20.0,
                      ),
                    ),

                    const SizedBox(height: 20,),
                    TextFormField(
                      controller: passController,
                      cursorColor:Theme.of(context).primaryColor,
                      keyboardType:
                      TextInputType.visiblePassword,
                      obscureText: cubit.isPassword,
                      textInputAction:
                      TextInputAction.newline,
                      decoration: InputDecoration(
                        suffixIcon: InkWell(
                            onTap: () {
                             cubit.changePasswordVisibility();
                            },
                            child: Icon(cubit.suffixPassword, color: Theme.of(context).primaryColor,)),
                        prefixIcon:  Icon(FontAwesomeIcons.unlock, color: Theme.of(context).primaryColor,),

                        labelStyle:  TextStyle(
                            color: Colors.grey,
                            fontSize:  responsive(context, 14.0, 18.0)),
                        contentPadding: const EdgeInsets.only(right: 10),
                        labelText: password.tr,
                        enabledBorder:OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide:  const BorderSide(color: Colors.grey),
                        ) ,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide:  BorderSide(color: Theme.of(context).primaryColor,),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          borderSide:  BorderSide(color: Theme.of(context).primaryColor,),
                        ),
                      ),
                      style: const TextStyle(
                          fontSize: 20.0,
                      ),
                    ), //
                    const SizedBox(height: 20,),

                    SizedBox(width: double.infinity, child: SizedBox(
                      height: 50,
                      child:ConditionalBuilder(
                        fallback: (context) =>
                            const Center(child: AdaptiveIndicator()),
                        condition:state is! UserLoginLoading,
                        builder:(context) => ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(15.0),
                                  )),
                            ), onPressed: () {
                            cubit.loginForUser(context, emailLoginController.text, passController.text);


                        }, child:Text(loginText.tr, style:  TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold, fontSize:  responsive(context, 14.0, 18.0)),)),
                      ),

                    )),
                    const SizedBox(height: 10,),
                    Stack(alignment: Alignment.center,children:[
                      const Divider(thickness: 1),
                        CircleAvatar(
                          radius: responsive(context, 17.0, 34.0),
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            or.tr,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: responsive(context, 12.0, 24.0)),
                          ),
                        )
                      ] ),
                    const SizedBox(height: 15,),
                      CircularProfileAvatar(
                        "",
                        radius: responsive(context, 20.0, 40.0),
                        backgroundColor: Colors.transparent,
                        borderWidth: 1,
                        borderColor: Theme.of(context).primaryColor,
                        elevation: 3.0,
                        foregroundColor: Theme.of(context).primaryColor,
                        cacheImage: true,
                        onTap: () async{
                          cubit.userLoginGoogle=await cubit.signInWithGoogle();
                        },
                        showInitialTextAbovePicture: true,
                        child: Image.asset(
                          "assets/images/google.png",
                          height: responsive(context, 20.0, 40.0),
                        ),
                      ),

                      Padding(
                      padding: EdgeInsets.only(top: MediaQuery
                          .of(context)
                          .padding
                          .top),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            noHave.tr, style:  TextStyle(color: Theme.of(context).primaryColor, fontSize:  responsive(context, 14.0, 18.0)),),
                          InkWell(onTap: (){
                             navigateTo(context, const RegisterScreen());
                          },
                            child: Text(
                              noHave2.tr, style:  TextStyle(
                                fontWeight: FontWeight.bold, fontSize:  responsive(context, 14.0, 18.0),color: Theme.of(context).primaryColor,)),
                          ),

                        ],
                      ),
                    ),

                  ],
                )
              ],),
            ),
          ),
        );


      },
    );
  }

}
