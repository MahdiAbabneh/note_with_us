import 'package:flutter/cupertino.dart';

String ?idForUser;
int ? tokenForUser;
String? selectedGenderRegisterValue;
String? selectedGenderLoginValue;


//Register
TextEditingController userNameController = TextEditingController();
TextEditingController dateOfBirthRegisterController = TextEditingController();
TextEditingController emailRegisterController = TextEditingController();
TextEditingController passwordController = TextEditingController();
TextEditingController confirmPasswordController = TextEditingController();

//Login
TextEditingController userNameLoginController = TextEditingController();
TextEditingController dateOfBirthLoginController = TextEditingController();
TextEditingController emailLoginController = TextEditingController();
TextEditingController passController = TextEditingController();

class JosKeys {
  static final formKeyRegister = GlobalKey<FormState>();
  static final formKeyLogin = GlobalKey<FormState>();

}


