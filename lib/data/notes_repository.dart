import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../design/tokens.dart';
import 'models.dart';

/// Timestamp format the original app used for `time`, kept so new and
/// old notes sort together.
String noteTimestamp(DateTime time) =>
    '${DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").format(time)}Z';

List<Note> _sorted(List<Note> notes) =>
    notes..sort((a, b) => b.time.compareTo(a.time));

/// Reads and writes notes, reactions and comments.
class NotesRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(
    Audience audience,
    String ownerId,
  ) {
    return switch (audience) {
      Audience.everyone => _db.collection('postsMain'),
      Audience.circle => _db.collection('circlePosts'),
      Audience.private =>
        _db.collection('postsOnlyMe').doc(ownerId).collection('myPost'),
    };
  }

  DocumentReference<Map<String, dynamic>> _ref(Note note) =>
      _collection(note.audience, note.ownerId).doc(note.id);

  /// Latest public notes.
  Stream<List<Note>> everyone() => _db
      .collection('postsMain')
      .orderBy('time', descending: true)
      .limit(80)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => Note.fromDoc(d, Audience.everyone)).toList(),
      );

  /// Notes shared with [uid] by people who have them in their circle.
  Stream<List<Note>> circleFeed(String uid) => _db
      .collection('circlePosts')
      .where('audience', arrayContains: uid)
      .snapshots()
      .map(
        (s) => _sorted(
          s.docs.map((d) => Note.fromDoc(d, Audience.circle)).toList(),
        ),
      );

  /// The private journal of [uid], newest first, up to [limit] notes.
  Stream<List<Note>> journal(String uid, {int limit = 40}) =>
      _collection(Audience.private, uid)
          .orderBy('time', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (s) =>
                s.docs.map((d) => Note.fromDoc(d, Audience.private)).toList(),
          );

  /// Everything [uid] wrote (private, circle and public), read once and
  /// newest first. Used by the PDF export, so it has no limit.
  Future<List<Note>> allMine(String uid) async {
    final results = await Future.wait([
      _collection(Audience.private, uid).get(),
      _db.collection('circlePosts').where('audience', arrayContains: uid).get(),
      _db.collection('postsMain').where('ownerId', isEqualTo: uid).get(),
    ]);
    return _sorted([
      for (final d in results[0].docs) Note.fromDoc(d, Audience.private),
      for (final d in results[1].docs)
        if (d.data()['ownerId'] == uid) Note.fromDoc(d, Audience.circle),
      for (final d in results[2].docs) Note.fromDoc(d, Audience.everyone),
    ]);
  }

  /// Public notes written by [uid].
  Stream<List<Note>> publicBy(String uid) => _db
      .collection('postsMain')
      .where('ownerId', isEqualTo: uid)
      .snapshots()
      .map(
        (s) => _sorted(
          s.docs.map((d) => Note.fromDoc(d, Audience.everyone)).toList(),
        ),
      );

  /// A single note, kept live for the detail screen.
  Stream<Note?> watch(Note note) => _ref(
    note,
  ).snapshots().map((d) => d.exists ? Note.fromDoc(d, note.audience) : null);

  /// Creates a note, uploading [photos] first.
  Future<void> create({
    required AppUser author,
    required Audience audience,
    required String text,
    required Mood mood,
    String prompt = '',
    String promptDay = '',
    String kind = '',
    List<String> circle = const [],
  }) async {
    await _collection(audience, author.uid).add({
      'text': text,
      'time': noteTimestamp(DateTime.now()),
      // Photos are no longer supported; the fields stay so older app
      // versions can still read new notes.
      'image': [],
      'numOfImages': 3,
      'ownerId': author.uid,
      'ownerName': author.username,
      'ownerImage': author.image,
      'likes': [],
      'reactions': {},
      'mood': mood.id,
      'prompt': prompt,
      if (promptDay.isNotEmpty) 'promptDay': promptDay,
      if (kind.isNotEmpty) 'kind': kind,
      'commentCount': 0,
      if (audience == Audience.circle)
        'audience': {author.uid, ...circle}.toList(),
    });
  }

  /// Sets, changes or (with `null`) removes [uid]'s reaction.
  Future<void> react(Note note, String uid, String? emoji) async {
    final update = <String, Object?>{
      'reactions.$uid': emoji ?? FieldValue.delete(),
    };
    if (note.legacyLikes.contains(uid)) {
      final doc = await _ref(note).get();
      final likes = (doc.data()?['likes'] as List? ?? const [])
          .where((l) => l is! Map || l['ownerId'] != uid)
          .toList();
      update['likes'] = likes;
    }
    await _ref(note).update(update);
  }

  Future<void> delete(Note note) => _ref(note).delete();

  /// Archives (hides) or restores one of the owner's private notes.
  Future<void> setArchived(Note note, {required bool archived}) =>
      _ref(note).update({'archived': archived});

  /// Everything [uid] wrote, private, circle and public, newest first.
  /// Used for weekly insights; emits once all three sources have loaded.
  Stream<List<Note>> mine(String uid, {int limit = 300}) {
    final sources = [
      journal(uid, limit: limit),
      circleFeed(uid).map((l) => l.where((n) => n.ownerId == uid).toList()),
      publicBy(uid),
    ];
    final latest = List<List<Note>?>.filled(sources.length, null);
    late final StreamController<List<Note>> controller;
    final subs = <StreamSubscription<List<Note>>>[];
    controller = StreamController<List<Note>>(
      onListen: () {
        for (var i = 0; i < sources.length; i++) {
          subs.add(
            sources[i].listen((notes) {
              latest[i] = notes;
              if (latest.every((l) => l != null)) {
                controller.add(_sorted([for (final l in latest) ...l!]));
              }
            }, onError: controller.addError),
          );
        }
      },
      onCancel: () async {
        for (final sub in subs) {
          await sub.cancel();
        }
      },
    );
    return controller.stream;
  }

  CollectionReference<Map<String, dynamic>> _favorites(String uid) =>
      _db.collection('users').doc(uid).collection('favorites');

  /// Notes [uid] saved as favorites, newest first.
  Stream<List<FavoriteRef>> favorites(String uid) =>
      _favorites(uid).snapshots().map(
        (s) =>
            s.docs.map(FavoriteRef.fromDoc).toList()
              ..sort((a, b) => b.savedAt.compareTo(a.savedAt)),
      );

  Future<void> setFavorite(String uid, Note note, {required bool favorite}) {
    final ref = _favorites(uid).doc(note.key);
    if (!favorite) return ref.delete();
    return ref.set({
      'audience': note.audience.name,
      'ownerId': note.ownerId,
      'noteId': note.id,
      'savedAt': Timestamp.now(),
    });
  }

  /// Loads the notes behind [refs], skipping ones that were deleted or
  /// that the user can no longer see.
  Future<List<Note>> resolve(List<FavoriteRef> refs) async {
    final notes = await Future.wait(
      refs.map((r) async {
        try {
          final doc = await _collection(
            r.audience,
            r.ownerId,
          ).doc(r.noteId).get();
          return doc.exists ? Note.fromDoc(doc, r.audience) : null;
        } on FirebaseException {
          return null;
        }
      }),
    );
    return notes.whereType<Note>().toList();
  }

  /// Pins or unpins one of the owner's private notes.
  Future<void> setComfort(Note note, {required bool comfort}) =>
      _ref(note).update({'comfort': comfort});

  Future<void> setPinned(Note note, {required bool pinned}) =>
      _ref(note).update({'pinned': pinned});

  /// Comments, oldest first.
  Stream<List<Comment>> comments(Note note) => _ref(note)
      .collection('comments')
      .orderBy('time')
      .snapshots()
      .map((s) => s.docs.map(Comment.fromDoc).toList());

  Future<void> addComment(Note note, AppUser author, String text) async {
    final batch = _db.batch()
      ..set(_ref(note).collection('comments').doc(), {
        'ownerId': author.uid,
        'ownerName': author.username,
        'ownerImage': author.image,
        'text': text,
        'time': noteTimestamp(DateTime.now()),
      })
      ..update(_ref(note), {'commentCount': FieldValue.increment(1)});
    await batch.commit();
  }

  Future<void> deleteComment(Note note, Comment comment) async {
    final batch = _db.batch()
      ..delete(_ref(note).collection('comments').doc(comment.id))
      ..update(_ref(note), {'commentCount': FieldValue.increment(-1)});
    await batch.commit();
  }

  /// Flags a note's author for moderation, as the old app did.
  Future<void> report(Note note, String reporterId) => _db
      .collection('reportPostUser')
      .doc(note.ownerId)
      .collection('report')
      .add({'reportUser': reporterId, 'noteId': note.id});
}
