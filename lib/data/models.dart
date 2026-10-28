import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/format.dart';
import '../design/tokens.dart';

DateTime _parseTime(dynamic raw) {
  if (raw is Timestamp) return raw.toDate();
  if (raw is String) {
    return DateTime.tryParse(raw.replaceAll('Z', '')) ?? DateTime(2023);
  }
  return DateTime(2023);
}

/// The reactions people can leave on a note.
const List<String> reactionEmojis = ['❤️', '😂', '🥹', '😮', '🔥', '👏'];

/// A person using the app; mirrors `users/{uid}`.
class AppUser {
  const AppUser({
    required this.uid,
    required this.username,
    this.email = '',
    this.image = '',
    this.phoneNumber = '',
    this.dateOfBirth = '',
    this.gender = '',
    this.location = '',
    this.bio = '',
    this.theme = 'origin',
  });

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    uid: map['uId'] as String? ?? '',
    username: map['username'] as String? ?? '',
    email: map['email'] as String? ?? '',
    image: map['image'] as String? ?? '',
    phoneNumber: map['phoneNumber'] as String? ?? '',
    dateOfBirth: map['dateOfBirth'] as String? ?? '',
    gender: map['gender'] as String? ?? '',
    location: map['location'] as String? ?? '',
    bio: map['bio'] as String? ?? '',
    theme: map['theme'] as String? ?? 'origin',
  );

  final String uid;
  final String username;
  final String email;
  final String image;
  final String phoneNumber;
  final String dateOfBirth;
  final String gender;
  final String location;
  final String bio;
  final String theme;

  int? get age => ageFrom(parseBirthDate(dateOfBirth));

  String get firstName => username.split(' ').first;
}

/// Who can see a note, which also decides the collection it lives in.
enum Audience {
  /// `postsOnlyMe/{uid}/myPost` — the private journal.
  private,

  /// `circlePosts` — visible to the author's circle.
  circle,

  /// `postsMain` — the public feed.
  everyone,
}

/// A note in any of the three collections.
class Note {
  const Note({
    required this.id,
    required this.audience,
    required this.text,
    required this.images,
    required this.time,
    required this.ownerId,
    required this.ownerName,
    required this.ownerImage,
    this.reactions = const {},
    this.legacyLikes = const {},
    this.mood = Mood.plain,
    this.prompt = '',
    this.promptDay = '',
    this.commentCount = 0,
    this.pinned = false,
    this.archived = false,
    this.comfort = false,
    this.fromOldApp = false,
  });

  factory Note.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    Audience audience,
  ) {
    final map = doc.data() ?? const {};
    final likes = (map['likes'] as List? ?? const [])
        .whereType<Map>()
        .map((l) => l['ownerId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    return Note(
      id: doc.id,
      audience: audience,
      text: map['text'] as String? ?? '',
      images: (map['image'] as List? ?? const []).map((e) => '$e').toList(),
      time: _parseTime(map['time']),
      ownerId: map['ownerId'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      ownerImage: map['ownerImage'] as String? ?? '',
      reactions: Map<String, String>.from(map['reactions'] as Map? ?? {}),
      legacyLikes: likes,
      mood: Mood.fromId(map['mood'] as String?),
      prompt: map['prompt'] as String? ?? '',
      promptDay: map['promptDay'] as String? ?? '',
      commentCount: (map['commentCount'] as num?)?.toInt() ?? 0,
      pinned: map['pinned'] as bool? ?? false,
      archived: map['archived'] as bool? ?? false,
      comfort: map['comfort'] as bool? ?? false,
      // The redesigned app always saves a mood, even "plain".
      fromOldApp: !map.containsKey('mood'),
    );
  }

  final String id;
  final Audience audience;
  final String text;
  final List<String> images;
  final DateTime time;
  final String ownerId;
  final String ownerName;
  final String ownerImage;

  /// `uid -> emoji`.
  final Map<String, String> reactions;

  /// People who liked the note in the old version; counted as ❤️.
  final Set<String> legacyLikes;
  final Mood mood;
  final String prompt;

  /// [dayKey] of the day this note answered the daily question, so a
  /// circle can answer the same one whatever language each person uses.
  final String promptDay;
  final int commentCount;

  /// Pinned to the top of the owner's journal (private notes only).
  final bool pinned;

  /// Hidden from the owner's journal without being deleted (private only).
  final bool archived;

  /// Kept in the owner's comfort box to read on a hard day (private only).
  final bool comfort;

  /// Written by the old app, before notes had a feeling. Kept in the
  /// database, but left out of public lists.
  final bool fromOldApp;

  /// Identifies this note across its three collections; used as the id
  /// of a saved favorite.
  String get key => '${audience.name}_${ownerId}_$id';

  /// What picks this note's paper colour when it has no mood.
  String get colorSeed => id.isEmpty ? ownerId : id;

  /// The emoji [uid] reacted with, if any.
  String? reactionOf(String uid) =>
      reactions[uid] ?? (legacyLikes.contains(uid) ? '❤️' : null);

  /// Emoji counts, most popular first.
  List<MapEntry<String, int>> get reactionCounts {
    final counts = <String, int>{};
    for (final emoji in reactions.values) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    final oldOnly = legacyLikes.where((id) => !reactions.containsKey(id));
    if (oldOnly.isNotEmpty) counts['❤️'] = (counts['❤️'] ?? 0) + oldOnly.length;
    return counts.entries.toList()..sort((a, b) => b.value - a.value);
  }

  int get reactionTotal =>
      reactionCounts.fold(0, (total, entry) => total + entry.value);
}

/// A comment under a note.
class Comment {
  const Comment({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerImage,
    required this.text,
    required this.time,
  });

  factory Comment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? const {};
    return Comment(
      id: doc.id,
      ownerId: map['ownerId'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      ownerImage: map['ownerImage'] as String? ?? '',
      text: map['text'] as String? ?? '',
      time: _parseTime(map['time']),
    );
  }

  final String id;
  final String ownerId;
  final String ownerName;
  final String ownerImage;
  final String text;
  final DateTime time;
}

/// [Capsule.kind] of a surprise note that arrives the next morning.
const morningKind = 'morning';

/// A note sealed until [unlockAt].
class Capsule {
  const Capsule({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerImage,
    required this.recipientId,
    required this.recipientName,
    required this.text,
    required this.mood,
    required this.createdAt,
    required this.unlockAt,
    required this.opened,
    this.kind = '',
  });

  factory Capsule.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? const {};
    return Capsule(
      id: doc.id,
      ownerId: map['ownerId'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      ownerImage: map['ownerImage'] as String? ?? '',
      recipientId: map['recipientId'] as String? ?? '',
      recipientName: map['recipientName'] as String? ?? '',
      text: map['text'] as String? ?? '',
      mood: Mood.fromId(map['mood'] as String?),
      createdAt: _parseTime(map['createdAt']),
      unlockAt: _parseTime(map['unlockAt']),
      opened: map['opened'] as bool? ?? false,
      kind: map['kind'] as String? ?? '',
    );
  }

  final String id;
  final String ownerId;
  final String ownerName;
  final String ownerImage;
  final String recipientId;
  final String recipientName;
  final String text;
  final Mood mood;
  final DateTime createdAt;
  final DateTime unlockAt;
  final bool opened;

  /// `morning` for a surprise note from a friend, empty for a normal capsule.
  final String kind;

  bool get isMorningNote => kind == morningKind;

  /// A morning note from someone else stays out of sight until it
  /// arrives, so it is still a surprise.
  bool isSurpriseFor(String uid) =>
      isMorningNote && recipientId == uid && ownerId != uid && !isUnlocked;

  bool get isUnlocked => !DateTime.now().isBefore(unlockAt);
  bool get isToSelf => ownerId == recipientId;
}

/// A conversation entry in `users/{uid}/chats`.
class ChatThread {
  const ChatThread({
    required this.userId,
    required this.username,
    required this.userImage,
    this.lastMessage = '',
    this.lastTime,
  });

  factory ChatThread.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? const {};
    return ChatThread(
      userId: map['userId'] as String? ?? doc.id,
      username: map['username'] as String? ?? '',
      userImage: map['userImage'] as String? ?? '',
      lastMessage: map['lastMessage'] as String? ?? '',
      lastTime: map['lastTime'] == null ? null : _parseTime(map['lastTime']),
    );
  }

  final String userId;
  final String username;
  final String userImage;
  final String lastMessage;
  final DateTime? lastTime;
}

/// A single chat message.
class Message {
  const Message({
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.time,
  });

  factory Message.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? const {};
    return Message(
      senderId: map['senderId'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      text: map['message'] as String? ?? '',
      time: _parseTime(map['time']),
    );
  }

  final String senderId;
  final String receiverId;
  final String text;
  final DateTime time;
}

/// An invitation to join each other's circles; stored as
/// `circleRequests/{from}_{to}` until accepted, declined or cancelled.
class CircleRequest {
  const CircleRequest({
    required this.from,
    required this.to,
    required this.fromName,
    required this.fromImage,
    required this.createdAt,
  });

  factory CircleRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? const {};
    return CircleRequest(
      from: map['from'] as String? ?? '',
      to: map['to'] as String? ?? '',
      fromName: map['fromName'] as String? ?? '',
      fromImage: map['fromImage'] as String? ?? '',
      createdAt: _parseTime(map['createdAt']),
    );
  }

  final String from;
  final String to;
  final String fromName;
  final String fromImage;
  final DateTime createdAt;
}

/// A note someone saved to their favorites; points at the original note.
class FavoriteRef {
  const FavoriteRef({
    required this.audience,
    required this.ownerId,
    required this.noteId,
    required this.savedAt,
  });

  factory FavoriteRef.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? const {};
    return FavoriteRef(
      audience: Audience.values.firstWhere(
        (a) => a.name == map['audience'],
        orElse: () => Audience.everyone,
      ),
      ownerId: map['ownerId'] as String? ?? '',
      noteId: map['noteId'] as String? ?? '',
      savedAt: _parseTime(map['savedAt']),
    );
  }

  final Audience audience;
  final String ownerId;
  final String noteId;
  final DateTime savedAt;

  String get key => '${audience.name}_${ownerId}_$noteId';
}

/// A capsule the whole circle writes to, opened together on [unlockAt].
/// Each person's letter stays in `entries/{uid}` and is readable by the
/// others only after it unlocks.
class GroupCapsule {
  const GroupCapsule({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.createdAt,
    required this.unlockAt,
    required this.members,
    required this.written,
  });

  factory GroupCapsule.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? const {};
    return GroupCapsule(
      id: doc.id,
      ownerId: map['ownerId'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      createdAt: _parseTime(map['createdAt']),
      unlockAt: _parseTime(map['unlockAt']),
      members: (map['members'] as List? ?? const []).cast<String>(),
      written: {...(map['written'] as List? ?? const []).cast<String>()},
    );
  }

  final String id;
  final String ownerId;
  final String ownerName;
  final String title;
  final DateTime createdAt;
  final DateTime unlockAt;

  /// Everyone taking part, the creator included.
  final List<String> members;

  /// Who has already written their letter.
  final Set<String> written;

  bool get isUnlocked => !DateTime.now().isBefore(unlockAt);
  bool hasWritten(String uid) => written.contains(uid);
}

/// One person's letter in a [GroupCapsule].
class GroupEntry {
  const GroupEntry({
    required this.ownerId,
    required this.ownerName,
    required this.ownerImage,
    required this.text,
    required this.mood,
    required this.time,
  });

  factory GroupEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? const {};
    return GroupEntry(
      ownerId: map['ownerId'] as String? ?? doc.id,
      ownerName: map['ownerName'] as String? ?? '',
      ownerImage: map['ownerImage'] as String? ?? '',
      text: map['text'] as String? ?? '',
      mood: Mood.fromId(map['mood'] as String?),
      time: _parseTime(map['time']),
    );
  }

  final String ownerId;
  final String ownerName;
  final String ownerImage;
  final String text;
  final Mood mood;
  final DateTime time;
}

/// A notebook two people write in, taking turns.
class SharedNotebook {
  const SharedNotebook({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.members,
    required this.memberNames,
    required this.createdAt,
    this.lastWriterId = '',
    this.lastTime,
    this.entryCount = 0,
  });

  factory SharedNotebook.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? const {};
    return SharedNotebook(
      id: doc.id,
      ownerId: map['ownerId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      members: (map['members'] as List? ?? const []).cast<String>(),
      memberNames: Map<String, String>.from(map['memberNames'] as Map? ?? {}),
      createdAt: _parseTime(map['createdAt']),
      lastWriterId: map['lastWriterId'] as String? ?? '',
      lastTime: map['lastTime'] == null ? null : _parseTime(map['lastTime']),
      entryCount: (map['entryCount'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String ownerId;
  final String title;
  final List<String> members;

  /// `uid -> name` as it was when the notebook was made.
  final Map<String, String> memberNames;
  final DateTime createdAt;

  /// Who wrote the last page; empty before the first one.
  final String lastWriterId;
  final DateTime? lastTime;
  final int entryCount;

  /// The other person in the notebook.
  String otherId(String uid) =>
      members.firstWhere((m) => m != uid, orElse: () => uid);

  /// Pages alternate: you may write unless you wrote the last one.
  bool isMyTurn(String uid) => lastWriterId != uid;
}

/// One page of a [SharedNotebook].
class NotebookEntry {
  const NotebookEntry({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.text,
    required this.time,
  });

  factory NotebookEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? const {};
    return NotebookEntry(
      id: doc.id,
      ownerId: map['ownerId'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      text: map['text'] as String? ?? '',
      time: _parseTime(map['time']),
    );
  }

  final String id;
  final String ownerId;
  final String ownerName;
  final String text;
  final DateTime time;
}
