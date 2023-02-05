
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mahdeko/Compouents/widgets.dart';
import 'package:mahdeko/modules/Login/login_screen.dart';
import 'cubit/cubit.dart';
import 'cubit/states.dart';

class HomeLayout extends StatelessWidget {
  const HomeLayout({super.key});


  @override
  Widget build(BuildContext context) {
    var cubit = HomeCubit.get(context);
    return BlocConsumer<HomeCubit, HomeStates>(
      listener: (context, state) {
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(icon:const Icon(Icons.logout),onPressed: (){
              FirebaseAuth.instance.signOut().whenComplete(() => {
                // CacheHelper.sharedPreferences?.remove("id"),
                // CacheHelper.sharedPreferences?.remove("adminCode"),
                // CacheHelper.sharedPreferences!.clear()
              }).whenComplete(() => {
                navigatePushReplacement(context, const LoginScreen())
              });

            }),
          ),
        );


      },
    );
  }
}
