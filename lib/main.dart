import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
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

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await CacheHelper.init();
  Bloc.observer = AppBlocObserver();
  //CacheHelper.sharedPreferences!.clear();


  Widget? widget;
  idForUser = CacheHelper.getData(key:'id');
  if (kDebugMode) {
    print(idForUser);
  }

  if (idForUser != null){
    widget = const HomeLayout();}
 else{
    widget = const LoginScreen();
  }

  runApp(MyApp(startWidget: widget));
}

class MyApp extends StatelessWidget {
  final Widget? startWidget;
  const MyApp({super.key,
    this.startWidget,
  });
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (BuildContext context) => LoginCubit()),
        BlocProvider(create: (BuildContext context) => RegisterCubit()),
        BlocProvider(create: (BuildContext context) => HomeCubit()),
      ],
      child: BlocConsumer<LoginCubit,LoginStates>(
        listener: (context, state) {},
        builder: (context, state) {
          MyLocaleController controllerLang= Get.put(MyLocaleController());
          return GetMaterialApp(
            theme: ThemeData(
                textTheme: GoogleFonts.almaraiTextTheme(Theme.of(context).textTheme),
                primaryColor: const Color(0xFFC27D3C),
                appBarTheme: const AppBarTheme(
                  backgroundColor:Color(0xFFC27D3C),
                  titleSpacing: 20.0,
                  // ignore: deprecated_member_use
                  backwardsCompatibility: false,
                  elevation: 0.0,
                  titleTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                  iconTheme: IconThemeData(
                    color: Colors.white,
                  ),
                ),
                floatingActionButtonTheme: const FloatingActionButtonThemeData(
                  backgroundColor:  Color(0xFFC27D3C),
                ),
                bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor:  Color(0xFFC27D3C),
                  unselectedItemColor: Colors.grey,
                  elevation: 20.0,
                  // backgroundColor: Colors.black('333739'),
                )),
            title: "Note Day",
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
