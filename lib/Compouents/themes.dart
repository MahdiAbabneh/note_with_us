import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';

ThemeData darkBlueTheme =  ThemeData(
  fontFamily: appFont,
  primaryColor: Colors.blueAccent,
  appBarTheme: AppBarTheme(
    titleSpacing: 20.0,
    // ignore: deprecated_member_use
    backwardsCompatibility: false,
    systemOverlayStyle: SystemUiOverlayStyle(
      // statusBarColor: HexColor('333739'),
      statusBarIconBrightness: Brightness.light,
    ),
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
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.blueAccent,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    type: BottomNavigationBarType.fixed,
    selectedItemColor: Colors.blueAccent,
    unselectedItemColor: Colors.grey,
    elevation: 20.0,
    // backgroundColor: Colors.black('333739'),
  ),
  textTheme: TextTheme(
    bodyText1: TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),
);

//-----------------------------------------

ThemeData pinkTheme=
    ThemeData(
      fontFamily: appFont,
      primarySwatch: Colors.pink,
      appBarTheme: AppBarTheme(
        titleSpacing: 20.0,
        // ignore: deprecated_member_use
        backwardsCompatibility: false,
        systemOverlayStyle: SystemUiOverlayStyle(
         // statusBarColor: HexColor('333739'),
          statusBarIconBrightness: Brightness.light,
        ),
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
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.pink,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        elevation: 20.0,
       // backgroundColor: Colors.black('333739'),
      ),
      textTheme: TextTheme(
        bodyText1: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );

//-----------------------------------------

ThemeData lightBlueTheme=
ThemeData(
  fontFamily: appFont,
  primaryColor: Colors.lightBlueAccent,
  appBarTheme: AppBarTheme(
    titleSpacing: 20.0,
    // ignore: deprecated_member_use
    backwardsCompatibility: false,
    systemOverlayStyle: SystemUiOverlayStyle(
      // statusBarColor: HexColor('333739'),
      statusBarIconBrightness: Brightness.light,
    ),
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
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.lightBlueAccent,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    type: BottomNavigationBarType.fixed,
    selectedItemColor: Colors.lightBlueAccent,
    unselectedItemColor: Colors.grey,
    elevation: 20.0,
    // backgroundColor: Colors.black('333739'),
  ),
  textTheme: TextTheme(
    bodyText1: TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),
);

//-----------------------------------------

ThemeData orangeTheme=
ThemeData(
  fontFamily: appFont,
  primarySwatch: Colors.deepOrange,
  appBarTheme: AppBarTheme(
    titleSpacing: 20.0,
    // ignore: deprecated_member_use
    backwardsCompatibility: false,
    systemOverlayStyle: SystemUiOverlayStyle(
      // statusBarColor: HexColor('333739'),
      statusBarIconBrightness: Brightness.light,
    ),
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
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.deepOrange,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    type: BottomNavigationBarType.fixed,
    selectedItemColor: Colors.deepOrange,
    unselectedItemColor: Colors.grey,
    elevation: 20.0,
    // backgroundColor: Colors.black('333739'),
  ),
  textTheme: TextTheme(
    bodyText1: TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),
);

//-----------------------------------------

ThemeData greenTheme=
ThemeData(
  fontFamily: appFont,
  primarySwatch: Colors.green,
  appBarTheme: AppBarTheme(
    titleSpacing: 20.0,
    // ignore: deprecated_member_use
    backwardsCompatibility: false,
    systemOverlayStyle: SystemUiOverlayStyle(
      // statusBarColor: HexColor('333739'),
      statusBarIconBrightness: Brightness.light,
    ),
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
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.green,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    type: BottomNavigationBarType.fixed,
    selectedItemColor: Colors.green,
    unselectedItemColor: Colors.grey,
    elevation: 20.0,
  ),
  textTheme: TextTheme(
    bodyText1: TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),
);

//-----------------------------------------

ThemeData defaultTheme = ThemeData(
  primaryColor: darkBlueColor,
  fontFamily: appFont,
  appBarTheme: AppBarTheme(
    color:darkBlueColor ,
    titleSpacing: 20.0,
    // ignore: deprecated_member_use
    backwardsCompatibility: false,
    systemOverlayStyle: SystemUiOverlayStyle(
      // statusBarColor: HexColor('333739'),
      statusBarIconBrightness: Brightness.light,
    ),
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
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: darkBlueColor,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    type: BottomNavigationBarType.fixed,
    selectedItemColor: darkBlueColor,
    unselectedItemColor: Colors.grey,
    elevation: 20.0,
    // backgroundColor: Colors.black('333739'),
  ),
  textTheme: TextTheme(
    bodyText1: TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),
);

