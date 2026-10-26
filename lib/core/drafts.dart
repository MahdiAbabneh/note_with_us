import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'prefs.dart';

/// An unfinished note kept on the device until it is posted or cleared.
@immutable
class Draft {
  const Draft({
    required this.text,
    required this.mood,
    required this.target,
    this.prompt = '',
  });

  factory Draft.fromJson(Map<String, dynamic> json) => Draft(
    text: json['text'] as String? ?? '',
    mood: json['mood'] as String? ?? 'plain',
    target: json['target'] as String? ?? 'private',
    prompt: json['prompt'] as String? ?? '',
  );

  final String text;
  final String mood;
  final String target;
  final String prompt;

  Map<String, dynamic> toJson() => {
    'text': text,
    'mood': mood,
    'target': target,
    'prompt': prompt,
  };
}

/// Device-local draft storage. Drafts never leave the phone, so private
/// writing in progress isn't sent anywhere before the user posts it.
class DraftStore extends ChangeNotifier {
  DraftStore._();

  /// Shared instance.
  static final DraftStore instance = DraftStore._();

  static const _key = 'composeDraft';

  /// The saved draft, if there is one with some text.
  Draft? get current {
    final raw = Prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final draft = Draft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return draft.text.trim().isEmpty ? null : draft;
    } on FormatException {
      return null;
    }
  }

  void save(Draft draft) {
    Prefs.setString(_key, jsonEncode(draft.toJson()));
    notifyListeners();
  }

  void clear() {
    Prefs.setString(_key, '');
    notifyListeners();
  }
}
