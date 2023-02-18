
import 'package:flutter/material.dart';

class PostDataModel {
  PostDataModel({
    required this.text,
    required this.time,
    required this.image,
    required this.numOfImages,
    required this.ownerId,
    required this.ownerName,
    required this.ownerImage,
    required this.likes,
    required this.reminder,
  });

  late final String text;
  late final String time;
  late final List<String> image;
  late final int numOfImages;
  late final String ownerId;
  late final String ownerName;
  late final String ownerImage;
  late final List<LikeDataModel> likes;
  late final List<ReminderDataModel> reminder;

  PostDataModel.fromJson(Map<String, dynamic> json) {
    text = json['text'] ?? '';
    time = json['time'] ?? '';
    image = List.from(json['image']).map((e) => e.toString()).toList();
    numOfImages = json['numOfImages'] ?? 3;
    ownerId = json['ownerId'] ?? '';
    ownerName = json['ownerName'] ?? '';
    ownerImage = json['ownerImage'] ?? '';
    likes = List.from(json['likes']).map((e) => LikeDataModel.fromJson(e)).toList();
    reminder = List.from(json['reminder']).map((e) => ReminderDataModel.fromJson(e)).toList();

  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'time': time,
      'image': image.map((element) => element).toList(),
      'numOfImages':numOfImages,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerImage': ownerImage,
      'likes': likes.map((element) => element.toJson()).toList(),
      'reminder': reminder.map((element) => element.toJson()).toList(),
    };
  }
}

class LikeDataModel {
  LikeDataModel({
    required this.ownerId,
    required this.ownerName,
    required this.ownerImage,
  });
  late final String ownerId;
  late final String ownerName;
  late final String ownerImage;

  LikeDataModel.fromJson(Map<String, dynamic> json) {
    ownerId = json['ownerId'] ?? '';
    ownerName = json['ownerName'] ?? '';
    ownerImage = json['ownerImage'] ?? '';
  }

  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerImage': ownerImage,
    };
  }
}

class ReminderDataModel {
  ReminderDataModel({
    required this.selectedTime,
    required this.isRinging,

  });
  late final String? selectedTime;
  late final bool isRinging;




  ReminderDataModel.fromJson(Map<String, dynamic> json) {
    selectedTime = json['selectedTime'] ?? '';
    isRinging = json['isRinging'] ?? '';

  }

  Map<String, dynamic> toJson() {
    return {
      'selectedTime': selectedTime,
      'isRinging': isRinging,
    };
  }
}
