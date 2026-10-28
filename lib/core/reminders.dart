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

/// Why turning a reminder on did not work, so the app can say so.
enum ReminderProblem {
  /// Notifications could not be set up at startup.
  unavailable,

  /// The user (or the OS) refused permission.
  permissionDenied,

  /// Permission was fine but scheduling failed.
  failed,
}

/// Where a tapped notification should take the user.
enum ReminderTarget { write, capsules, today }

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
  static const _birthdayIdsKey = 'birthdayNotificationIds';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Set when the user taps a notification; the home shell routes it.
  final ValueNotifier<ReminderTarget?> openRequest = ValueNotifier(null);

  /// Set when the last attempt to turn something on failed.
  ReminderProblem? lastProblem;

  /// Technical detail of the last failure, shown only in debug builds.
  String? lastDetail;

  bool get dailyEnabled => Prefs.getBool('reminderOn') ?? false;
  bool get capsuleAlerts => Prefs.getBool('capsuleAlerts') ?? true;
  bool get birthdayAlerts => Prefs.getBool('birthdayAlerts') ?? true;

  /// Whether the user waved away the one-time "make it a habit" card.
  bool get nudgeDismissed => Prefs.getBool('reminderNudgeDismissed') ?? false;

  Future<void> dismissNudge() async {
    await Prefs.setBool('reminderNudgeDismissed', true);
    notifyListeners();
  }

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
      lastDetail = '$error';
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
    if (!_ready) {
      lastProblem = ReminderProblem.unavailable;
      return false;
    }
    try {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = ios != null
          ? await ios.requestPermissions(alert: true, badge: false, sound: true)
          : await android?.requestNotificationsPermission();
      if (granted ?? ios == null) return true;
      lastProblem = ReminderProblem.permissionDenied;
      return false;
    } catch (error, stack) {
      lastProblem = ReminderProblem.failed;
      lastDetail = '$error';
      developer.log(
        'Notification permission request failed',
        name: 'note_with_us.reminders',
        error: error,
        stackTrace: stack,
      );
      return false;
    }
  }

  /// Turns the daily reminder on or off. Returns false if permission was
  /// refused, leaving it off.
  Future<bool> setDaily(bool on) async {
    if (on && !await requestPermission()) return false;
    await Prefs.setBool('reminderOn', on);
    try {
      await _rescheduleDaily();
    } catch (error, stack) {
      // Scheduling failed: leave the reminder off rather than pretend.
      await Prefs.setBool('reminderOn', false);
      lastProblem = ReminderProblem.failed;
      lastDetail = '$error';
      developer.log(
        'Scheduling the daily reminder failed',
        name: 'note_with_us.reminders',
        error: error,
        stackTrace: stack,
      );
      notifyListeners();
      return false;
    }
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

  /// Turns capsule alerts on or off. Returns false if permission was
  /// refused, leaving them as they were.
  Future<bool> setCapsuleAlerts(bool on) async {
    if (on && !await requestPermission()) return false;
    await Prefs.setBool('capsuleAlerts', on);
    if (!on) await clearCapsuleAlerts();
    notifyListeners();
    return true;
  }

  /// Turns birthday reminders on or off. Returns false if permission was
  /// refused, leaving them as they were.
  Future<bool> setBirthdayAlerts(bool on) async {
    if (on && !await requestPermission()) return false;
    await Prefs.setBool('birthdayAlerts', on);
    _birthdaySignature = null;
    if (!on) await clearBirthdayAlerts();
    notifyListeners();
    return true;
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

  /// Schedules an alert for each capsule that is still locked (with the
  /// notification text the caller chose) and cancels alerts for capsules
  /// that no longer exist.
  Future<void> syncCapsules(
    List<({String id, DateTime unlockAt, String title, String body})> capsules,
  ) async {
    if (!_ready || !capsuleAlerts) return;
    final previous = _scheduledCapsuleIds();
    final now = DateTime.now();
    final wanted =
        <int, ({String id, DateTime unlockAt, String title, String body})>{
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
        title: c.title,
        body: c.body,
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

  String? _birthdaySignature;
  Future<void> _birthdayQueue = Future.value();

  /// Schedules a reminder for each of [birthdays] and cancels reminders
  /// for people no longer listed. Does nothing when the list is the same
  /// as the last one that worked, since this is called whenever the
  /// circle changes. Calls run one after another, never at the same time.
  Future<void> syncBirthdays(
    List<({String id, DateTime at, String title, String body})> birthdays,
  ) {
    final run = _birthdayQueue.then((_) => _syncBirthdays(birthdays));
    _birthdayQueue = run;
    return run;
  }

  Future<void> _syncBirthdays(
    List<({String id, DateTime at, String title, String body})> birthdays,
  ) async {
    if (!_ready || !birthdayAlerts) return;
    final signature = birthdays
        .map((b) => '${b.id}@${b.at.millisecondsSinceEpoch}:${b.title}')
        .join('|');
    if (signature == _birthdaySignature) return;
    try {
      final wanted = {
        for (final b in birthdays) _birthdayNotificationId(b.id): b,
      };
      final previous = _scheduledIds(_birthdayIdsKey);
      // Remember both old and new ids first, so even if scheduling stops
      // halfway a later sync still knows what to cancel.
      await Prefs.setString(
        _birthdayIdsKey,
        jsonEncode({...previous, ...wanted.keys}.toList()),
      );
      for (final id in previous.difference(wanted.keys.toSet())) {
        await _plugin.cancel(id: id);
      }
      for (final MapEntry(key: id, value: b) in wanted.entries) {
        await _plugin.zonedSchedule(
          id: id,
          scheduledDate: tz.TZDateTime.from(b.at, tz.local),
          title: b.title,
          body: b.body,
          payload: ReminderTarget.today.name,
          notificationDetails: _details('birthdays', 'Birthdays'.tr),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
      await Prefs.setString(_birthdayIdsKey, jsonEncode(wanted.keys.toList()));
      // Only a sync that finished is remembered, so a failed one is retried.
      _birthdaySignature = signature;
    } catch (error, stack) {
      _birthdaySignature = null;
      developer.log(
        'Scheduling birthday reminders failed',
        name: 'note_with_us.reminders',
        error: error,
        stackTrace: stack,
      );
    }
  }

  /// Removes all birthday reminders, e.g. on sign-out.
  Future<void> clearBirthdayAlerts() async {
    _birthdaySignature = null;
    if (!_ready) return;
    for (final id in _scheduledIds(_birthdayIdsKey)) {
      await _plugin.cancel(id: id);
    }
    await Prefs.setString(_birthdayIdsKey, '[]');
  }

  Set<int> _scheduledIds(String key) {
    try {
      return {
        ...(jsonDecode(Prefs.getString(key) ?? '[]') as List).cast<int>(),
      };
    } on FormatException {
      return {};
    }
  }

  // Clear of the daily reminder and the capsule ids.
  int _birthdayNotificationId(String userId) =>
      400000000 + (userId.hashCode & 0x0FFFFFFF);

  Set<int> _scheduledCapsuleIds() => _scheduledIds(_capsuleIdsKey);

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
