import 'package:cloud_firestore/cloud_firestore.dart';

import 'models.dart';

/// Direct messages stored under `users/{uid}/chats/{otherUid}/messages`,
/// mirrored on both sides as in the original app.
class ChatRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _thread(String owner, String other) =>
      _db.collection('users').doc(owner).collection('chats').doc(other);

  /// Conversations of [uid], most recent first.
  Stream<List<ChatThread>> threads(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('chats')
      .snapshots()
      .map(
        (s) => s.docs.map(ChatThread.fromDoc).toList()
          ..sort(
            (a, b) => (b.lastTime ?? DateTime(2000)).compareTo(
              a.lastTime ?? DateTime(2000),
            ),
          ),
      );

  /// Messages between [me] and [other], newest first.
  Stream<List<Message>> messages(String me, String other) => _thread(me, other)
      .collection('messages')
      .orderBy('time', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Message.fromDoc).toList());

  Future<void> send(AppUser me, AppUser other, String text) async {
    final now = DateTime.now().toString();
    final message = {
      'senderId': me.uid,
      'receiverId': other.uid,
      'message': text,
      'time': now,
    };
    final batch = _db.batch()
      ..set(_thread(me.uid, other.uid), {
        'userId': other.uid,
        'username': other.username,
        'userImage': other.image,
        'lastMessage': text,
        'lastTime': now,
      }, SetOptions(merge: true))
      ..set(_thread(other.uid, me.uid), {
        'userId': me.uid,
        'username': me.username,
        'userImage': me.image,
        'lastMessage': text,
        'lastTime': now,
      }, SetOptions(merge: true))
      ..set(_thread(me.uid, other.uid).collection('messages').doc(), message)
      ..set(_thread(other.uid, me.uid).collection('messages').doc(), message);
    await batch.commit();
  }
}
