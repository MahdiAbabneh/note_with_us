class LikePostModel {
  final String? message;
  final Data? data;
  final dynamic status;

  LikePostModel({
    this.message,
    this.data,
    this.status,
  });

  LikePostModel.fromJson(Map<String, dynamic> json)
      : message = json['message'] as String?,
        data = (json['data'] as Map<String,dynamic>?) != null ? Data.fromJson(json['data'] as Map<String,dynamic>) : null,
        status = json['status'];

  Map<String, dynamic> toJson() => {
    'message' : message,
    'data' : data?.toJson(),
    'status' : status
  };
}

class Data {
  final int? postId;
  final int? numOfpages;
  final String? firstName;
  final String? lastName;
  final String? localPath;
  final String? type;
  final String? text;
  final String? date;
  final String? updateDate;
  final User? user;
  final String? bgImg;
  final dynamic feeling;
  final dynamic activity;
  final List<dynamic>? postImages;
  final List<PostFamiliesList>? postFamiliesList;
  final List<PostUserList>? postUserList;
  final List<PostUserLikes>? postUserLikes;
  final List<PostUserComments>? postUserComments;
  final List<dynamic>? postTaggedUsers;

  Data({
    this.postId,
    this.numOfpages,
    this.firstName,
    this.lastName,
    this.localPath,
    this.type,
    this.text,
    this.date,
    this.updateDate,
    this.user,
    this.bgImg,
    this.feeling,
    this.activity,
    this.postImages,
    this.postFamiliesList,
    this.postUserList,
    this.postUserLikes,
    this.postUserComments,
    this.postTaggedUsers,
  });

  Data.fromJson(Map<String, dynamic> json)
      : postId = json['postId'] as int?,
        numOfpages = json['numOfpages'] as int?,
        firstName = json['firstName'] as String?,
        lastName = json['lastName'] as String?,
        localPath = json['localPath'] as String?,
        type = json['type'] as String?,
        text = json['text'] as String?,
        date = json['date'] as String?,
        updateDate = json['updateDate'] as String?,
        user = (json['user'] as Map<String,dynamic>?) != null ? User.fromJson(json['user'] as Map<String,dynamic>) : null,
        bgImg = json['bgImg'] as String?,
        feeling = json['feeling'],
        activity = json['activity'],
        postImages = json['postImages'] as List?,
        postFamiliesList = (json['postFamiliesList'] as List?)?.map((dynamic e) => PostFamiliesList.fromJson(e as Map<String,dynamic>)).toList(),
        postUserList = (json['postUserList'] as List?)?.map((dynamic e) => PostUserList.fromJson(e as Map<String,dynamic>)).toList(),
        postUserLikes = (json['postUserLikes'] as List?)?.map((dynamic e) => PostUserLikes.fromJson(e as Map<String,dynamic>)).toList(),
        postUserComments = (json['postUserComments'] as List?)?.map((dynamic e) => PostUserComments.fromJson(e as Map<String,dynamic>)).toList(),
        postTaggedUsers = json['postTaggedUsers'] as List?;

  Map<String, dynamic> toJson() => {
    'postId' : postId,
    'numOfpages' : numOfpages,
    'firstName' : firstName,
    'lastName' : lastName,
    'localPath' : localPath,
    'type' : type,
    'text' : text,
    'date' : date,
    'updateDate' : updateDate,
    'user' : user?.toJson(),
    'bgImg' : bgImg,
    'feeling' : feeling,
    'activity' : activity,
    'postImages' : postImages,
    'postFamiliesList' : postFamiliesList?.map((e) => e.toJson()).toList(),
    'postUserList' : postUserList?.map((e) => e.toJson()).toList(),
    'postUserLikes' : postUserLikes?.map((e) => e.toJson()).toList(),
    'postUserComments' : postUserComments?.map((e) => e.toJson()).toList(),
    'postTaggedUsers' : postTaggedUsers
  };
}

class User {
  final int? id;
  final String? username;
  final String? email;
  final bool? enabled;
  final dynamic createdAt;
  final String? firstName;
  final String? lastName;
  final String? dob;
  final String? gender;
  final String? phone;
  final dynamic families;
  final String? profilePicture;
  final String? coverPhoto;
  final dynamic namePrefix;
  final dynamic aboutMe;
  final dynamic language;
  final dynamic religiousViews;
  final dynamic relationshipStatus;
  final dynamic loyalityToken;
  final int? loyalityPoint;
  final dynamic country;
  final bool? enableTwoFactorAuth;
  final dynamic customGender;

  User({
    this.id,
    this.username,
    this.email,
    this.enabled,
    this.createdAt,
    this.firstName,
    this.lastName,
    this.dob,
    this.gender,
    this.phone,
    this.families,
    this.profilePicture,
    this.coverPhoto,
    this.namePrefix,
    this.aboutMe,
    this.language,
    this.religiousViews,
    this.relationshipStatus,
    this.loyalityToken,
    this.loyalityPoint,
    this.country,
    this.enableTwoFactorAuth,
    this.customGender,
  });

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        username = json['username'] as String?,
        email = json['email'] as String?,
        enabled = json['enabled'] as bool?,
        createdAt = json['createdAt'],
        firstName = json['firstName'] as String?,
        lastName = json['lastName'] as String?,
        dob = json['dob'] as String?,
        gender = json['gender'] as String?,
        phone = json['phone'] as String?,
        families = json['families'],
        profilePicture = json['profilePicture'] as String?,
        coverPhoto = json['coverPhoto'] as String?,
        namePrefix = json['namePrefix'],
        aboutMe = json['aboutMe'],
        language = json['language'],
        religiousViews = json['religiousViews'],
        relationshipStatus = json['relationshipStatus'],
        loyalityToken = json['loyalityToken'],
        loyalityPoint = json['loyalityPoint'] as int?,
        country = json['country'],
        enableTwoFactorAuth = json['enableTwoFactorAuth'] as bool?,
        customGender = json['customGender'];

  Map<String, dynamic> toJson() => {
    'id' : id,
    'username' : username,
    'email' : email,
    'enabled' : enabled,
    'createdAt' : createdAt,
    'firstName' : firstName,
    'lastName' : lastName,
    'dob' : dob,
    'gender' : gender,
    'phone' : phone,
    'families' : families,
    'profilePicture' : profilePicture,
    'coverPhoto' : coverPhoto,
    'namePrefix' : namePrefix,
    'aboutMe' : aboutMe,
    'language' : language,
    'religiousViews' : religiousViews,
    'relationshipStatus' : relationshipStatus,
    'loyalityToken' : loyalityToken,
    'loyalityPoint' : loyalityPoint,
    'country' : country,
    'enableTwoFactorAuth' : enableTwoFactorAuth,
    'customGender' : customGender
  };
}

class PostFamiliesList {
  final int? id;
  final int? familyId;
  final int? postId;

  PostFamiliesList({
    this.id,
    this.familyId,
    this.postId,
  });

  PostFamiliesList.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        familyId = json['familyId'] as int?,
        postId = json['postId'] as int?;

  Map<String, dynamic> toJson() => {
    'id' : id,
    'familyId' : familyId,
    'postId' : postId
  };
}

class PostUserList {
  final int? id;
  final int? userId;
  final int? postId;

  PostUserList({
    this.id,
    this.userId,
    this.postId,
  });

  PostUserList.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        userId = json['userId'] as int?,
        postId = json['postId'] as int?;

  Map<String, dynamic> toJson() => {
    'id' : id,
    'userId' : userId,
    'postId' : postId
  };
}

class PostUserLikes {
  final int? id;
  final String? type;
  final int? userId;
  final int? postId;
  final dynamic votingId;

  PostUserLikes({
    this.id,
    this.type,
    this.userId,
    this.postId,
    this.votingId,
  });

  PostUserLikes.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        type = json['type'] as String?,
        userId = json['userId'] as int?,
        postId = json['postId'] as int?,
        votingId = json['votingId'];

  Map<String, dynamic> toJson() => {
    'id' : id,
    'type' : type,
    'userId' : userId,
    'postId' : postId,
    'votingId' : votingId
  };
}

class PostUserComments {
  final int? id;
  final String? date;
  final String? comment;
  final String? updatedDate;
  final int? userId;
  final int? postId;
  final dynamic parentId;
  final String? firstName;
  final String? lastName;
  final String? localPath;
  final List<dynamic>? commentImageResponse;

  PostUserComments({
    this.id,
    this.date,
    this.comment,
    this.updatedDate,
    this.userId,
    this.postId,
    this.parentId,
    this.firstName,
    this.lastName,
    this.localPath,
    this.commentImageResponse,
  });

  PostUserComments.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        date = json['date'] as String?,
        comment = json['comment'] as String?,
        updatedDate = json['updatedDate'] as String?,
        userId = json['userId'] as int?,
        postId = json['postId'] as int?,
        parentId = json['parentId'],
        firstName = json['firstName'] as String?,
        lastName = json['lastName'] as String?,
        localPath = json['localPath'] as String?,
        commentImageResponse = json['commentImageResponse'] as List?;

  Map<String, dynamic> toJson() => {
    'id' : id,
    'date' : date,
    'comment' : comment,
    'updatedDate' : updatedDate,
    'userId' : userId,
    'postId' : postId,
    'parentId' : parentId,
    'firstName' : firstName,
    'lastName' : lastName,
    'localPath' : localPath,
    'commentImageResponse' : commentImageResponse
  };
}