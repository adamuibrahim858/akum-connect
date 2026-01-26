import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import '../models/timetable_entry.dart';

class LectureNotificationService {
  static final fln.FlutterLocalNotificationsPlugin _notificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    // Get local timezone
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const fln.DarwinInitializationSettings initializationSettingsDarwin =
        fln.DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const fln.InitializationSettings initializationSettings =
        fln.InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (fln.NotificationResponse response) async {
            debugPrint('Notification clicked: ${response.payload}');
          },
    );

    // Request permissions for Android 13+
    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          fln.AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleNotifications(
    List<TimetableEntry> timetable,
  ) async {
    await cancelAllNotifications(); // Clear old alarms before setting new ones

    debugPrint("Scheduling notifications for ${timetable.length} entries...");

    for (var i = 0; i < timetable.length; i++) {
      final entry = timetable[i];
      await _scheduleForEntry(entry, i);
    }
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  static Future<void> _scheduleForEntry(TimetableEntry entry, int index) async {
    // Parse Time: "08:00 - 10:00" -> "08:00"
    try {
      final startTimeStr = entry.timeSlot.split(' - ').first.trim();
      final timeParts = startTimeStr.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Map day string to DateTime weekday
      // Monday=1, ... Sunday=7
      final dayMap = {
        'Monday': 1,
        'Tuesday': 2,
        'Wednesday': 3,
        'Thursday': 4,
        'Friday': 5,
        'Saturday': 6,
        'Sunday': 7,
      };

      final targetWeekday = dayMap[entry.day];
      if (targetWeekday == null) return;

      // Calculate next instance for Lecture Start
      final nextLectureTime = _nextInstanceOfDayAndTime(
        targetWeekday,
        hour,
        minute,
      );

      // Calculate next instance for Reminder (5 mins before)
      // IMPORTANT: Calculate independently to handle day wrap correctly
      // e.g. Lecture on Mon 00:02, Reminder should be Sun 23:57
      // But for simplicity in this timetable context (usually 8am-6pm), direct subtraction is okay
      // BUT, if we subtract and it goes into the past relative to now, we must ensure it's next occurrence.
      // So best to calculate "Now + X" logic inside helper.

      // Let's us calculate the target time for reminder first (hour/min)
      // If 8:00 -> 7:55. If 00:02 -> 23:57 prev day.
      // Instead of manual math, let's just subtract 5 mins from the *nextLectureTime*
      // AND CHECK if that result is in the past. If so, add 7 days.

      tz.TZDateTime reminderTime = nextLectureTime.subtract(
        const Duration(minutes: 5),
      );
      if (reminderTime.isBefore(tz.TZDateTime.now(tz.local))) {
        reminderTime = reminderTime.add(const Duration(days: 7));
      }

      // Schedule Alarm (Start Time)
      await _notificationsPlugin.zonedSchedule(
        index * 10 + 1, // Unique ID
        "Lecture Started: ${entry.courseCode}",
        "${entry.courseTitle} at ${entry.venue}",
        nextLectureTime,
        fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'lecture_alarm',
            'Lecture Alarms',
            channelDescription: 'Notifications for lectures',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
            // Sound: Use default if raw resource is missing.
            // To use custom sound: Place file in android/app/src/main/res/raw/alarm_sound.mp3
            // sound: const fln.RawResourceAndroidNotificationSound('alarm_sound'),
            playSound: true,
          ),
          iOS: const fln.DarwinNotificationDetails(presentSound: true),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: fln.DateTimeComponents.dayOfWeekAndTime,
      );

      // Schedule Reminder (5 mins before)
      await _notificationsPlugin.zonedSchedule(
        index * 10 + 2,
        "Upcoming Lecture: ${entry.courseCode}",
        "Starts in 5 mins! ${entry.courseTitle} at ${entry.venue}",
        reminderTime,
        fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'lecture_reminder',
            'Lecture Reminders',
            channelDescription: 'Reminders 5 minutes before lecture',
            importance: fln.Importance.high,
            priority: fln.Priority.high,
            playSound: true,
          ),
          iOS: const fln.DarwinNotificationDetails(),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,

        matchDateTimeComponents: fln.DateTimeComponents.dayOfWeekAndTime,
      );

      debugPrint(
        "Scheduled ${entry.courseCode}: Start at $nextLectureTime, Reminder at $reminderTime",
      );
    } catch (e) {
      debugPrint("Error scheduling for ${entry.courseCode}: $e");
    }
  }

  static tz.TZDateTime _nextInstanceOfDayAndTime(
    int weekday,
    int hour,
    int minute,
  ) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Adjust to correct weekday
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // If passed, add a week
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }
}
