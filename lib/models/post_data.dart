
class PostDataModel {
  PostDataModel({
    required this.text,
    required this.time,
    required this.image,
    required this.ownerId,
    required this.ownerName,
    required this.ownerImage,
    required this.likes,
    required this.comments,
  });

  late final String text;
  late final String time;
  late final List<String> image;
  late final String ownerId;
  late final String ownerName;
  late final String ownerImage;
  late final List<LikeDataModel> likes;
  late final List<CommentDataModel> comments;

  PostDataModel.fromJson(Map<String, dynamic> json) {
    text = json['text'] ?? '';
    time = json['time'] ?? '';
    image = List.from(json['image']).map((e) => e.toString()).toList();
    ownerId = json['ownerId'] ?? '';
    ownerName = json['ownerName'] ?? '';
    ownerImage = json['ownerImage'] ?? '';
    likes = List.from(json['likes']).map((e) => LikeDataModel.fromJson(e)).toList();
    comments = List.from(json['comments']).map((e) => CommentDataModel.fromJson(e)).toList();

  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'time': time,
      'image': image.map((element) => element).toList(),
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerImage': ownerImage,
      'likes': likes.map((element) => element.toJson()).toList(),
      'comments': comments.map((element) => element.toJson()).toList(),
    };
  }
}

class CommentDataModel {
  CommentDataModel({
    required this.text,
    required this.time,
    required this.ownerId,
    required this.ownerName,
    required this.ownerImage,
  });

  late final String text;
  late final String time;
  late final String ownerId;
  late final String ownerName;
  late final String ownerImage;

  CommentDataModel.fromJson(Map<String, dynamic> json) {
    text = json['text'] ?? '';
    time = json['time'] ?? '';
    ownerId = json['ownerId'] ?? '';
    ownerName = json['ownerName'] ?? '';
    ownerImage = json['ownerImage'] ?? '';
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'time': time,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerImage': ownerImage,
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

class OrdersStatusForUsersDataModel {
  OrdersStatusForUsersDataModel({
    required this.ownerId,
    required this.ownerName,
    required this.ownerImage,
    //required this.time,

  });
  late final String ownerId;
  late final String ownerName;
  late final String ownerImage;
  //late final String time;


  OrdersStatusForUsersDataModel.fromJson(Map<String, dynamic> json) {
    ownerId = json['ownerId'] ?? '';
    ownerName = json['ownerName'] ?? '';
    ownerImage = json['ownerImage'] ?? '';
    //time = json['time'] ?? '';

  }

  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerImage': ownerImage
      //'time': time,

    };
  }
}