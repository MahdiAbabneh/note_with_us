import 'dart:core';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mahdeko/Compouents/constant_empty.dart';
import 'package:mahdeko/Layout/Home/cubit/states.dart';
import 'package:mahdeko/models/post_data.dart';
import 'package:mahdeko/models/user_data_model.dart';
import 'package:age_calculator/age_calculator.dart';

class HomeCubit extends Cubit<HomeStates> {
  HomeCubit() : super(HomeInitialState());

  static HomeCubit get(context) => BlocProvider.of(context);

  UserDataModel? user;
  DateDuration? durationAge;

  Future<void> getUserData() async {
    emit(UserDataLoading());
    await FirebaseFirestore.instance
        .collection('users')
        .doc(idForUser).get().then((value) {
      user = UserDataModel.fromJson(value.data()!);
      usernameData = user!.username;
      dateOfBirthData = user!.dateOfBirth;
      genderData = user!.gender;
      phoneNumberData = user!.phoneNumber;
      addressData = user!.location;
      profileImage = user!.image;
      emit(UserDataSuccess());
    }).catchError((error) {
      emit(UserDataError());
    });
    ageCalculator();
  }

  void ageCalculator() {
    var re = RegExp(
      r'^'
      r'(?<day>[0-9]{1,2})'
      r'/'
      r'(?<month>[0-9]{1,2})'
      r'/'
      r'(?<year>[0-9]{4,})'
      r'$',
    );

    var match = re.firstMatch(dateOfBirthData!);
    if (match == null) {
      throw const FormatException('Unrecognized date format');
    }

    var dateTimeFormat = DateTime(
      int.parse(match.namedGroup('year')!),
      int.parse(match.namedGroup('month')!),
      int.parse(match.namedGroup('day')!),
    );
    durationAge = AgeCalculator.age(dateTimeFormat);
  }

  Future<void> updateUserData(updateData, controller) async {
    emit(UserUpdateDataLoading());
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid).update(
        {"$updateData": controller}).then((value) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid).get().then((value) {
        UserDataModel? user;
        user = UserDataModel.fromJson(value.data()!);
        usernameData = user.username;
        phoneNumberData = user.phoneNumber;
        addressData = user.location;
        profileImage = user.image;
        emit(UserUpdateDataSuccess());
      });
    });
  }

  CroppedFile? croppedProfileImageFile;
  File? profileImageForUser;
  final ImagePicker pickerProfileImageGallery = ImagePicker();
  final ImagePicker pickerProfileImageCamera = ImagePicker();

  Future<void> selectProfileImageFromGallery() async {
    emit(UserSelectProfileImageLoading());
    final selectImage = await pickerProfileImageGallery.pickImage(
        source: ImageSource.gallery);

    if (selectImage != null) {
      profileImageForUser = File(selectImage.path);
      croppedProfileImageFile = await ImageCropper().cropImage(
        sourcePath: profileImageForUser!.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
      );

      if (croppedProfileImageFile != null) {
        profileImageForUser = File(croppedProfileImageFile!.path);
        emit(UserSelectProfileImageSuccess());
      }
    } else {
      emit(UserSelectProfileImageError());
    }
  }

  Future<void> selectProfileImageFromCamera() async {
    emit(UserSelectProfileImageLoading());
    final pickedFile = await pickerProfileImageCamera.pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null) {
      profileImageForUser = File(pickedFile.path);
      croppedProfileImageFile = await ImageCropper().cropImage(
        sourcePath: profileImageForUser!.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
      );

      if (croppedProfileImageFile != null) {
        profileImageForUser = File(croppedProfileImageFile!.path);
        emit(UserSelectProfileImageSuccess());
      }
    } else {
      emit(UserSelectProfileImageError());
    }
  }


  Future<void> uploadUserProfileImage(context) async {
    emit(UserProfileImageUploadLoading());

     await FirebaseStorage.instance
        .ref(
        'uploads/${profileImageForUser!
            .path
            .split('/')
            .last}')
        .putFile(profileImageForUser!)
        .then((file) {
      debugPrint(file.state.name);

      file.ref.getDownloadURL().then((value) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid).update(
            {"image": value}).then((value) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid).get().then((value) {
            UserDataModel? user;
            user = UserDataModel.fromJson(value.data()!);
            profileImage = user.image;
            emit(UserProfileImageUploadSuccess());
          });
        });
        emit(UserProfileImageUploadSuccess());
      }).catchError((error) {
        emit(UserProfileImageUploadError());
      });
    }).catchError((error) {
      emit(UserProfileImageUploadError());
    });
  }

  List<XFile>? imageFileListFromGallery = [];

  final ImagePicker imagePicker = ImagePicker();

  void selectPostImages() async {
    emit(UserSelectImagePostLoading());
    final List<XFile> selectedImages = await imagePicker.pickMultiImage();
    if (selectedImages.isNotEmpty &&
        selectedImages.length + imageFileListFromGallery!.length <=3) {
      imageFileListFromGallery!.addAll(selectedImages);
      emit(UserSelectImagePostSuccess());
    } else {
      emit(UserSelectImagePostError());
    }
  }

  void removePostImage(index) {
    imageFileListFromGallery?.removeAt(index);
    emit(UserRemovePostImage());
  }

  String dateFormat(DateTime dateTime) {
    return '${dateTime.toIso8601String().substring(0, dateTime.toIso8601String().length - 3)}Z';
  }
  String dateAndTimeFormat(String dateToFormat) {
    return ('${DateTime.parse(dateToFormat.toString().replaceAll("Z", "")).year}/${DateTime.parse(dateToFormat.toString().replaceAll("Z", "")).month}/${DateTime.parse(dateToFormat.toString().replaceAll("Z", "")).day},  ${DateTime.parse(dateToFormat.toString().replaceAll("Z", "")).hour}:${DateTime.parse(dateToFormat.toString().replaceAll("Z", "")).minute}')
        .toString();
  }

  List<String> imagesForPost=[];


Future<void> createPost() async {
  emit(UserCreatePostLoading());
  imagesForPost.clear();
  DateTime nowTime = DateTime.now();
  if (imageFileListFromGallery!.isNotEmpty) {

     for(int i=0;i<imageFileListFromGallery!.length;i++)
    {
     await FirebaseStorage.instance
          .ref(
          'uploadsImagePost/${imageFileListFromGallery![i].path.split('/').last}')
          .putFile(File(imageFileListFromGallery![i].path)).then((p0)async {
       await p0.ref.getDownloadURL().then((value) async{
          imagesForPost.add(value);
        });
      });
     print("=============================================================$i====================");
    }
    print(imagesForPost);

    PostDataModel model = PostDataModel(
      image: imagesForPost,
      likes: [],
      ownerId: user!.uId!,
      ownerImage: user!.image!,
      ownerName:  user!.username!,
      text: textPostController.text,
      time: dateFormat(nowTime),
      comments: [],
    );

   await FirebaseFirestore.instance
        .collection('posts')
        .add(model.toJson())
        .then((value) {
     emit(UserCreatePostSuccess());
   }).catchError((error) {
     emit(UserCreatePostError());
   });
  }
  else{
    PostDataModel model = PostDataModel(
      image: [],
      likes: [],
      ownerId: user!.uId!,
      ownerImage: user!.image!,
      ownerName:  user!.username!,
      text: textPostController.text,
      time: dateFormat(nowTime),
      comments: [],
    );

    await FirebaseFirestore.instance
        .collection('posts')
        .add(model.toJson())
        .then((value) {
      emit(UserCreatePostSuccess());
    }).catchError((error) {
      emit(UserCreatePostError());
    });

  }
  getPosts();
}

  List<Map<String,PostDataModel>> postsList = [];

  Future<void> getPosts() async {
   FirebaseFirestore.instance.collection('posts').orderBy("time",descending: true).snapshots().listen((value) {
      postsList = [];
      for (var element in value.docs) {
        postsList.add(
            {element.reference.id: PostDataModel.fromJson(element.data())});
      }
    });
  }
}



