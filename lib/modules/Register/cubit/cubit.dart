import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mahdeko/Compouents/constant_empty.dart';
import 'package:mahdeko/models/user_data_model.dart';
import 'package:mahdeko/modules/Register/cubit/states.dart';

import '../register_screen.dart';



class RegisterCubit extends Cubit<RegisterStates> {
  RegisterCubit() : super(RegisterInitialState());

  static RegisterCubit get(context) => BlocProvider.of(context);

  Future<void> registerForUser(String email, String password) async {
    emit(UserRegisterLoading());
    await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password)
        .then((value) {
      FirebaseMessaging.instance.getToken().then((userValue) {
        UserDataModel model = UserDataModel(
          uId: value.user!.uid,
          email: emailController.text,
          username: userNameController.text,
          image: '',
          token: userValue!,
          dateOfBirth: '',
          phoneNumber: '',
          gender: selectedGenderValue,
        );
        FirebaseFirestore.instance
            .collection('users')
            .doc(value.user!.uid)
            .set(model.toJson());
        emit(UserRegisterSuccess());
      }).catchError((error) {
        emit(UserRegisterError());


      });
    });
  }

  IconData suffixPassword = Icons.visibility_off_outlined;
  bool isPassword = true;

  void changePasswordVisibility() {
    isPassword = !isPassword;
    suffixPassword =
    !isPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined;
    emit(SocialChangePasswordVisibilityRegister());
  }

  IconData suffixConfirmPassword = Icons.visibility_off_outlined;
  bool isConfirmPassword = true;

  void changeConfirmPasswordVisibility() {
    isConfirmPassword = !isConfirmPassword;
    suffixConfirmPassword =
    !isConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined;
    emit(SocialChangeConfirmPasswordVisibility());
  }


}
