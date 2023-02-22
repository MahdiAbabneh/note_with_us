class UserDataModel {
  UserDataModel({
    this.uId,
    this.username,
    this.email,
    this.token,
    this.image,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.location,
    this.theme,
    this.darkMood
  });

  String? uId;
  String? username;
  String? email;
  String? token;
  String? image;
  String? phoneNumber;
  String? dateOfBirth;
  String? gender;
  String? location;
  String? theme;
  bool ?  darkMood;


  UserDataModel.fromJson(Map<String, dynamic> json) {
    uId = json['uId'] ?? '';
    username = json['username'] ?? '';
    email = json['email'] ?? '';
    token = json['token'] ?? '';
    image = json['image'] ?? '';
    phoneNumber = json['phoneNumber'] ?? '';
    dateOfBirth = json['dateOfBirth'] ?? '';
    gender = json['gender'] ?? '';
    location = json['location'] ?? '';
    theme = json['theme'] ?? '';
    darkMood = json['darkMood'] ?? false;
  }

  Map<String, dynamic> toJson() {
    return {
      'uId': uId,
      'username': username,
      'email': email,
      'token': token,
      'image': image,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'location':location,
      'theme':theme,
      'darkMood':darkMood

    };
  }
}