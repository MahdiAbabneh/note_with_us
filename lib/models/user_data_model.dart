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
  });

  String? uId;
  String? username;
  String? email;
  String? token;
  String? image;
  String? phoneNumber;
  String?dateOfBirth;
  String?gender;


  UserDataModel.fromJson(Map<String, dynamic> json) {
    uId = json['uId'] ?? '';
    username = json['username'] ?? '';
    email = json['email'] ?? '';
    token = json['token'] ?? '';
    image = json['image'] ?? '';
    phoneNumber = json['phoneNumber'] ?? '';
    dateOfBirth = json['dateOfBirth'] ?? '';
    gender = json['gender'] ?? '';
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

    };
  }
}