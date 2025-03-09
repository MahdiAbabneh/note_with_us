import 'package:flutter/cupertino.dart';
String ?idForUser;
int ? tokenForUser;
String? selectedGenderRegisterValue;
String? selectedGenderLoginValue;
String? selectedTypeNoteValue;
int? indexUser ;
int? indexRinging ;


String? usernameData;
String? dateOfBirthData;
String? genderData;
String? phoneNumberData;
String? addressData;
String? profileImage;
String? themeData;
bool? darkMoodData;
List<String> albumImages=[];
// List<StoryItemModel> storiesImages=[];
// List<StoryItemModel> storiesUserImages=[];
List<String> albumUserImages=[];


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

//profile
TextEditingController userNameProfileController = TextEditingController(text: usernameData);
TextEditingController userPhoneProfileController = TextEditingController(text:phoneNumberData );
TextEditingController userAddressProfileController = TextEditingController(text:addressData );

//post
TextEditingController textPostController = TextEditingController();



class JosKeys {
  static final formKeyRegister = GlobalKey<FormState>();
  static final formKeyLogin = GlobalKey<FormState>();
  static final formKeyUserNameProfile = GlobalKey<FormState>();
  static final formKeyPhoneNumberProfile = GlobalKey<FormState>();
  static final formKeyCreateNote = GlobalKey<FormState>();
}


