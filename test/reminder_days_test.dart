import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mahdeko/core/prefs.dart';
import 'package:mahdeko/core/reminders.dart';
import 'package:mahdeko/design/theme.dart';
import 'package:mahdeko/design/tokens.dart';
import 'package:mahdeko/features/profile/me_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('reminder day presets update the picker', (tester) async {
    await initializeDateFormatting();
    SharedPreferences.setMockInitialValues({});
    await Prefs.init();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(
          brightness: Brightness.light,
          accent: Accent.values.first,
          arabic: false,
        ),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => pickReminderDays(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weekdays'));
    await tester.pumpAndSettle();
    expect(Reminders.instance.days, {1, 2, 3, 4, 5});
    await tester.tap(find.text('Sun'));
    await tester.pumpAndSettle();
    expect(Reminders.instance.days, {1, 2, 3, 4, 5, 7});
  });
}
