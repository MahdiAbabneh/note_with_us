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
  }

  /// Shared instance.
  static final AppSettings instance = AppSettings._();

  late ThemeMode _mode;
  late Accent _accent;
  late Backdrop _backdrop;
  late String _lang;

  ThemeMode get mode => _mode;
  Accent get accent => _accent;
  Backdrop get backdrop => _backdrop;
  String get lang => _lang;
  bool get isArabic => _lang == 'ar';
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
