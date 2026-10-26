import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'l10n.dart';
import 'prefs.dart';

/// Where a tapped notification should take the user.
enum ReminderTarget { write, capsules }

/// Optional, on-device notifications: a daily writing reminder and an
/// alert when a received time capsule unlocks.
///
/// Everything is scheduled locally, so no note or capsule text is ever
/// sent to a push service, and notification bodies never contain it.
class Reminders extends ChangeNotifier {
  Reminders._();

  /// Shared instance.
  static final Reminders instance = Reminders._();

  static const _dailyId = 1;

  /// One repeating notification per chosen weekday (Monday = 1).
  static int _weekdayId(int weekday) => 10 + weekday;
  static const _capsuleIdsKey = 'capsuleNotificationIds';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Set when the user taps a notification; the home shell routes it.
  final ValueNotifier<ReminderTarget?> openRequest = ValueNotifier(null);

  bool get dailyEnabled => Prefs.getBool('reminderOn') ?? false;
  bool get capsuleAlerts => Prefs.getBool('capsuleAlerts') ?? true;

  TimeOfDay get time {
    final parts = (Prefs.getString('reminderTime') ?? '20:30').split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 20,
      minute: int.tryParse(parts.last) ?? 30,
    );
  }

  /// Sets up time zones and the plugin; safe to call before `runApp`.
  Future<void> init() async {
    try {
      tz_data.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (r) => _route(r.payload),
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _route(launch!.notificationResponse?.payload);
      }
      _ready = true;
    } catch (error, stack) {
      developer.log(
        'Reminders unavailable',
        name: 'note_with_us.reminders',
        error: error,
        stackTrace: stack,
      );
    }
  }

  void _route(String? payload) {
    openRequest.value = ReminderTarget.values
        .where((t) => t.name == payload)
        .firstOrNull;
  }

  /// Asks the OS for permission; returns whether notifications may show.
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: false,
            sound: true,
          ) ??
          false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? true;
  }

  /// Turns the daily reminder on or off. Returns false if permission was
  /// refused, leaving it off.
  Future<bool> setDaily(bool on) async {
    if (on && !await requestPermission()) return false;
    await Prefs.setBool('reminderOn', on);
    await _rescheduleDaily();
    notifyListeners();
    return true;
  }

  /// Days the reminder may come (1 = Monday … 7 = Sunday); all by default.
  Set<int> get days {
    final raw = Prefs.getString('reminderDays');
    if (raw == null || raw.isEmpty) return {1, 2, 3, 4, 5, 6, 7};
    final parsed = raw.split(',').map(int.tryParse).whereType<int>().toSet();
    return parsed.isEmpty ? {1, 2, 3, 4, 5, 6, 7} : parsed;
  }

  /// Saves the chosen days; at least one day must stay selected.
  Future<void> setDays(Set<int> value) async {
    if (value.isEmpty) return;
    await Prefs.setString('reminderDays', (value.toList()..sort()).join(','));
    await _rescheduleDaily();
    notifyListeners();
  }

  Future<void> setTime(TimeOfDay value) async {
    await Prefs.setString('reminderTime', '${value.hour}:${value.minute}');
    await _rescheduleDaily();
    notifyListeners();
  }

  Future<void> setCapsuleAlerts(bool on) async {
    if (on && !await requestPermission()) return;
    await Prefs.setBool('capsuleAlerts', on);
    if (!on) await clearCapsuleAlerts();
    notifyListeners();
  }

  /// Re-applies the daily reminder, e.g. after a language change.
  Future<void> refresh() => _rescheduleDaily();

  Future<void> _rescheduleDaily() async {
    if (!_ready) return;
    await _plugin.cancel(id: _dailyId);
    for (var d = 1; d <= 7; d++) {
      await _plugin.cancel(id: _weekdayId(d));
    }
    if (!dailyEnabled) return;
    final chosen = days;
    final everyDay = chosen.length == 7;
    final now = tz.TZDateTime.now(tz.local);
    // Every day: one daily notification. Otherwise one weekly
    // notification per chosen weekday.
    for (final weekday in everyDay ? [0] : chosen) {
      var next = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      while (!next.isAfter(now) || (!everyDay && next.weekday != weekday)) {
        next = next.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        id: everyDay ? _dailyId : _weekdayId(weekday),
        scheduledDate: next,
        title: 'Your moment today'.tr,
        body: 'Take a minute to write how today felt.'.tr,
        payload: ReminderTarget.write.name,
        notificationDetails: _details('daily', 'Daily writing reminder'.tr),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: everyDay
            ? DateTimeComponents.time
            : DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  /// Schedules an alert for each received, still-locked capsule and
  /// cancels alerts for capsules that no longer exist.
  Future<void> syncCapsules(
    List<({String id, DateTime unlockAt, String from})> capsules,
  ) async {
    if (!_ready || !capsuleAlerts) return;
    final previous = _scheduledCapsuleIds();
    final now = DateTime.now();
    final wanted = <int, ({String id, DateTime unlockAt, String from})>{
      for (final c in capsules.where((c) => c.unlockAt.isAfter(now)))
        _capsuleNotificationId(c.id): c,
    };
    for (final id in previous.difference(wanted.keys.toSet())) {
      await _plugin.cancel(id: id);
    }
    for (final MapEntry(key: id, value: c) in wanted.entries) {
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: tz.TZDateTime.from(c.unlockAt, tz.local),
        title: 'A time capsule is ready to open'.tr,
        body: c.from.isEmpty
            ? 'A note from your past self is waiting.'.tr
            : 'From {name}'.tr.replaceAll('{name}', c.from),
        payload: ReminderTarget.capsules.name,
        notificationDetails: _details('capsules', 'Time capsules'.tr),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
    await Prefs.setString(_capsuleIdsKey, jsonEncode(wanted.keys.toList()));
  }

  /// Removes all capsule alerts, e.g. on sign-out.
  Future<void> clearCapsuleAlerts() async {
    if (!_ready) return;
    for (final id in _scheduledCapsuleIds()) {
      await _plugin.cancel(id: id);
    }
    await Prefs.setString(_capsuleIdsKey, '[]');
  }

  Set<int> _scheduledCapsuleIds() {
    try {
      return {
        ...(jsonDecode(Prefs.getString(_capsuleIdsKey) ?? '[]') as List)
            .cast<int>(),
      };
    } on FormatException {
      return {};
    }
  }

  // Stable per capsule and clear of the daily reminder's id.
  int _capsuleNotificationId(String capsuleId) =>
      1000 + (capsuleId.hashCode & 0x0FFFFFFF);

  NotificationDetails _details(String channel, String name) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          name,
          importance: Importance.defaultImportance,
        ),
        iOS: const DarwinNotificationDetails(),
      );
}
