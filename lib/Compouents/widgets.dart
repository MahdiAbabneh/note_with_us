import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';


double responsive(context,mobile,tab){
  return  MediaQuery.of(context).size.height < 430 || MediaQuery.of(context).size.width< 490 ? mobile : tab;
}
void navigateTo(context, widget) => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => widget,
  ),
);
void navigatePushReplacement(context, widget) => Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => widget),
);

Future<bool?> showToastSuccess(msg,context) => Fluttertoast.showToast(
    msg: msg,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.SNACKBAR,
    timeInSecForIosWeb: 3,
    backgroundColor: Theme.of(context).primaryColor,
    textColor: Colors.white,
    fontSize: responsive(context, 16.0, 24.0));

Future<bool?> showToastFailed(msg,context) => Fluttertoast.showToast(
    msg: msg,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.SNACKBAR,
    timeInSecForIosWeb: 3,
    backgroundColor: Colors.red,
    textColor: Colors.white,
    fontSize:responsive(context, 16.0, 24.0));