import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:jiffy/jiffy.dart';
import 'package:mahdeko/Compouents/constant_empty.dart';
import 'package:mahdeko/models/user_data_model.dart';
import 'package:mahdeko/modules/Register/cubit/states.dart';
import 'package:mahdeko/network/cache_helper.dart';

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
          email: emailRegisterController.text,
          username: userNameController.text,
          image: '',
          token: userValue!,
          dateOfBirth: dateOfBirthRegisterController.text,
          phoneNumber: '',
          gender:  selectedGenderRegisterValue=="ذكر"?"Male":selectedGenderRegisterValue=="أنثى"?"":"Female",
          location: '',
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


  selectDateRegister(context) async {
    final DateTime? newDateTime = await showRoundedDatePicker(
        textPositiveButton:CacheHelper.getData(key:"lang")=="ar"?"موافق": "OK",
        textNegativeButton:CacheHelper.getData(key:"lang")=="ar"?"الخروج":"CANCEL",
      fontFamily: CacheHelper.getData(key:"lang")=="ar"?"Almarai":"mali",
      imageHeader:NetworkImage("https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRdATqA4BZF69cbrTVtiI48SLILp5mRi6fohHbnI3UnaVtxqeEcH4T0n2JaZxa9UHHdpp0&usqp=CAU") ,
      theme: ThemeData(
          primaryColor: Theme
              .of(context)
              .primaryColor,
          primarySwatch:Colors.brown),
      height: 330,
      context: context,
      initialDate:DateTime(DateTime.now().year - 18),
      firstDate:  DateTime(DateTime.now().year - 60),
      lastDate: DateTime(DateTime.now().year -18),
      borderRadius: 16,
    );
    if (newDateTime != null) {
      dateOfBirthRegisterController.text =Jiffy(newDateTime).format("yMd").toString();
    }
  }

}
