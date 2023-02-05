class SigninModel {
  final String? accessToken;
  final String? refreshToken;
  final String? tokenType;
  final int? id;
  final String? username;
  final String? email;
  final List<String>? roles;
  final String? firstName;
  final String? lastName;
  final String? theme;
  final String? systemLanguageFileName;
  final bool? activated;
  final String? phone;
  final Country? country;
  final bool? markedForDeleted;

  SigninModel({
    this.accessToken,
    this.refreshToken,
    this.tokenType,
    this.id,
    this.username,
    this.email,
    this.roles,
    this.firstName,
    this.lastName,
    this.theme,
    this.systemLanguageFileName,
    this.activated,
    this.phone,
    this.country,
    this.markedForDeleted,
  });

  SigninModel.fromJson(Map<String, dynamic> json)
      : accessToken = json['accessToken'] as String?,
        refreshToken = json['refreshToken'] as String?,
        tokenType = json['tokenType'] as String?,
        id = json['id'] as int?,
        username = json['username'] as String?,
        email = json['email'] as String?,
        roles = (json['roles'] as List?)?.map((dynamic e) => e as String).toList(),
        firstName = json['firstName'] as String?,
        lastName = json['lastName'] as String?,
        theme = json['theme'] as String?,
        systemLanguageFileName = json['systemLanguageFileName'] as String?,
        activated = json['activated'] as bool?,
        phone = json['phone'] as String?,
        country = (json['country'] as Map<String,dynamic>?) != null ? Country.fromJson(json['country'] as Map<String,dynamic>) : null,
        markedForDeleted = json['markedForDeleted'] as bool?;

  Map<String, dynamic> toJson() => {
    'accessToken' : accessToken,
    'refreshToken' : refreshToken,
    'tokenType' : tokenType,
    'id' : id,
    'username' : username,
    'email' : email,
    'roles' : roles,
    'firstName' : firstName,
    'lastName' : lastName,
    'theme' : theme,
    'systemLanguageFileName' : systemLanguageFileName,
    'activated' : activated,
    'phone' : phone,
    'country' : country?.toJson(),
    'markedForDeleted' : markedForDeleted
  };
}

class Country {
  final int? id;
  final String? shortName;
  final String? name;
  final int? phoneCode;

  Country({
    this.id,
    this.shortName,
    this.name,
    this.phoneCode,
  });

  Country.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int?,
        shortName = json['shortName'] as String?,
        name = json['name'] as String?,
        phoneCode = json['phoneCode'] as int?;

  Map<String, dynamic> toJson() => {
    'id' : id,
    'shortName' : shortName,
    'name' : name,
    'phoneCode' : phoneCode
  };
}