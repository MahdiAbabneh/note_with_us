import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'users_repository.dart';

/// Thrown when the user backs out of a sign-in sheet.
class SignInCancelled implements Exception {
  const SignInCancelled();
}

/// Wraps Firebase Auth plus Google and Apple sign-in.
class AuthService {
  AuthService({UsersRepository? users}) : _users = users ?? UsersRepository();

  final UsersRepository _users;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  bool _googleReady = false;

  /// Which provider the current account uses: `password`, `google.com`
  /// or `apple.com`.
  String get provider {
    final providers = _auth.currentUser?.providerData ?? const [];
    return providers.isEmpty ? 'password' : providers.first.providerId;
  }

  Future<void> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  /// Creates an email account and its profile in one go.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String dateOfBirth,
    required String gender,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _users.createProfile(
      uid: cred.user!.uid,
      email: email,
      username: username,
      dateOfBirth: dateOfBirth,
      gender: gender,
      token: await pushToken(),
    );
  }

  Future<void> signInWithGoogle() async {
    await _auth.signInWithCredential(await _googleCredential());
  }

  Future<void> signInWithApple() async {
    try {
      await _auth.signInWithProvider(
        AppleAuthProvider()
          ..addScope('email')
          ..addScope('name'),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'canceled' || e.code == 'web-context-canceled') {
        throw const SignInCancelled();
      }
      rethrow;
    }
  }

  Future<AuthCredential> _googleCredential() async {
    try {
      if (!_googleReady) {
        await GoogleSignIn.instance.initialize();
        _googleReady = true;
      }
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: ['profile', 'email'],
      );
      return GoogleAuthProvider.credential(
        idToken: account.authentication.idToken,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const SignInCancelled();
      }
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> signOut() async {
    if (_googleReady) await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  /// Confirms the user's identity again; Firebase requires a recent
  /// sign-in before an account can be deleted.
  Future<void> reauthenticate({String? password}) async {
    final user = _auth.currentUser!;
    switch (provider) {
      case 'google.com':
        await user.reauthenticateWithCredential(await _googleCredential());
      case 'apple.com':
        await user.reauthenticateWithProvider(AppleAuthProvider());
      default:
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(
            email: user.email ?? '',
            password: password ?? '',
          ),
        );
    }
  }

  /// Deletes all data and then the account itself.
  Future<void> deleteAccount({String? password}) async {
    await reauthenticate(password: password);
    final user = _auth.currentUser!;
    await _users.deleteAllData(user.uid);
    await user.delete();
    if (_googleReady) await GoogleSignIn.instance.signOut();
  }

  /// The FCM token, or an empty string when push is not set up (for
  /// example on iOS without an APNs key).
  static Future<String> pushToken() async {
    try {
      // ignore: deprecated_member_use
      return await FirebaseMessaging.instance.getToken() ?? '';
    } catch (_) {
      return '';
    }
  }
}
