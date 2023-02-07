import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mahdeko/Compouents/constant_empty.dart';
import 'package:mahdeko/models/user_data_model.dart';
import 'package:mahdeko/modules/Login/cubit/states.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mahdeko/network/cache_helper.dart';




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

  Future<UserCredential> signInWithGoogle() async {
    emit(UserLoginLoading());
    final GoogleSignInAccount? googleUser = await GoogleSignIn(scopes: ['profile', 'email']).signIn();
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    return await FirebaseAuth.instance.signInWithCredential(credential);
}

  void signInWithGoogleSuccess() async{
    UserCredential userLoginGoogle=await signInWithGoogle();
    if(userLoginGoogle.credential!.accessToken!=null)
      {
        FirebaseMessaging.instance.getToken().then((userValue) {
          UserDataModel model = UserDataModel(
            uId: userLoginGoogle.user!.uid,
            email: userLoginGoogle.user!.email,
            username:  userLoginGoogle.additionalUserInfo!.username??"",
            image: '',
            token: userValue!,
            dateOfBirth: '',
            phoneNumber: '',
            gender: '',
          );
          FirebaseFirestore.instance
              .collection('users')
              .doc(userLoginGoogle.user!.uid,)
              .set(model.toJson());
          emit(UserLoginSuccess());
        }).catchError((error) {
          emit(UserLoginSuccess());


        });

      }
    else
      {
        emit(UserLoginError());
      }
  }

}
