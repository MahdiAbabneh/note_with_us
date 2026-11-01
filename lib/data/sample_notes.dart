import '../core/l10n.dart';
import '../design/tokens.dart';
import 'models.dart';

/// Discover shows the example notes until it has this many real ones.
const minRealDiscoverNotes = 8;

/// Example notes for Discover, so a new app doesn't open on an empty
/// feed. They are labelled "Example" on screen, live only in the app (no
/// database, no accounts) and show what kinds of notes people write.
List<Note> sampleNotes() => [
  for (final (i, s) in _samples.indexed)
    Note(
      id: 'example_$i',
      audience: Audience.everyone,
      text: L10n.arabic ? s.ar : s.en,
      images: const [],
      // Kept apart from real notes: examples always go last.
      time: DateTime(2000),
      ownerId: 'example:$i',
      ownerName: L10n.arabic ? s.nameAr : s.nameEn,
      ownerImage: 'emoji:${s.emoji}:${s.color}',
      mood: s.mood,
      example: true,
    ),
];

typedef _Sample = ({
  String nameEn,
  String nameAr,
  String emoji,
  int color,
  Mood mood,
  String en,
  String ar,
});

const List<_Sample> _samples = [
  (
    nameEn: 'Omar',
    nameAr: 'عمر',
    emoji: '🦊',
    color: 2,
    mood: Mood.dreamy,
    en: 'Sunset over the old city tonight. Some evenings just feel like a gift 🌅 #views',
    ar: 'غروب الشمس فوق المدينة القديمة الليلة. بعض الأمسيات هدية 🌅 #مناظر',
  ),
  (
    nameEn: 'Lina',
    nameAr: 'لينا',
    emoji: '🌻',
    color: 3,
    mood: Mood.joy,
    en: 'Passed my driving test on the first try!! 🚗🎉',
    ar: 'نجحت في امتحان السواقة من أول مرة!! 🚗🎉',
  ),
  (
    nameEn: 'Maya',
    nameAr: 'مايا',
    emoji: '🦋',
    color: 5,
    mood: Mood.calm,
    en: 'Rainy morning, warm tea, a good book. Nothing else needed ☕️ #books',
    ar: 'صباح ماطر، شاي دافئ وكتاب جميل. لا أحتاج شيئًا آخر ☕️ #كتب',
  ),
  (
    nameEn: 'Yousef',
    nameAr: 'يوسف',
    emoji: '🐼',
    color: 4,
    mood: Mood.fired,
    en: 'Ran my first 10K today. Legs gone, heart full 🏃‍♂️ #health',
    ar: 'ركضت أول ١٠ كيلومترات اليوم. تعبت لكن قلبي مبسوط 🏃‍♂️ #صحة',
  ),
  (
    nameEn: 'Sara',
    nameAr: 'سارة',
    emoji: '🌸',
    color: 1,
    mood: Mood.love,
    en: 'Dinner with mom tonight. She made my favorite and we talked for hours ❤️ #family',
    ar: 'عشاء مع أمي الليلة. طبخت أكلتي المفضلة وتحدثنا لساعات ❤️ #عائلة',
  ),
  (
    nameEn: 'Kareem',
    nameAr: 'كريم',
    emoji: '🐢',
    color: 0,
    mood: Mood.blue,
    en: 'Long week. Writing it down helps a little. Tomorrow is a new page.',
    ar: 'أسبوع طويل. الكتابة تساعد قليلًا. بكرة صفحة جديدة.',
  ),
  (
    nameEn: 'Noor',
    nameAr: 'نور',
    emoji: '🌙',
    color: 5,
    mood: Mood.dreamy,
    en: 'Sealed a letter to myself for next year. Can’t wait to read it 💌',
    ar: 'ختمت رسالة لنفسي للسنة القادمة. متحمسة أقرأها 💌',
  ),
  (
    nameEn: 'Ahmad',
    nameAr: 'أحمد',
    emoji: '🦁',
    color: 2,
    mood: Mood.calm,
    en: 'Three things I’m grateful for today: coffee, sunshine, and old friends ☀️',
    ar: 'ثلاثة أشياء ممتن لها اليوم: القهوة، الشمس، والأصدقاء القدامى ☀️',
  ),
];
