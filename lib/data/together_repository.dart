import 'package:cloud_firestore/cloud_firestore.dart';

import '../design/tokens.dart';
import 'models.dart';

/// Capsules the whole circle writes to and opens together.
///
/// `groupCapsules/{id}` holds who, when and who has written so far. Each
/// letter lives in `entries/{uid}`; the security rules let the others
/// read it only after `unlockAt`.
class GroupCapsulesRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _capsules =>
      _db.collection('groupCapsules');

  DocumentReference<Map<String, dynamic>> _entry(String id, String uid) =>
      _capsules.doc(id).collection('entries').doc(uid);

  /// Capsules [uid] takes part in, soonest to open first.
  Stream<List<GroupCapsule>> mine(String uid) => _capsules
      .where('members', arrayContains: uid)
      .snapshots()
      .map(
        (s) =>
            s.docs.map(GroupCapsule.fromDoc).toList()
              ..sort((a, b) => a.unlockAt.compareTo(b.unlockAt)),
      );

  /// Live copy of one capsule, for the "who has written" ticks.
  Stream<GroupCapsule?> watch(String id) => _capsules
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? GroupCapsule.fromDoc(d) : null);

  Future<void> create({
    required AppUser author,
    required String title,
    required DateTime unlockAt,
    required Iterable<String> circle,
  }) => _capsules.add({
    'ownerId': author.uid,
    'ownerName': author.username,
    'title': title,
    'createdAt': Timestamp.now(),
    'unlockAt': Timestamp.fromDate(unlockAt),
    'members': {author.uid, ...circle}.toList(),
    'written': <String>[],
  });

  /// Your own letter, if you wrote one already.
  Future<GroupEntry?> myEntry(String id, String uid) async {
    final doc = await _entry(id, uid).get();
    return doc.exists ? GroupEntry.fromDoc(doc) : null;
  }

  /// Saves (or rewrites) your letter and ticks you off as written.
  Future<void> saveEntry({
    required GroupCapsule capsule,
    required AppUser author,
    required String text,
    required Mood mood,
  }) {
    final batch = _db.batch()
      ..set(_entry(capsule.id, author.uid), {
        'ownerId': author.uid,
        'ownerName': author.username,
        'ownerImage': author.image,
        'text': text,
        'mood': mood.id,
        'time': Timestamp.now(),
      });
    if (!capsule.hasWritten(author.uid)) {
      batch.update(_capsules.doc(capsule.id), {
        'written': FieldValue.arrayUnion([author.uid]),
      });
    }
    return batch.commit();
  }

  /// Everyone's letters; readable only once the capsule has unlocked.
  Future<List<GroupEntry>> entries(String id) async {
    final snap = await _capsules.doc(id).collection('entries').get();
    return snap.docs.map(GroupEntry.fromDoc).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  /// Deletes the capsule and every member's letter. The letters are
  /// deleted by id (one per member) rather than listed, because until the
  /// capsule opens the rules let nobody list other people's letters, not
  /// even the creator.
  Future<void> delete(GroupCapsule capsule) async {
    final batch = _db.batch();
    for (final member in capsule.members) {
      batch.delete(_entry(capsule.id, member));
    }
    batch.delete(_capsules.doc(capsule.id));
    await batch.commit();
  }
}

/// Notebooks two people write in, taking turns.
///
/// `sharedNotebooks/{id}` records whose turn it is; pages live in
/// `entries`. The rules only accept a page from the person whose turn it
/// is, and the page and the turn change are written together.
class NotebooksRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _notebooks =>
      _db.collection('sharedNotebooks');

  CollectionReference<Map<String, dynamic>> _entries(String id) =>
      _notebooks.doc(id).collection('entries');

  /// Notebooks [uid] shares with someone, most recently written first.
  Stream<List<SharedNotebook>> mine(String uid) => _notebooks
      .where('members', arrayContains: uid)
      .snapshots()
      .map(
        (s) => s.docs.map(SharedNotebook.fromDoc).toList()
          ..sort(
            (a, b) => (b.lastTime ?? b.createdAt).compareTo(
              a.lastTime ?? a.createdAt,
            ),
          ),
      );

  Stream<SharedNotebook?> watch(String id) => _notebooks
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? SharedNotebook.fromDoc(d) : null);

  /// Pages, oldest first.
  Stream<List<NotebookEntry>> entries(String id) => _entries(id)
      .orderBy('time')
      .snapshots()
      .map((s) => s.docs.map(NotebookEntry.fromDoc).toList());

  /// Starts a notebook and returns its id.
  Future<String> create({
    required AppUser author,
    required AppUser other,
    required String title,
  }) async {
    final ref = await _notebooks.add({
      'ownerId': author.uid,
      'title': title,
      'members': [author.uid, other.uid],
      'memberNames': {author.uid: author.username, other.uid: other.username},
      'createdAt': Timestamp.now(),
      'lastWriterId': '',
      'entryCount': 0,
    });
    return ref.id;
  }

  /// Adds a page and passes the turn, in one batch.
  Future<void> addEntry({
    required SharedNotebook notebook,
    required AppUser author,
    required String text,
  }) {
    final now = Timestamp.now();
    final batch = _db.batch()
      ..set(_entries(notebook.id).doc(), {
        'ownerId': author.uid,
        'ownerName': author.username,
        'text': text,
        'time': now,
      })
      ..update(_notebooks.doc(notebook.id), {
        'lastWriterId': author.uid,
        'lastTime': now,
        'entryCount': FieldValue.increment(1),
      });
    return batch.commit();
  }

  Future<void> delete(SharedNotebook notebook) async {
    final pages = await _entries(notebook.id).get();
    final batch = _db.batch();
    for (final doc in pages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_notebooks.doc(notebook.id));
    await batch.commit();
  }
}

/// Questions to some of your circle, with private answers.
///
/// `circleAsks/{id}` holds the question and who has answered; each
/// answer is `answers/{uid}`, readable only by its writer and by whoever
/// asked.
class AsksRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _asks =>
      _db.collection('circleAsks');

  DocumentReference<Map<String, dynamic>> _answer(String id, String uid) =>
      _asks.doc(id).collection('answers').doc(uid);

  List<CircleAsk> _parse(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map(CircleAsk.fromDoc).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Questions [uid] asked, newest first.
  Stream<List<CircleAsk>> asked(String uid) =>
      _asks.where('ownerId', isEqualTo: uid).snapshots().map(_parse);

  /// Questions asked of [uid], newest first.
  Stream<List<CircleAsk>> forMe(String uid) =>
      _asks.where('members', arrayContains: uid).snapshots().map(_parse);

  Stream<CircleAsk?> watch(String id) => _asks
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? CircleAsk.fromDoc(d) : null);

  Future<void> create({
    required AppUser author,
    required String text,
    required Iterable<String> members,
  }) => _asks.add({
    'ownerId': author.uid,
    'ownerName': author.username,
    'text': text,
    'createdAt': Timestamp.now(),
    'members': members.toList(),
    'answered': <String>[],
  });

  /// Your own answer, if you gave one.
  Future<AskAnswer?> myAnswer(String id, String uid) async {
    final doc = await _answer(id, uid).get();
    return doc.exists ? AskAnswer.fromDoc(doc) : null;
  }

  /// Saves (or rewrites) your answer and ticks you off as answered.
  Future<void> saveAnswer({
    required CircleAsk ask,
    required AppUser author,
    required String text,
  }) {
    final batch = _db.batch()
      ..set(_answer(ask.id, author.uid), {
        'ownerId': author.uid,
        'ownerName': author.username,
        'ownerImage': author.image,
        'text': text,
        'time': Timestamp.now(),
      });
    if (!ask.hasAnswered(author.uid)) {
      batch.update(_asks.doc(ask.id), {
        'answered': FieldValue.arrayUnion([author.uid]),
      });
    }
    return batch.commit();
  }

  /// Everyone's answers; only the person who asked may read them.
  Future<List<AskAnswer>> answers(String id) async {
    final snap = await _asks.doc(id).collection('answers').get();
    return snap.docs.map(AskAnswer.fromDoc).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  Future<void> delete(CircleAsk ask) async {
    final answers = await _asks.doc(ask.id).collection('answers').get();
    final batch = _db.batch();
    for (final doc in answers.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_asks.doc(ask.id));
    await batch.commit();
  }
}
