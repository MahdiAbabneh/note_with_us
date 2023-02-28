import 'package:alarm/alarm.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:mahdeko/Locale/locale_controller.dart';
import 'Compouents/constant_empty.dart';
import 'Layout/Home/cubit/cubit.dart';
import 'Layout/Home/home_layout.dart';
import 'Locale/locale.dart';
import 'bloc_observer.dart';
import 'modules/Login/cubit/cubit.dart';
import 'modules/Login/cubit/states.dart';
import 'modules/Login/login_screen.dart';
import 'modules/Register/cubit/cubit.dart';
import 'network/cache_helper.dart';
import 'package:get/instance_manager.dart';
import 'package:get/route_manager.dart';

BuildContext context= context;
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Alarm.init();
  await CacheHelper.init();
  Bloc.observer = AppBlocObserver();
  Widget? widget;
  idForUser = CacheHelper.getData(key:'id');
  darkMoodData=CacheHelper.getData(key:'darkMood')??false;
  themeData=CacheHelper.getData(key: 'theme')??'origin';

  if (idForUser != null){
    widget =  const HomeLayout();}
 else{
    widget = const LoginScreen();
  }

  runApp(Phoenix(child: MyApp(startWidget: widget)));
}

class MyApp extends StatelessWidget {
  final Widget? startWidget;
  const MyApp({super.key,
    this.startWidget,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (BuildContext context) => LoginCubit()),
        BlocProvider(create: (BuildContext context) => RegisterCubit()),
        BlocProvider(create: (BuildContext context) => HomeCubit()..getUserData()..getPosts()),
      ],
      child: BlocConsumer<LoginCubit,LoginStates>(
        listener: (context, state) {},
        builder: (context, state) {
          MyLocaleController controllerLang= Get.put(MyLocaleController());
          return GetMaterialApp(
            theme: FlexThemeData.light(
              scheme: themeData == 'origin'
                  ? FlexScheme.mango
                  : themeData == 'blue'
                      ? FlexScheme.ebonyClay
                      : themeData == 'pink'
                          ? FlexScheme.sakura
                          : FlexScheme.mango,
              fontFamily:
                  CacheHelper.getData(key: "lang") == "ar" ? "Almarai" : "mali",
            ),
            darkTheme: FlexThemeData.dark(
              scheme: FlexScheme.mango,
              fontFamily: CacheHelper.getData(key: "lang") == "ar" ? "Almarai" : "mali",
            ),
            themeMode: darkMoodData! ? ThemeMode.dark : ThemeMode.light,
            title: "Note with us",
            debugShowCheckedModeBanner: false,
            locale: controllerLang.initialLang,
            translations:MyLocale(),
            home:startWidget,
          );
        },
      ),
    );
  }
}
