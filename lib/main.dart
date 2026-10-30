import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/prefs.dart';
import 'core/reminders.dart';
import 'core/settings.dart';
import 'data/session.dart';
import 'design/design.dart';
import 'features/auth/profile_form.dart';
import 'features/auth/welcome_screen.dart';
import 'features/shell/home_shell.dart';

/// Development only: `--dart-define=USE_EMULATOR=true` points the app at
/// the local Firebase emulators instead of the live project. Off by
/// default, so normal and store builds always use live Firebase.
const _useEmulator = bool.fromEnvironment('USE_EMULATOR');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  if (_useEmulator) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    // The on-device cache is keyed by project, not host, so emulator data
    // would otherwise linger and hide live notes on the next normal run.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }
  await Prefs.init();
  await initializeDateFormatting();
  await Reminders.instance.init();
  runApp(const NoteWithUsApp());
}

/// Root widget: theme, language and the signed-in/signed-out switch.
class NoteWithUsApp extends StatelessWidget {
  const NoteWithUsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: 'Note With Us',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(
          brightness: Brightness.light,
          accent: settings.accent,
          arabic: settings.isArabic,
          backdrop: settings.backdrop,
          noteFont: settings.noteFont,
          notePaper: settings.notePaper,
        ),
        darkTheme: buildTheme(
          brightness: Brightness.dark,
          accent: settings.accent,
          arabic: settings.isArabic,
          backdrop: settings.backdrop,
          noteFont: settings.noteFont,
          notePaper: settings.notePaper,
        ),
        themeMode: settings.mode,
        locale: settings.locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  final session = Session.instance;
  late SessionStatus _last = session.status;

  @override
  void initState() {
    super.initState();
    session.addListener(_onSession);
  }

  @override
  void dispose() {
    session.removeListener(_onSession);
    super.dispose();
  }

  /// A guest who signs in from a sheet or pushed screen lands on the
  /// fresh home, not on top of what they had open.
  void _onSession() {
    if (_last == SessionStatus.guest && session.status != _last) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
    _last = session.status;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final screen = switch (session.status) {
          SessionStatus.loading => const _Splash(),
          SessionStatus.signedOut => const WelcomeScreen(),
          SessionStatus.needsProfile => const CompleteProfileScreen(),
          SessionStatus.guest || SessionStatus.ready => const HomeShell(),
        };
        return AnimatedSwitcher(
          duration: Motion.slow,
          switchInCurve: Motion.ease,
          child: KeyedSubtree(key: ValueKey(session.status), child: screen),
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✦', style: TextStyle(fontSize: 40, color: c.accent))
                .animate(onPlay: (ctl) => ctl.repeat(reverse: true))
                .scaleXY(end: 1.15, duration: 700.ms, curve: Curves.easeInOut),
            const SizedBox(height: Space.md),
            Text('Note With Us', style: context.text.title),
          ],
        ),
      ),
    );
  }
}
