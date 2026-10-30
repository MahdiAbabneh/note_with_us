import 'package:cloud_firestore/cloud_firestore.dart';

import '../design/tokens.dart';
import 'models.dart';

/// Time capsules live in a top-level `capsules` collection.
///
/// The capsule document only says who, when and which mood. Its text is
/// kept in `capsules/{id}/sealed/content`, which the security rules let
/// the recipient read only once the capsule has unlocked.
class CapsulesRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _capsules =>
      _db.collection('capsules');

  DocumentReference<Map<String, dynamic>> _sealed(String id) =>
      _capsules.doc(id).collection('sealed').doc('content');

  List<Capsule> _parse(QuerySnapshot<Map<String, dynamic>> s) =>
      s.docs.map(Capsule.fromDoc).toList()
        ..sort((a, b) => a.unlockAt.compareTo(b.unlockAt));

  /// Capsules addressed to [uid], including ones they sent themselves.
  Stream<List<Capsule>> received(String uid) =>
      _capsules.where('recipientId', isEqualTo: uid).snapshots().map(_parse);

  /// Capsules [uid] sent to other people.
  Stream<List<Capsule>> sent(String uid) => _capsules
      .where('ownerId', isEqualTo: uid)
      .snapshots()
      .map((s) => _parse(s).where((c) => !c.isToSelf).toList());

  Future<void> create({
    required AppUser author,
    required AppUser recipient,
    required String text,
    required Mood mood,
    required DateTime unlockAt,
    String kind = '',
  }) async {
    final ref = _capsules.doc();
    final batch = _db.batch()
      ..set(ref, {
        'ownerId': author.uid,
        'ownerName': author.username,
        'ownerImage': author.image,
        'recipientId': recipient.uid,
        'recipientName': recipient.username,
        'text': '',
        'mood': mood.id,
        'createdAt': Timestamp.now(),
        'unlockAt': Timestamp.fromDate(unlockAt),
        'opened': false,
        if (kind.isNotEmpty) 'kind': kind,
      })
      ..set(_sealed(ref.id), {'text': text});
    await batch.commit();
  }

  /// The capsule's text; only readable once unlocked (or by its author).
  Future<String> readText(Capsule capsule) async {
    if (capsule.text.isNotEmpty) return capsule.text;
    final doc = await _sealed(capsule.id).get();
    return doc.data()?['text'] as String? ?? '';
  }

  /// Marks the capsule opened and caches its text for previews.
  Future<void> markOpened(Capsule capsule, String text) =>
      _capsules.doc(capsule.id).update({'opened': true, 'text': text});

  Future<void> delete(Capsule capsule) async {
    final batch = _db.batch()
      ..delete(_sealed(capsule.id))
      ..delete(_capsules.doc(capsule.id));
    await batch.commit();
  }
}
