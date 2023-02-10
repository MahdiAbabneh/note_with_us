import 'dart:core';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jiffy/jiffy.dart';
import 'package:mahdeko/Compouents/constant_empty.dart';
import 'package:mahdeko/Layout/Home/cubit/states.dart';
import 'package:mahdeko/models/user_data_model.dart';
import 'package:age_calculator/age_calculator.dart';

class HomeCubit extends Cubit<HomeStates> {
  HomeCubit() : super(HomeInitialState());

  static HomeCubit get(context) => BlocProvider.of(context);

  UserDataModel? user;
  DateDuration? durationAge;

  Future<void> getUserData() async{
    emit(UserDataLoading());
   await FirebaseFirestore.instance
        .collection('users')
        .doc(idForUser).get().then((value) {
        user = UserDataModel.fromJson(value.data()!);
        usernameData=user!.username;
        dateOfBirthData=user!.dateOfBirth;
        genderData=user!.gender;
        phoneNumberData=user!.phoneNumber;
        addressData=user!.location;
        emit(UserDataSuccess());
    }).catchError((error) {
     emit(UserDataError());
   });
    ageCalculator();
  }
  void ageCalculator(){
    var re = RegExp(
      r'^'
      r'(?<day>[0-9]{1,2})'
      r'/'
      r'(?<month>[0-9]{1,2})'
      r'/'
      r'(?<year>[0-9]{4,})'
      r'$',
    );

    var match = re.firstMatch(dateOfBirthData!);
    if (match == null) {
      throw const FormatException('Unrecognized date format');
    }

    var dateTimeFormat = DateTime(
      int.parse(match.namedGroup('year')!),
      int.parse(match.namedGroup('month')!),
      int.parse(match.namedGroup('day')!),
    );
    durationAge = AgeCalculator.age(dateTimeFormat);
  }

  Future<void> updateUserData(updateData,controller) async{
    emit(UserUpdateDataLoading());
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid).update({"$updateData":controller}).then((value) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid).get().then((value) {
        UserDataModel? user;
        user = UserDataModel.fromJson(value.data()!);
        usernameData=user.username;
        phoneNumberData=user.phoneNumber;
        addressData=user.location;
        emit(UserUpdateDataSuccess());
      });
    });
  }




}

