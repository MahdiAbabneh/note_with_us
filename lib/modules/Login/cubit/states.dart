
abstract class LoginStates {}

class LoginInitialState extends LoginStates {}

class UserLoginLoading extends LoginStates {}

class UserLoginGoogleSuccess extends LoginStates {}

class UserLoginGoogleInfoSuccess extends LoginStates {}

class UserLoginGoogleInfoError extends LoginStates {}

class UserLoginSuccess extends LoginStates {}

class UserLoginError extends LoginStates {}

class SocialChangePasswordVisibility extends LoginStates {}



