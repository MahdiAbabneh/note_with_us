import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:story_viewer/customizer.dart';
import 'package:story_viewer/models/story_item.dart';
import 'package:story_viewer/models/user.dart';
import 'package:story_viewer/viewer.dart';
import 'package:story_viewer/viewer_controller.dart';

import 'constant_empty.dart';


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

Widget customStoryViewer(List<StoryItemModel> stories,String name,String image,context) {
  StoryViewerController controller = StoryViewerController();
  return StoryViewer(
    progressColor:Theme.of(context).primaryColor ,
    padding: const EdgeInsets.all(20),
    viewerController: controller,
    hasReply: false,
    customValues: Customizer(
      sendIcon: CupertinoIcons.right_chevron,
      closeIcon: CupertinoIcons.down_arrow,
    ),
    stories:stories,
    userModel: UserModel(
      username: name,
      profilePicture: NetworkImage(
        image,
      ),
    ),
  );
}