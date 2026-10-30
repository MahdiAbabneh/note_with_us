import 'dart:math';

import 'package:flutter/foundation.dart';

import 'l10n.dart';
import 'prefs.dart';

/// Daily writing prompts, as (English, Arabic) pairs.
const List<(String, String)> _prompts = [
  ('What made you smile today?', 'ما الذي جعلك تبتسم اليوم؟'),
  (
    'Who are you grateful for right now, and why?',
    'لمن أنت ممتن الآن، ولماذا؟',
  ),
  ('Describe today in three words.', 'صف يومك بثلاث كلمات.'),
  (
    'What is a small win you had this week?',
    'ما هو إنجاز صغير حققته هذا الأسبوع؟',
  ),
  ('What song is stuck in your head?', 'ما الأغنية العالقة في رأسك؟'),
  (
    'Write a note to yourself one year from now.',
    'اكتب رسالة لنفسك بعد سنة من الآن.',
  ),
  ('What did you learn today?', 'ماذا تعلمت اليوم؟'),
  (
    'What is something you are looking forward to?',
    'ما الشيء الذي تتطلع إليه؟',
  ),
  ('Share a memory that always makes you laugh.', 'شارك ذكرى تضحكك دائمًا.'),
  ('What would make tomorrow great?', 'ما الذي سيجعل الغد رائعًا؟'),
  ('Who do you miss today?', 'من تفتقد اليوم؟'),
  ('What is the best advice you ever got?', 'ما أفضل نصيحة سمعتها في حياتك؟'),
  ('What place makes you feel at home?', 'أي مكان يشعرك بأنك في بيتك؟'),
  ('What are you proud of lately?', 'ما الذي تفخر به مؤخرًا؟'),
  ('Describe your perfect weekend.', 'صف عطلة نهاية الأسبوع المثالية.'),
  (
    'What is one thing you want to remember about today?',
    'ما الشيء الذي تريد أن تتذكره من اليوم؟',
  ),
  (
    'Tell someone in your circle why they matter.',
    'أخبر أحدًا في دائرتك لماذا هو مهم لك.',
  ),
  (
    'What is a smell that brings back memories?',
    'ما الرائحة التي تعيد إليك الذكريات؟',
  ),
  (
    'What would you tell your younger self?',
    'ماذا ستقول لنفسك عندما كنت أصغر؟',
  ),
  ('What is on your mind before you sleep?', 'ما الذي يشغل بالك قبل النوم؟'),
  (
    'What is a simple pleasure you enjoyed today?',
    'ما المتعة البسيطة التي استمتعت بها اليوم؟',
  ),
  ('What dream do you keep coming back to?', 'ما الحلم الذي تعود إليه دائمًا؟'),
  (
    'Write about a kind thing someone did for you.',
    'اكتب عن معروف قدمه لك أحدهم.',
  ),
  ('What is the last thing that surprised you?', 'ما آخر شيء فاجأك؟'),
  (
    'What are three things you love about yourself?',
    'ما ثلاثة أشياء تحبها في نفسك؟',
  ),
  ('Where do you want to be in five years?', 'أين تريد أن تكون بعد خمس سنوات؟'),
  (
    'What is your favourite thing about this season?',
    'ما أكثر ما تحبه في هذا الفصل؟',
  ),
  ('Describe a person who inspires you.', 'صف شخصًا يلهمك.'),
  (
    'What made today different from yesterday?',
    'ما الذي جعل اليوم مختلفًا عن الأمس؟',
  ),
  ('What is a habit you want to start?', 'ما العادة التي تريد أن تبدأها؟'),
  ('Write a thank-you note you never sent.', 'اكتب رسالة شكر لم ترسلها أبدًا.'),
];

/// Any prompt other than [except], for "Need an idea?".
String randomPrompt({String except = ''}) {
  final random = Random();
  while (true) {
    final (en, ar) = _prompts[random.nextInt(_prompts.length)];
    final prompt = L10n.arabic ? ar : en;
    if (prompt != except) return prompt;
  }
}

/// The prompt for a given day, the same for everyone on that date.
String promptFor(DateTime day) {
  final dayOfYear = day.difference(DateTime(day.year)).inDays;
  final (en, ar) = _prompts[(dayOfYear + day.year) % _prompts.length];
  return L10n.arabic ? ar : en;
}

/// Whether today's prompt was answered or hidden, remembered on this
/// device for the current day only, so tomorrow starts fresh.
class PromptState extends ChangeNotifier {
  PromptState._();

  /// Shared instance.
  static final PromptState instance = PromptState._();

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  bool get answeredToday => Prefs.getString('promptAnswered') == _today();
  bool get hiddenToday => Prefs.getString('promptHidden') == _today();

  /// Today's prompt, in the current language.
  String get today => promptFor(DateTime.now());

  /// Call after posting a note; counts only if it answered today's prompt.
  void noteAnswered(String prompt) {
    if (prompt.isEmpty || prompt != today) return;
    Prefs.setString('promptAnswered', _today());
    notifyListeners();
  }

  void hideForToday() {
    Prefs.setString('promptHidden', _today());
    notifyListeners();
  }
}

/// Whether this stretch's "past you" note was answered or put off,
/// remembered on this device (see `pastSelfWindow`).
class PastSelfState extends ChangeNotifier {
  PastSelfState._();

  /// Shared instance.
  static final PastSelfState instance = PastSelfState._();

  static const _key = 'pastSelfDone';

  bool isDone(int window) => Prefs.getString(_key) == '$window';

  void markDone(int window) {
    Prefs.setString(_key, '$window');
    notifyListeners();
  }
}
