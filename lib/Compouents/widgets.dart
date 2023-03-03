import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mahdeko/network/cache_helper.dart';
import 'package:story_viewer/customizer.dart';
import 'package:story_viewer/models/story_item.dart';
import 'package:story_viewer/models/user.dart';
import 'package:story_viewer/viewer.dart';
import 'package:story_viewer/viewer_controller.dart';

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

SnackBar? showToastSuccess(msg,context)
{
  final snackBar = SnackBar(
    dismissDirection: DismissDirection.up,
    duration: const Duration(seconds: 3),
    content: Text(
      msg,
      style: TextStyle(fontFamily: CacheHelper.getData(key: "lang") == "ar" ? "Almarai" : "mali",
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: responsive(context, 16.0, 24.0)),
    ),
    backgroundColor: Theme.of(context).primaryColor,
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
  return null;
}

SnackBar? showToastFailed(msg,context) {
  final snackBar = SnackBar(
    dismissDirection: DismissDirection.up,
    duration: const Duration(seconds: 3),
    content: Text(
      msg,
      style: TextStyle(fontFamily: CacheHelper.getData(key: "lang") == "ar" ? "Almarai" : "mali",
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: responsive(context, 16.0, 24.0)),
    ),
    backgroundColor: Colors.red,
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
  return null;
}

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