import 'package:flutter/material.dart';

import '../design/tokens.dart';
import 'l10n.dart';
import 'prefs.dart';
import 'reminders.dart';

/// Device-level appearance and language settings.
///
/// Keys match the ones the previous version of the app stored, so people
/// who update keep their language and dark-mode choice.
class AppSettings extends ChangeNotifier {
  AppSettings._() {
    final storedMode = Prefs.getString('themeMode');
    _mode = switch (storedMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ =>
        Prefs.getBool('darkMood') == true ? ThemeMode.dark : ThemeMode.system,
    };
    _accent = Accent.fromId(Prefs.getString('theme'));
    _backdrop = Backdrop.fromId(Prefs.getString('backdrop'));
    final lang =
        Prefs.getString('lang') ??
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    _lang = lang == 'ar' ? 'ar' : 'en';
    L10n.arabic = _lang == 'ar';
    // Hijri dates start on for Arabic, off for English, until chosen.
    _hijri = Prefs.getBool('hijri') ?? _lang == 'ar';
    _islamic = Prefs.getBool('islamic') ?? _lang == 'ar';
    _hijriOffset = (int.tryParse(Prefs.getString('hijriOffset') ?? '') ?? 0)
        .clamp(-2, 2);
  }

  /// Shared instance.
  static final AppSettings instance = AppSettings._();

  late ThemeMode _mode;
  late Accent _accent;
  late Backdrop _backdrop;
  late String _lang;
  late bool _hijri;
  late bool _islamic;
  late int _hijriOffset;

  ThemeMode get mode => _mode;
  Accent get accent => _accent;
  Backdrop get backdrop => _backdrop;
  String get lang => _lang;
  bool get isArabic => _lang == 'ar';

  /// Whether Hijri dates are shown next to the usual ones.
  bool get hijri => _hijri;

  /// Whether Ramadan and Eid features (daily prompts, greetings, Eid
  /// capsule dates) are shown.
  bool get islamic => _islamic;

  /// Days to add before converting to Hijri, for countries that start
  /// the month earlier or later than the Umm al-Qura calendar (-2…2).
  int get hijriOffset => _hijriOffset;
  Locale get locale => Locale(_lang);

  void setMode(ThemeMode mode) {
    _mode = mode;
    Prefs.setString('themeMode', mode.name);
    Prefs.setBool('darkMood', mode == ThemeMode.dark);
    notifyListeners();
  }

  void setAccent(Accent accent) {
    _accent = accent;
    Prefs.setString('theme', accent.id);
    notifyListeners();
  }

  void setBackdrop(Backdrop backdrop) {
    _backdrop = backdrop;
    Prefs.setString('backdrop', backdrop.id);
    notifyListeners();
  }

  void setHijri(bool on) {
    _hijri = on;
    Prefs.setBool('hijri', on);
    notifyListeners();
  }

  void setIslamic(bool on) {
    _islamic = on;
    Prefs.setBool('islamic', on);
    notifyListeners();
  }

  void setHijriOffset(int days) {
    _hijriOffset = days.clamp(-2, 2);
    Prefs.setString('hijriOffset', '$_hijriOffset');
    notifyListeners();
  }

  void setLang(String lang) {
    _lang = lang;
    L10n.arabic = lang == 'ar';
    Prefs.setString('lang', lang);
    notifyListeners();
    // The reminder text is fixed when scheduled; re-schedule in the new
    // language.
    Reminders.instance.refresh();
  }
}
