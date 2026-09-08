import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
      NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const int _notificationId = 1001;

  static const String _enabledKey =
      'notifications_enabled';

  static const String _hourKey =
      'notification_hour';

  static const String _minuteKey =
      'notification_minute';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings =
        InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: initializationSettings,
    );

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();

    final androidPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) {
      return true;
    }

    final granted =
        await androidPlugin.requestNotificationsPermission();

    return granted ?? false;
  }

  Future<void> scheduleDailyNotification({
    required int hour,
    required int minute,
  }) async {
    await initialize();

    final prefs =
        await SharedPreferences.getInstance();

    final userName =
        prefs.getString('user_name') ?? '';

    final notificationText =
        userName.isEmpty
            ? 'Време е за твоите навици! 🔥'
            : '$userName, време е за твоите навици! 🔥';

    final now =
        tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Ако часът вече е минал днес,
    // първото известие ще бъде утре.
    if (!scheduledDate.isAfter(now)) {
      scheduledDate =
          scheduledDate.add(
        const Duration(days: 1),
      );
    }

    const notificationDetails =
        NotificationDetails(
      android: AndroidNotificationDetails(
        'streakly_daily',
        'Streakly напомняния',
        channelDescription:
            'Ежедневни напомняния за навиците',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    // Първо отменяме старото известие,
    // за да няма две известия едновременно.
    await _notifications.cancel(
      id: _notificationId,
    );

    await _notifications.zonedSchedule(
      id: _notificationId,
      title: 'Streakly',
      body: notificationText,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode:
          AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents:
          DateTimeComponents.time,
    );

    await prefs.setBool(
      _enabledKey,
      true,
    );

    await prefs.setInt(
      _hourKey,
      hour,
    );

    await prefs.setInt(
      _minuteKey,
      minute,
    );
  }

  Future<void> cancelDailyNotification() async {
    await initialize();

    await _notifications.cancel(
      id: _notificationId,
    );

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      _enabledKey,
      false,
    );
  }

  Future<bool> isEnabled() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getBool(
          _enabledKey,
        ) ??
        false;
  }

  Future<int> getHour() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getInt(
          _hourKey,
        ) ??
        20;
  }

  Future<int> getMinute() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getInt(
          _minuteKey,
        ) ??
        0;
  }
}