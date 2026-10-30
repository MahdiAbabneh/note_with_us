import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/prefs.dart';
import '../core/reminders.dart';
import 'auth_service.dart';
import 'capsules_repository.dart';
import 'chat_repository.dart';
import 'models.dart';
import 'notes_repository.dart';
import 'together_repository.dart';
import 'users_repository.dart';

/// Where the signed-in flow currently is. A guest is signed out but
/// browsing public notes before creating an account.
enum SessionStatus { loading, signedOut, guest, needsProfile, ready }

const _guestKey = 'guest';
const _guestHiddenKey = 'guestHidden';

/// App-wide signed-in state: the current profile, circle and blocks,
/// plus a live directory of users for names and avatars.
class Session extends ChangeNotifier {
  Session._() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuth);
  }

  /// Shared instance.
  static final Session instance = Session._();

  final auth = AuthService();
  final users = UsersRepository();
  final notes = NotesRepository();
  final capsules = CapsulesRepository();
  final chats = ChatRepository();
  final groupCapsules = GroupCapsulesRepository();
  final notebooks = NotebooksRepository();
  final asks = AsksRepository();

  SessionStatus status = SessionStatus.loading;
  AppUser? _me;
  Set<String> circle = {};
  Set<String> blocked = {};

  /// Circle requests waiting for this user's answer.
  List<CircleRequest> incomingRequests = [];

  /// People this user has asked to join circles with.
  Set<String> requested = {};

  /// Notes this user saved, newest first, and their keys for lookups.
  List<FavoriteRef> favorites = [];
  Set<String> get favoriteKeys => {for (final f in favorites) f.key};
  Map<String, AppUser> directory = {};
  final List<StreamSubscription<dynamic>> _subs = [];

  bool get isGuest => status == SessionStatus.guest;

  /// Starts browsing without an account. Remembered, so the app reopens
  /// in guest mode until the person signs in.
  void enterGuest() {
    Prefs.setBool(_guestKey, true);
    if (status != SessionStatus.signedOut) return;
    blocked = _guestHidden();
    status = SessionStatus.guest;
    notifyListeners();
  }

  /// Back to the welcome screen.
  void leaveGuest() {
    Prefs.setBool(_guestKey, false);
    if (!isGuest) return;
    blocked = {};
    status = SessionStatus.signedOut;
    notifyListeners();
  }

  /// Guests can't block anyone, but can hide someone's notes on this
  /// device.
  void hideForGuest(String ownerId) {
    blocked = {...blocked, ownerId};
    Prefs.setString(_guestHiddenKey, blocked.join(','));
    notifyListeners();
  }

  static Set<String> _guestHidden() =>
      (Prefs.getString(_guestHiddenKey) ?? '').split(',').toSet()..remove('');

  /// The signed-in profile. Only valid while [status] is ready.
  AppUser get me => _me!;
  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  User? get authUser => FirebaseAuth.instance.currentUser;

  /// Everyone except the current user and people they blocked.
  List<AppUser> get people =>
      directory.values
          .where((u) => u.uid != uid && !blocked.contains(u.uid))
          .toList()
        ..sort(
          (a, b) =>
              a.username.toLowerCase().compareTo(b.username.toLowerCase()),
        );

  List<AppUser> get circleMembers =>
      circle.map((id) => directory[id]).whereType<AppUser>().toList();

  /// Live name/avatar for [uid], falling back to what a note stored.
  AppUser userOr(String uid, {String name = '', String image = ''}) =>
      directory[uid] ?? AppUser(uid: uid, username: name, image: image);

  bool isVisible(String ownerId) => !blocked.contains(ownerId);

  void _onAuth(User? user) {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    _me = null;
    circle = {};
    blocked = {};
    incomingRequests = [];
    requested = {};
    favorites = [];
    if (user == null) {
      // Capsule alerts belong to the account that received them.
      Reminders.instance.clearCapsuleAlerts();
      Reminders.instance.clearBirthdayAlerts();
      final guest = Prefs.getBool(_guestKey) ?? false;
      if (guest) blocked = _guestHidden();
      status = guest ? SessionStatus.guest : SessionStatus.signedOut;
      notifyListeners();
      return;
    }
    // Signing in ends guest mode; signing out later shows the welcome.
    Prefs.setBool(_guestKey, false);
    status = SessionStatus.loading;
    notifyListeners();
    _subs
      ..add(users.watch(user.uid).listen(_onProfile))
      ..add(
        users.circle(user.uid).listen((c) {
          circle = c;
          notifyListeners();
        }),
      )
      ..add(
        users.blocked(user.uid).listen((b) {
          blocked = b;
          notifyListeners();
        }),
      )
      ..add(
        users.incomingRequests(user.uid).listen((r) {
          incomingRequests = r;
          notifyListeners();
        }, onError: (_) {}),
      )
      ..add(
        notes.favorites(user.uid).listen((f) {
          favorites = f;
          notifyListeners();
        }, onError: (_) {}),
      )
      ..add(
        users.outgoingRequests(user.uid).listen((r) {
          requested = {for (final x in r) x.to};
          notifyListeners();
        }, onError: (_) {}),
      )
      ..add(
        users.all().listen((list) {
          directory = {for (final u in list) u.uid: u};
          notifyListeners();
        }),
      );
  }

  void _onProfile(AppUser? profile) {
    final firstLoad = _me == null && profile != null;
    _me = profile;
    status = profile == null ? SessionStatus.needsProfile : SessionStatus.ready;
    notifyListeners();
    if (firstLoad) _refreshPushToken();
  }

  Future<void> _refreshPushToken() async {
    final token = await AuthService.pushToken();
    if (token.isNotEmpty) await users.update(uid, {'token': token});
  }
}
