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
    // Get local timezone, default to 'UTC' if checking fails to avoid crash
    String? timeZoneName;
    try {
      timeZoneName = await FlutterTimezone.getLocalTimezone();
    } catch (e) {
      debugPrint("Failed to get local timezone: $e");
    }

    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName ?? 'Africa/Lagos'));
    } catch (e) {
      debugPrint(
        "Could not set location for $timeZoneName, fallback to UTC/Local. Error: $e",
      );
    }

    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const fln.DarwinInitializationSettings initializationSettingsDarwin =
        fln.DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const fln.LinuxInitializationSettings initializationSettingsLinux =
        fln.LinuxInitializationSettings(defaultActionName: 'Open notification');

    const fln.InitializationSettings initializationSettings =
        fln.InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          linux: initializationSettingsLinux,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (fln.NotificationResponse response) async {
            debugPrint('Notification clicked: ${response.payload}');
          },
    );

    // Request permissions for Android 13+
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              fln.AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint(
        "⚠️ LectureNotificationService: Permission request handled: $e",
      );
    }
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
    // 1. Parsing Logic
    int? parsedHour = _parseStartHour(entry.timeSlot);

    if (parsedHour == null) {
      debugPrint(
        "❌ Failed to parse time slot: ${entry.timeSlot} for ${entry.courseCode}",
      );
      return;
    }

    // 2. Day Mapping
    // Handle both full names "Monday" and short "MON"
    final dayMap = {
      'MONDAY': 1,
      'MON': 1,
      'TUESDAY': 2,
      'TUE': 2,
      'WEDNESDAY': 3,
      'WED': 3,
      'THURSDAY': 4,
      'THU': 4,
      'FRIDAY': 5,
      'FRI': 5,
      'SATURDAY': 6,
      'SAT': 6,
      'SUNDAY': 7,
      'SUN': 7,
    };

    final normalizedDay = entry.day.toUpperCase().trim();
    final targetWeekday = dayMap[normalizedDay];

    if (targetWeekday == null) {
      debugPrint("❌ Failed to map day: ${entry.day} for ${entry.courseCode}");
      return;
    }

    debugPrint(
      "\n--- Processing ${entry.courseCode} (${entry.day} ${entry.timeSlot}) ---",
    );
    debugPrint("Parsed Start Hour: $parsedHour:00 (Weekday: $targetWeekday)");

    // 3. Calculate Notifications
    // We need TWO notifications:
    // A. 10 mins before start (Reminder)
    // B. Exact start time (Lecture Start)

    // Calculate next instance of the Lecture Start
    tz.TZDateTime lectureStartTime = _nextInstanceOfDayAndTime(
      targetWeekday,
      parsedHour,
      0, // Minute is always 0 for these slots
    );

    // Calculate Reminder time (10 mins before)
    tz.TZDateTime reminderTime = lectureStartTime.subtract(
      const Duration(minutes: 10),
    );

    // CRITICAL FIX: Ensure Reminder is also in the future.
    // _nextInstanceOfDayAndTime ensures lectureStartTime is in the future relative to NOW.
    // However, if lectureStartTime is today at 8:00 AM, and now is 7:55 AM:
    // lectureStartTime (8:00) is valid (future).
    // reminderTime (7:50) is invalid (past).
    // If reminderTime is in the past, we should move BOTH to next week to maintain the cycle,
    // OR we accept that we missed this week's reminder but catch the lecture start.
    // The requirement says "Ensure notifications are NOT scheduled in the past".
    // Best approach for repeating weekly notifications: Find the first pair where BOTH are in the future.

    final now = tz.TZDateTime.now(tz.local);

    if (reminderTime.isBefore(now)) {
      debugPrint(
        "⚠️ Calculated reminder $reminderTime is in the past. Moving schedule to next week.",
      );
      lectureStartTime = lectureStartTime.add(const Duration(days: 7));
      reminderTime = reminderTime.add(const Duration(days: 7));
    }

    debugPrint("✅ Scheduling Reminder at: $reminderTime");
    debugPrint("✅ Scheduling Start at:    $lectureStartTime");

    // 4. Schedule Alarm A (Reminder - 10 mins before)
    try {
      await _notificationsPlugin.zonedSchedule(
        index * 20 + 0, // Unique ID
        "Upcoming: ${entry.courseCode}", // Title
        "In 10 mins: ${entry.courseTitle} at ${entry.venue}", // Body
        reminderTime,
        fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'lecture_reminder',
            'Lecture Reminders',
            channelDescription: 'Reminders 10 minutes before lecture',
            importance: fln.Importance.high,
            priority: fln.Priority.high,
            playSound: true,
          ),
          iOS: const fln.DarwinNotificationDetails(presentSound: true),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: fln.DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      debugPrint("❌ Error scheduling REMINDER for ${entry.courseCode}: $e");
    }

    // 5. Schedule Alarm B (Exact Start Time)
    try {
      await _notificationsPlugin.zonedSchedule(
        index * 20 + 1, // Unique ID (Offset by 1)
        "Lecture Started: ${entry.courseCode}",
        "Happening NOW via ${entry.venue}",
        lectureStartTime,
        fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'lecture_alarm',
            'Lecture Alarms',
            channelDescription: 'Notifications for exact lecture time',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
            playSound: true,
          ),
          iOS: const fln.DarwinNotificationDetails(presentSound: true),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: fln.DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      debugPrint("❌ Error scheduling START ALARM for ${entry.courseCode}: $e");
    }
  }

  /// Parses strings like "8-9", "12-1", "1-2" into 24-hour start integer.
  static int? _parseStartHour(String timeSlot) {
    if (timeSlot.trim().isEmpty) return null;

    // Extract first part: "8-9" -> "8"
    String startPart = timeSlot.split('-').first.trim();
    // Handle en-dash just in case
    if (startPart.contains('–')) {
      startPart = startPart.split('–').first.trim();
    }

    int? hour = int.tryParse(startPart);
    if (hour == null) return null;

    // Heuristic for School Hours (Daily 7am to 6pm cycle)
    // 8, 9, 10, 11 -> AM (Return as is)
    // 12 -> PM (Noon) (Return 12)
    // 1, 2, 3, 4, 5, 6 -> PM (Add 12 -> 13, 14, etc.)

    if (hour >= 7 && hour <= 11) {
      return hour;
    } else if (hour == 12) {
      return 12;
    } else if (hour >= 1 && hour <= 6) {
      return hour + 12;
    } else {
      // Fallback/Edge case (e.g. 7am or evening classes? Assuming AM if < 7? or PM?)
      // Given the list: 8-9, ..., 5-6. This logic covers all.
      // If a slot is "7-8", it fits 7-11.
      return hour;
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

    // Initial Move: Ensure the weekday matches
    // Note: This logic simply moves forward day by day until it hits the weekday.
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Check if the resulting date/time is in the past.
    // If so, add 7 days to get the NEXT week's occurrence.
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }
}
