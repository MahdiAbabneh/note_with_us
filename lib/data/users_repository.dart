import 'package:cloud_firestore/cloud_firestore.dart';

import 'models.dart';

/// Default avatars the original app assigned by gender; kept so older
/// app versions still show a picture for new accounts.
const String maleAvatar =
    'https://cdn-icons-png.flaticon.com/512/146/146007.png';
const String femaleAvatar =
    'https://cdn-icons-png.flaticon.com/512/146/146005.png';

/// Profiles, circles, blocks and reports.
class UsersRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// The profile of [uid], or `null` while it does not exist yet.
  Stream<AppUser?> watch(String uid) => _users
      .doc(uid)
      .snapshots()
      .map(
        (d) => d.exists ? AppUser.fromMap({...?d.data(), 'uId': uid}) : null,
      );

  /// Everyone with a profile.
  Stream<List<AppUser>> all() => _users.snapshots().map(
    (s) => s.docs
        .map((d) => AppUser.fromMap({...d.data(), 'uId': d.id}))
        .where((u) => u.username.isNotEmpty)
        .toList(),
  );

  Future<void> createProfile({
    required String uid,
    required String email,
    required String username,
    required String dateOfBirth,
    required String gender,
    String token = '',
  }) => _users.doc(uid).set({
    'uId': uid,
    'email': email,
    'username': username,
    'image': gender == 'Female' ? femaleAvatar : maleAvatar,
    'token': token,
    'dateOfBirth': dateOfBirth,
    'phoneNumber': '',
    'gender': gender,
    'location': '',
    'bio': '',
    'theme': 'origin',
    'darkMood': false,
  });

  Future<void> update(String uid, Map<String, Object?> fields) =>
      _users.doc(uid).update(fields);

  /// Uploads a new profile photo and stores its URL.
  /// Sets the profile picture to one of the built-in avatars.
  Future<void> setAvatar(String uid, String avatar) =>
      update(uid, {'image': avatar});

  /// People [uid] shares circle notes with.
  Stream<Set<String>> circle(String uid) => _db
      .collection('circles')
      .doc(uid)
      .snapshots()
      .map(
        (d) => {...(d.data()?['members'] as List? ?? const []).cast<String>()},
      );

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('circleRequests');

  DocumentReference<Map<String, dynamic>> _circleDoc(String uid) =>
      _db.collection('circles').doc(uid);

  DocumentReference<Map<String, dynamic>> _request(String from, String to) =>
      _requests.doc('${from}_$to');

  /// Requests other people sent to [uid].
  Stream<List<CircleRequest>> incomingRequests(String uid) => _requests
      .where('to', isEqualTo: uid)
      .snapshots()
      .map(
        (s) =>
            s.docs.map(CircleRequest.fromDoc).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  /// Requests [uid] sent that are still waiting.
  Stream<List<CircleRequest>> outgoingRequests(String uid) => _requests
      .where('from', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map(CircleRequest.fromDoc).toList());

  /// Asks [other] to join circles with [me]. Nothing changes until they
  /// accept.
  Future<void> sendCircleRequest(AppUser me, AppUser other) =>
      _request(me.uid, other.uid).set({
        'from': me.uid,
        'to': other.uid,
        'fromName': me.username,
        'fromImage': me.image,
        'createdAt': Timestamp.now(),
      });

  Future<void> cancelCircleRequest(String me, String other) =>
      _request(me, other).delete();

  Future<void> declineCircleRequest(CircleRequest request) =>
      _request(request.from, request.to).delete();

  /// Accepting puts both people in each other's circle. [alsoSent] is
  /// true when the accepter had sent a request the other way too.
  Future<void> acceptCircleRequest(
    CircleRequest request, {
    bool alsoSent = false,
  }) async {
    final batch = _db.batch()
      ..set(_circleDoc(request.to), {
        'members': FieldValue.arrayUnion([request.from]),
      }, SetOptions(merge: true))
      ..set(_circleDoc(request.from), {
        'members': FieldValue.arrayUnion([request.to]),
      }, SetOptions(merge: true))
      ..delete(_request(request.from, request.to));
    if (alsoSent) batch.delete(_request(request.to, request.from));
    await batch.commit();
  }

  /// Removes [other] from [uid]'s circle and [uid] from theirs.
  Future<void> removeFromCircle(String uid, String other) async {
    final batch = _db.batch()
      ..set(_circleDoc(uid), {
        'members': FieldValue.arrayRemove([other]),
      }, SetOptions(merge: true))
      ..set(_circleDoc(other), {
        'members': FieldValue.arrayRemove([uid]),
      }, SetOptions(merge: true));
    await batch.commit();
  }

  /// People [uid] has blocked.
  Stream<Set<String>> blocked(String uid) => _db
      .collection('blocks')
      .doc(uid)
      .snapshots()
      .map(
        (d) => {...(d.data()?['blocked'] as List? ?? const []).cast<String>()},
      );

  Future<void> setBlocked(
    String uid,
    String other, {
    required bool block,
  }) async {
    await _db.collection('blocks').doc(uid).set({
      'blocked': block
          ? FieldValue.arrayUnion([other])
          : FieldValue.arrayRemove([other]),
    }, SetOptions(merge: true));
    if (!block) return;
    await removeFromCircle(uid, other);
    // Drop any pending requests either way; a missing one isn't an error.
    for (final ref in [_request(uid, other), _request(other, uid)]) {
      try {
        await ref.delete();
      } on FirebaseException {
        // No request existed in this direction.
      }
    }
  }

  Future<void> report(String userId, String reporterId) => _db
      .collection('reportUser')
      .doc(userId)
      .collection('report')
      .add({'reportUser': reporterId});

  /// Removes everything the app stores about [uid].
  Future<void> deleteAllData(String uid) async {
    final refs = <DocumentReference>[];
    Future<void> collect(Query<Map<String, dynamic>> query) async =>
        refs.addAll((await query.get()).docs.map((d) => d.reference));
    Future<void> collectCapsules(Query<Map<String, dynamic>> query) async {
      for (final doc in (await query.get()).docs) {
        refs
          ..add(doc.reference.collection('sealed').doc('content'))
          ..add(doc.reference);
      }
    }

    // Circle capsules you started go entirely; in the others, only your
    // own letter. Your pages in shared notebooks go, the notebook stays
    // for the other person to keep or delete.
    Future<void> collectTogether() async {
      final capsules = await _db
          .collection('groupCapsules')
          .where('members', arrayContains: uid)
          .get();
      for (final doc in capsules.docs) {
        if (doc.data()['ownerId'] == uid) {
          refs.addAll(
            (await doc.reference.collection('entries').get()).docs.map(
              (d) => d.reference,
            ),
          );
          refs.add(doc.reference);
        } else {
          refs.add(doc.reference.collection('entries').doc(uid));
        }
      }
      final notebooks = await _db
          .collection('sharedNotebooks')
          .where('members', arrayContains: uid)
          .get();
      for (final doc in notebooks.docs) {
        await collect(
          doc.reference.collection('entries').where('ownerId', isEqualTo: uid),
        );
      }
    }

    await Future.wait([
      collectTogether(),
      collect(_db.collection('postsOnlyMe').doc(uid).collection('myPost')),
      collect(_db.collection('postsMain').where('ownerId', isEqualTo: uid)),
      collect(_db.collection('circlePosts').where('ownerId', isEqualTo: uid)),
      collectCapsules(
        _db.collection('capsules').where('ownerId', isEqualTo: uid),
      ),
      collectCapsules(
        _db.collection('capsules').where('recipientId', isEqualTo: uid),
      ),
      collect(_users.doc(uid).collection('chats')),
      collect(_users.doc(uid).collection('favorites')),
    ]);
    refs.addAll([
      _db.collection('circles').doc(uid),
      _db.collection('blocks').doc(uid),
      _db.collection('imagesUser').doc(uid),
      _db.collection('reminder').doc(uid),
      _users.doc(uid),
    ]);
    for (var i = 0; i < refs.length; i += 400) {
      final batch = _db.batch();
      for (final ref in refs.skip(i).take(400)) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }
}
