import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
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

  UserCredential? userLoginGoogle;
  UserDataModel? user;
  Future<UserCredential> signInWithGoogle() async {
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
}

  void signInWithGoogleSuccess() async{
    emit(UserLoginLoading());
    FirebaseMessaging.instance.getToken().then((userValue) {
          UserDataModel model = UserDataModel(
            uId: userLoginGoogle?.user!.uid,
            email: userLoginGoogle?.user!.email,
            username:userNameLoginController.text,
            image: '',
            token: userValue!,
            dateOfBirth: dateOfBirthLoginController.text,
            phoneNumber: '',
            gender: selectedGenderLoginValue=="ذكر"?"Male":selectedGenderLoginValue=="أنثى"?"":"Female",
            location: ''
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
      dateOfBirthLoginController.text =Jiffy(newDateTime).format("yMd").toString();
    }
  }


}
