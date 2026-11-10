import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_constants.dart';

/// Thin wrapper around flutter_local_notifications for the daily check-in
/// reminder. All failures degrade to `false`/no-ops so the app never breaks
/// when notifications are unavailable (e.g. emulator quirks).
class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(settings);
      _ready = true;
    } on Exception {
      _ready = false;
    }
  }

  Future<bool> _ensurePermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    try {
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    } on Exception {
      return false;
    }
  }

  /// Schedules (or reschedules) the daily reminder at [hour]:[minute].
  /// Returns false when notifications are unavailable or permission denied.
  Future<bool> scheduleDaily({
    required int hour,
    required int minute,
    required String langCode,
  }) async {
    if (!_ready) return false;
    if (!await _ensurePermission()) return false;
    final isId = langCode.startsWith('id');
    final title = isId ? 'Halo! 👋 NARA di sini' : 'Hey! 👋 NARA here';
    final body = isId
        ? 'Cek tugasmu dan isi kebiasaan hari ini yuk. Menit kecil, dampak besar.'
        : 'Check your tasks and check in your habits. Small minute, big impact.';
    try {
      await _plugin.zonedSchedule(
        ReminderConstants.dailyNotificationId,
        title,
        body,
        _nextInstanceOf(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            ReminderConstants.dailyChannelId,
            ReminderConstants.dailyChannelName,
            channelDescription: 'NARA daily check-in reminder',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return true;
    } on Exception {
      return false;
    }
  }

  Future<void> cancelDaily() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(ReminderConstants.dailyNotificationId);
    } on Exception {
      // Nothing to cancel — ignore.
    }
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
