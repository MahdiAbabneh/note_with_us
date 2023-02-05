

import 'package:get/route_manager.dart';

class MyLocale implements Translations{

  @override
  Map<String, Map<String, String>> get keys => {

    "ar" :  {
      'Email': "البريد الإلكتروني",
      "Password":"كلمة المرور",
      "User":"مستخدم",
      "Admin":"مسؤول",
      "Confirmation code":"رمز التأكيد",
      "Login Failed Please Verify the Data Entered":"فشل في عملية تسجيل الدخول الرجاء التأكد من البيانات المدخلة",
      "Don't have an account ? ":"ليس لديك حساب ؟ ",
      " Create an account":"إنشاء حساب",
      "Login":"تسجيل الدخول",
      "Create Account":"إنشاء الحساب",
      "Username must contain a minimum of 3 characters and a maximum of 15 characters.":"يجب أن يحتوي اسم المستخدم على 3 أحرف كحد أدنى و 15 حرفًا كحد أقصى",
      "User Name":"اسم المستخدم",
      "email address must not be empty":"يجب ألا يكون عنوان البريد الإلكتروني فارغًا",
      "Password must be a minimum of 6 characters and a maximum of 10 characters":"كلمة المرور يجب أن تتكون من ٦ خانات كحد أدنى و ١٠ خانات كحد أقصى",
      "Password is incorrect":"كلمة المرور غير صحيحة",
      "Confirm Password":"تأكيد كلمة المرور",
      "Account successfully created":"تم إنشاء الحساب بنجاح",
      "OR":"أو",
      "Gender":"جنس",
      "Please select gender":"يرجى تحديد الجنس",
      "Male":"ذكر",
      "Female":"أنثى"
    },

    "en" : {




    }

  };


}