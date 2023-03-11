import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';
import 'package:mahdeko/Compouents/constant_empty.dart';
import 'package:mahdeko/models/user_data_model.dart';
import 'package:mahdeko/modules/Register/cubit/states.dart';
import 'package:mahdeko/network/cache_helper.dart';
import 'package:url_launcher/url_launcher.dart';




class RegisterCubit extends Cubit<RegisterStates> {
  RegisterCubit() : super(RegisterInitialState());

  static RegisterCubit get(context) => BlocProvider.of(context);

  Future<void> registerForUser(String email, String password) async {
    emit(UserRegisterLoading());
    try{
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password)
          .then((value) {
        FirebaseMessaging.instance.getToken().then((userValue) {
          UserDataModel model = UserDataModel(
            uId: value.user!.uid,
            email: emailRegisterController.text,
            username: userNameController.text,
            image: selectedGenderRegisterValue=="ذكر"?'https://cdn-icons-png.flaticon.com/512/146/146007.png?w=740&t=st=1675798040~exp=1675798640~hmac=2f09fbe38c3577a6e7d6a9b4dbdf09c4e7412c4a56717a1aa8e96e51e1ecd467'
                :selectedGenderRegisterValue=="Male"?'https://cdn-icons-png.flaticon.com/512/146/146007.png?w=740&t=st=1675798040~exp=1675798640~hmac=2f09fbe38c3577a6e7d6a9b4dbdf09c4e7412c4a56717a1aa8e96e51e1ecd467'
                :selectedGenderRegisterValue=="أنثى"?'https://cdn-icons-png.flaticon.com/512/146/146005.png?w=740&t=st=1676069504~exp=1676070104~hmac=72e19bd69ea7b7beef7ed4a5a710bd820a1378dfd1876925c69ce16f96110d6e'
                :selectedGenderRegisterValue=="Female"?'https://cdn-icons-png.flaticon.com/512/146/146005.png?w=740&t=st=1676069504~exp=1676070104~hmac=72e19bd69ea7b7beef7ed4a5a710bd820a1378dfd1876925c69ce16f96110d6e':"",
            token: userValue!,
            dateOfBirth: dateOfBirthRegisterController.text,
            phoneNumber: '',
            gender:selectedGenderRegisterValue=="ذكر"?"Male":selectedGenderRegisterValue=="أنثى"?"Female":selectedGenderRegisterValue,
            location: '',
            theme: 'origin',
            darkMood: false,

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
    catch(e){
      emit(UserRegisterError());
    }

  }

  IconData suffixPassword =FontAwesomeIcons.eyeSlash;
  bool isPassword = true;

  void changePasswordVisibility() {
    isPassword = !isPassword;
    suffixPassword =
    !isPassword ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash;
    emit(SocialChangePasswordVisibilityRegister());
  }

  IconData suffixConfirmPassword = FontAwesomeIcons.eyeSlash;
  bool isConfirmPassword = true;

  void changeConfirmPasswordVisibility() {
    isConfirmPassword = !isConfirmPassword;
    suffixConfirmPassword =
    !isConfirmPassword ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash;
    emit(SocialChangeConfirmPasswordVisibility());
  }


  selectDateRegister(context) async {
    final DateTime? newDateTime = await showRoundedDatePicker(
        textPositiveButton:CacheHelper.getData(key:"lang")=="ar"?"موافق": "OK",
        textNegativeButton:CacheHelper.getData(key:"lang")=="ar"?"الخروج":"CANCEL",
      fontFamily: CacheHelper.getData(key:"lang")=="ar"?"Almarai":"mali",
      imageHeader: const CachedNetworkImageProvider(
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRdATqA4BZF69cbrTVtiI48SLILp5mRi6fohHbnI3UnaVtxqeEcH4T0n2JaZxa9UHHdpp0&usqp=CAU",
           ),
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

  Future<void> launchURLBrowserSignUp(url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

}
