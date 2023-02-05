class GetPoostsByUserId {
  List<Content>? content;
  String? pageable;
  int? totalPages;
  int? totalElements;
  bool? last;
  int? numberOfElements;
  int? size;
  bool? first;
  int? number;
  Sort? sort;
  bool? empty;

  GetPoostsByUserId({
    this.content,
    this.pageable,
    this.totalPages,
    this.totalElements,
    this.last,
    this.numberOfElements,
    this.size,
    this.first,
    this.number,
    this.sort,
    this.empty,
  });

  GetPoostsByUserId.fromJson(Map<String, dynamic> json) {
    content = (json['content'] as List?)?.map((dynamic e) => Content.fromJson(e as Map<String,dynamic>)).toList();
    pageable = json['pageable'] as String?;
    totalPages = json['totalPages'] as int?;
    totalElements = json['totalElements'] as int?;
    last = json['last'] as bool?;
    numberOfElements = json['numberOfElements'] as int?;
    size = json['size'] as int?;
    first = json['first'] as bool?;
    number = json['number'] as int?;
    sort = (json['sort'] as Map<String,dynamic>?) != null ? Sort.fromJson(json['sort'] as Map<String,dynamic>) : null;
    empty = json['empty'] as bool?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['content'] = content?.map((e) => e.toJson()).toList();
    json['pageable'] = pageable;
    json['totalPages'] = totalPages;
    json['totalElements'] = totalElements;
    json['last'] = last;
    json['numberOfElements'] = numberOfElements;
    json['size'] = size;
    json['first'] = first;
    json['number'] = number;
    json['sort'] = sort?.toJson();
    json['empty'] = empty;
    return json;
  }
}

class Content {
  int? postId;
  int? numOfpages;
  String? firstName;
  String? lastName;
  String? localPath;
  String? type;
  String? text;
  String? date;
  String? updateDate;
  User? user;
  String? bgImg;
  String? feeling;
  String? activity;
  List<PostImages>? postImages;
  List<PostFamiliesList>? postFamiliesList;
  List<PostUserList>? postUserList;
  List<PostUserLikes>? postUserLikes;
  List<PostUserComments>? postUserComments;
  List<PostTaggedUsers>? postTaggedUsers;

  Content({
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

  Content.fromJson(Map<String, dynamic> json) {
    postId = json['postId'] as int?;
    numOfpages = json['numOfpages'] as int?;
    firstName = json['firstName'] as String?;
    lastName = json['lastName'] as String?;
    localPath = json['localPath'] as String?;
    type = json['type'] as String?;
    text = json['text'] as String?;
    date = json['date'] as String?;
    updateDate = json['updateDate'] as String?;
    user = (json['user'] as Map<String,dynamic>?) != null ? User.fromJson(json['user'] as Map<String,dynamic>) : null;
    bgImg = json['bgImg'] as String?;
    feeling = json['feeling'] as String?;
    activity = json['activity'] as String?;
    postImages = (json['postImages'] as List?)?.map((dynamic e) => PostImages.fromJson(e as Map<String,dynamic>)).toList();
    postFamiliesList = (json['postFamiliesList'] as List?)?.map((dynamic e) => PostFamiliesList.fromJson(e as Map<String,dynamic>)).toList();
    postUserList = (json['postUserList'] as List?)?.map((dynamic e) => PostUserList.fromJson(e as Map<String,dynamic>)).toList();
    postUserLikes = (json['postUserLikes'] as List?)?.map((dynamic e) => PostUserLikes.fromJson(e as Map<String,dynamic>)).toList();
    postUserComments = (json['postUserComments'] as List?)?.map((dynamic e) => PostUserComments.fromJson(e as Map<String,dynamic>)).toList();
    postTaggedUsers = (json['postTaggedUsers'] as List?)?.map((dynamic e) => PostTaggedUsers.fromJson(e as Map<String,dynamic>)).toList();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['postId'] = postId;
    json['numOfpages'] = numOfpages;
    json['firstName'] = firstName;
    json['lastName'] = lastName;
    json['localPath'] = localPath;
    json['type'] = type;
    json['text'] = text;
    json['date'] = date;
    json['updateDate'] = updateDate;
    json['user'] = user?.toJson();
    json['bgImg'] = bgImg;
    json['feeling'] = feeling;
    json['activity'] = activity;
    json['postImages'] = postImages?.map((e) => e.toJson()).toList();
    json['postFamiliesList'] = postFamiliesList?.map((e) => e.toJson()).toList();
    json['postUserList'] = postUserList?.map((e) => e.toJson()).toList();
    json['postUserLikes'] = postUserLikes?.map((e) => e.toJson()).toList();
    json['postUserComments'] = postUserComments?.map((e) => e.toJson()).toList();
    json['postTaggedUsers'] = postTaggedUsers?.map((e) => e.toJson()).toList();
    return json;
  }
}

class User {
  int? id;
  String? username;
  String? email;
  bool? enabled;
  dynamic createdAt;
  String? firstName;
  String? lastName;
  String? dob;
  String? gender;
  String? phone;
  dynamic families;
  String? profilePicture;
  String? coverPhoto;
  dynamic namePrefix;
  dynamic aboutMe;
  dynamic language;
  dynamic religiousViews;
  dynamic relationshipStatus;
  dynamic loyalityToken;
  int? loyalityPoint;
  dynamic country;
  bool? enableTwoFactorAuth;
  dynamic customGender;

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

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    username = json['username'] as String?;
    email = json['email'] as String?;
    enabled = json['enabled'] as bool?;
    createdAt = json['createdAt'];
    firstName = json['firstName'] as String?;
    lastName = json['lastName'] as String?;
    dob = json['dob'] as String?;
    gender = json['gender'] as String?;
    phone = json['phone'] as String?;
    families = json['families'];
    profilePicture = json['profilePicture'] as String?;
    coverPhoto = json['coverPhoto'] as String?;
    namePrefix = json['namePrefix'];
    aboutMe = json['aboutMe'];
    language = json['language'];
    religiousViews = json['religiousViews'];
    relationshipStatus = json['relationshipStatus'];
    loyalityToken = json['loyalityToken'];
    loyalityPoint = json['loyalityPoint'] as int?;
    country = json['country'];
    enableTwoFactorAuth = json['enableTwoFactorAuth'] as bool?;
    customGender = json['customGender'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['id'] = id;
    json['username'] = username;
    json['email'] = email;
    json['enabled'] = enabled;
    json['createdAt'] = createdAt;
    json['firstName'] = firstName;
    json['lastName'] = lastName;
    json['dob'] = dob;
    json['gender'] = gender;
    json['phone'] = phone;
    json['families'] = families;
    json['profilePicture'] = profilePicture;
    json['coverPhoto'] = coverPhoto;
    json['namePrefix'] = namePrefix;
    json['aboutMe'] = aboutMe;
    json['language'] = language;
    json['religiousViews'] = religiousViews;
    json['relationshipStatus'] = relationshipStatus;
    json['loyalityToken'] = loyalityToken;
    json['loyalityPoint'] = loyalityPoint;
    json['country'] = country;
    json['enableTwoFactorAuth'] = enableTwoFactorAuth;
    json['customGender'] = customGender;
    return json;
  }
}

class PostImages {
  int? id;
  String? date;
  String? extension;
  String? localPath;
  int? userId;
  dynamic type;
  String? userName;
  dynamic albumId;
  dynamic description;
  int? postId;
  dynamic eventModel;
  dynamic noteId;
  bool? markedToBeDeleted;
  dynamic markedToBeDeleteddate;
  List<dynamic>? imageFamiliesList;
  List<dynamic>? imageUserList;
  dynamic votingId;

  PostImages({
    this.id,
    this.date,
    this.extension,
    this.localPath,
    this.userId,
    this.type,
    this.userName,
    this.albumId,
    this.description,
    this.postId,
    this.eventModel,
    this.noteId,
    this.markedToBeDeleted,
    this.markedToBeDeleteddate,
    this.imageFamiliesList,
    this.imageUserList,
    this.votingId,
  });

  PostImages.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    date = json['date'] as String?;
    extension = json['extension'] as String?;
    localPath = json['localPath'] as String?;
    userId = json['userId'] as int?;
    type = json['type'];
    userName = json['userName'] as String?;
    albumId = json['albumId'];
    description = json['description'];
    postId = json['postId'] as int?;
    eventModel = json['eventModel'];
    noteId = json['noteId'];
    markedToBeDeleted = json['markedToBeDeleted'] as bool?;
    markedToBeDeleteddate = json['markedToBeDeleteddate'];
    imageFamiliesList = json['imageFamiliesList'] as List?;
    imageUserList = json['imageUserList'] as List?;
    votingId = json['votingId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['id'] = id;
    json['date'] = date;
    json['extension'] = extension;
    json['localPath'] = localPath;
    json['userId'] = userId;
    json['type'] = type;
    json['userName'] = userName;
    json['albumId'] = albumId;
    json['description'] = description;
    json['postId'] = postId;
    json['eventModel'] = eventModel;
    json['noteId'] = noteId;
    json['markedToBeDeleted'] = markedToBeDeleted;
    json['markedToBeDeleteddate'] = markedToBeDeleteddate;
    json['imageFamiliesList'] = imageFamiliesList;
    json['imageUserList'] = imageUserList;
    json['votingId'] = votingId;
    return json;
  }
}

class PostFamiliesList {
  int? id;
  int? familyId;
  int? postId;

  PostFamiliesList({
    this.id,
    this.familyId,
    this.postId,
  });

  PostFamiliesList.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    familyId = json['familyId'] as int?;
    postId = json['postId'] as int?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['id'] = id;
    json['familyId'] = familyId;
    json['postId'] = postId;
    return json;
  }
}

class PostUserList {
  int? id;
  int? userId;
  int? postId;

  PostUserList({
    this.id,
    this.userId,
    this.postId,
  });

  PostUserList.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    userId = json['userId'] as int?;
    postId = json['postId'] as int?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['id'] = id;
    json['userId'] = userId;
    json['postId'] = postId;
    return json;
  }
}

class PostUserLikes {
  int? id;
  String? type;
  int? userId;
  int? postId;
  dynamic votingId;

  PostUserLikes({
    this.id,
    this.type,
    this.userId,
    this.postId,
    this.votingId,
  });

  PostUserLikes.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    type = json['type'] as String?;
    userId = json['userId'] as int?;
    postId = json['postId'] as int?;
    votingId = json['votingId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['id'] = id;
    json['type'] = type;
    json['userId'] = userId;
    json['postId'] = postId;
    json['votingId'] = votingId;
    return json;
  }
}

class PostUserComments {
  int? id;
  String? date;
  String? comment;
  String? updatedDate;
  int? userId;
  int? postId;
  String? firstName;
  String? lastName;
  String? localPath;

  PostUserComments({
    this.id,
    this.date,
    this.comment,
    this.updatedDate,
    this.userId,
    this.postId,
    this.firstName,
    this.lastName,
    this.localPath,
  });

  PostUserComments.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    date = json['date'] as String?;
    comment = json['comment'] as String?;
    updatedDate = json['updatedDate'] as String?;
    userId = json['userId'] as int?;
    postId = json['postId'] as int?;
    firstName = json['firstName'] as String?;
    lastName = json['lastName'] as String?;
    localPath = json['localPath'] as String?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['id'] = id;
    json['date'] = date;
    json['comment'] = comment;
    json['updatedDate'] = updatedDate;
    json['userId'] = userId;
    json['postId'] = postId;
    json['firstName'] = firstName;
    json['lastName'] = lastName;
    json['localPath'] = localPath;
    return json;
  }
}

class PostTaggedUsers {
  int? id;
  int? userId;
  int? postId;
  String? userName;

  PostTaggedUsers({
    this.id,
    this.userId,
    this.postId,
    this.userName,
  });

  PostTaggedUsers.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    userId = json['userId'] as int?;
    postId = json['postId'] as int?;
    userName = json['userName'] as String?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['id'] = id;
    json['userId'] = userId;
    json['postId'] = postId;
    json['userName'] = userName;
    return json;
  }
}

class Sort {
  bool? sorted;
  bool? unsorted;
  bool? empty;

  Sort({
    this.sorted,
    this.unsorted,
    this.empty,
  });

  Sort.fromJson(Map<String, dynamic> json) {
    sorted = json['sorted'] as bool?;
    unsorted = json['unsorted'] as bool?;
    empty = json['empty'] as bool?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['sorted'] = sorted;
    json['unsorted'] = unsorted;
    json['empty'] = empty;
    return json;
  }
}