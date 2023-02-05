

import 'dart:ui';

import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:get/route_manager.dart';
import 'package:mahdeko/network/cache_helper.dart';

class MyLocaleController extends GetxController{

  Locale initialLang= CacheHelper.getData(key:"lang")== null? Get.deviceLocale! : Locale(CacheHelper.getData(key:"lang")) ;

  void changeLang(String codeLange){
    Locale locale= Locale(codeLange);
    CacheHelper.saveData(key: "lang", value: codeLange);
    Get.updateLocale(locale);
  }

}