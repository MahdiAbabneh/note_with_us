import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jiffy/jiffy.dart';
import 'package:mahdeko/Compouents/constant_empty.dart';
import 'package:mahdeko/Compouents/widgets.dart';
import 'package:mahdeko/Layout/Home/home_layout.dart';
import 'package:mahdeko/models/user_data_model.dart';
import 'package:mahdeko/modules/Login/cubit/states.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mahdeko/modules/Register/register_screen.dart';
import 'package:mahdeko/network/cache_helper.dart';




class LoginCubit extends Cubit<LoginStates> {
  LoginCubit() : super(LoginInitialState());

  static LoginCubit get(context) => BlocProvider.of(context);

  Future<void> loginForUser(context,String email, String password)async {
    emit(UserLoginLoading());
    await FirebaseAuth.instance
        .signInWithEmailAndPassword(
        email: email,
        password: password)
        .then((value) {
      emit(UserLoginSuccess());
    }).catchError((error) {
      emit(UserLoginError());
    });
  }

  IconData suffixPassword = FontAwesomeIcons.eyeSlash;
  bool isPassword = true;

  void changePasswordVisibility() {
    isPassword = !isPassword;
    suffixPassword =
    !isPassword ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash;
    emit(SocialChangePasswordVisibility());
  }

  UserCredential? userLoginGoogle;

  Future<UserCredential?> signInWithGoogle() async {
    try{
      emit(UserLoginLoading());
      final GoogleSignInAccount? googleUser = await GoogleSignIn(scopes: ['profile', 'email']).signIn();
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      return await FirebaseAuth.instance.signInWithCredential(credential).whenComplete(() {
        FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid).get().then((value) {
          //user = UserDataModel.fromJson(value.data()!);
          if(value.data()==null)
          {
            emit(UserLoginGoogleSuccess());
          }
          else{
            emit(UserLoginSuccess());
          }
        });
      });
    }catch(e){
      emit(UserLoginError());
    }
    return  null;
}

  Future<void> signInWithGoogleSuccess() async{
    emit(UserLoginLoading());
   await FirebaseMessaging.instance.getToken().then((userValue) {
          UserDataModel model = UserDataModel(
            uId: userLoginGoogle?.user!.uid,
            email: userLoginGoogle?.user!.email,
            username:userNameLoginController.text,
            image:selectedGenderLoginValue=="ذكر"?'https://cdn-icons-png.flaticon.com/512/146/146007.png?w=740&t=st=1675798040~exp=1675798640~hmac=2f09fbe38c3577a6e7d6a9b4dbdf09c4e7412c4a56717a1aa8e96e51e1ecd467'
                :selectedGenderLoginValue=="Male"?'https://cdn-icons-png.flaticon.com/512/146/146007.png?w=740&t=st=1675798040~exp=1675798640~hmac=2f09fbe38c3577a6e7d6a9b4dbdf09c4e7412c4a56717a1aa8e96e51e1ecd467'
                :selectedGenderLoginValue=="أنثى"?'https://cdn-icons-png.flaticon.com/512/146/146005.png?w=740&t=st=1676069504~exp=1676070104~hmac=72e19bd69ea7b7beef7ed4a5a710bd820a1378dfd1876925c69ce16f96110d6e'
                :selectedGenderLoginValue=="Female"?'https://cdn-icons-png.flaticon.com/512/146/146005.png?w=740&t=st=1676069504~exp=1676070104~hmac=72e19bd69ea7b7beef7ed4a5a710bd820a1378dfd1876925c69ce16f96110d6e':"",
            token: userValue!,
            dateOfBirth: dateOfBirthLoginController.text,
            phoneNumber: '',
            gender: selectedGenderLoginValue=="ذكر"?"Male":selectedGenderLoginValue=="أنثى"?"Female":selectedGenderLoginValue,
            location: '',
            theme: 'origin',
            darkMood: false,
          );
          FirebaseFirestore.instance
              .collection('users')
              .doc(userLoginGoogle?.user!.uid,)
              .set(model.toJson());
          emit(UserLoginGoogleInfoSuccess());
        }).catchError((error) {
          emit(UserLoginGoogleInfoError());
        });

  }

  selectDateLogin(context) async {
    final DateTime? newDateTime = await showRoundedDatePicker(
      textPositiveButton:CacheHelper.getData(key:"lang")=="ar"?"موافق": "OK",
      textNegativeButton:CacheHelper.getData(key:"lang")=="ar"?"الخروج":"CANCEL",
      fontFamily: CacheHelper.getData(key:"lang")=="ar"?"Almarai":"mali",
      imageHeader: const CachedNetworkImageProvider(
        "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRdATqA4BZF69cbrTVtiI48SLILp5mRi6fohHbnI3UnaVtxqeEcH4T0n2JaZxa9UHHdpp0&usqp=CAU",
      ),      theme: ThemeData(
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
      dateOfBirthLoginController.text =Jiffy(newDateTime).format("yMd").toString();
    }
  }


}
