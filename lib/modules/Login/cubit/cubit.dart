import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mahdeko/modules/Login/cubit/states.dart';
import 'package:google_sign_in/google_sign_in.dart';




class LoginCubit extends Cubit<LoginStates> {
  LoginCubit() : super(LoginInitialState());

  static LoginCubit get(context) => BlocProvider.of(context);

  void loginForUser(context,String email, String password) {
    emit(UserLoginLoading());
    FirebaseAuth.instance
        .signInWithEmailAndPassword(
        email: email,
        password: password)
        .then((value) {
          print(value.user);
      emit(UserLoginSuccess());

    }).catchError((error) {
      emit(UserLoginError());

     // showToastFailed("فشل في عملية تسجيل الدخول الرجاء التأكد من البيانات المدخلة");
    });
  }

  IconData suffixPassword = Icons.visibility_off_outlined;
  bool isPassword = true;

  void changePasswordVisibility() {
    isPassword = !isPassword;
    suffixPassword =
    !isPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined;
    emit(SocialChangePasswordVisibility());
  }




}
