import 'package:akum_connet/models/exam_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/foundation.dart';

class ExamNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
          linux: initializationSettingsLinux,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        debugPrint('Exam Notification clicked: ${response.payload}');
      },
    );

    // Create a high importance channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'exam_alerts', // id
      'Exam Alerts', // title
      description: 'Notifications for upcoming exams', // description
      importance: Importance.max,
      playSound: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Request permissions for Android 13+
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint("⚠️ ExamNotificationService: Permission request handled: $e");
    }
  }

  static Future<void> scheduleExamNotifications(ExamModel exam) async {
    // Generate unique base ID for this exam using hash of its ID
    // We use hash because exam.id is a String (uuid).
    // Ensure positive int using abs()
    final int baseId = exam.id.hashCode.abs();

    final startTimeOfDay = exam.startTimeToTimeOfDay;

    // Construct DateTime from exam date and start time
    // Note: exam.date usually has time components 00:00:00 from the date picker
    final DateTime examDateTime = DateTime(
      exam.date.year,
      exam.date.month,
      exam.date.day,
      startTimeOfDay.hour,
      startTimeOfDay.minute,
    );

    final tz.TZDateTime tzExamDateTime = tz.TZDateTime.from(
      examDateTime,
      tz.local,
    );

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // 1. Schedule 30 minutes before
    final tz.TZDateTime reminderTime = tzExamDateTime.subtract(
      const Duration(minutes: 30),
    );

    if (reminderTime.isAfter(now)) {
      await _notificationsPlugin.zonedSchedule(
        baseId + 1, // ID for reminder
        "Upcoming Exam: ${exam.courseCode}",
        "Exams starts in 30 minutes at ${exam.venue}",
        reminderTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'exam_alerts',
            'Exam Alerts',
            channelDescription: 'Notifications for upcoming exams',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.critical,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint("Scheduled reminder for ${exam.courseCode} at $reminderTime");
    }

    // 2. Schedule exactly at start time
    if (tzExamDateTime.isAfter(now)) {
      await _notificationsPlugin.zonedSchedule(
        baseId + 2, // ID for start time
        "Exam Time Now: ${exam.courseCode}",
        "Good luck! Venue: ${exam.venue}",
        tzExamDateTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'exam_alerts',
            'Exam Alerts',
            channelDescription: 'Notifications for upcoming exams',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.critical,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint(
        "Scheduled start alarm for ${exam.courseCode} at $tzExamDateTime",
      );
    }
  }

  static Future<void> cancelExamNotifications(ExamModel exam) async {
    final int baseId = exam.id.hashCode.abs();
    await _notificationsPlugin.cancel(baseId + 1);
    await _notificationsPlugin.cancel(baseId + 2);
    debugPrint("Cancelled notifications for ${exam.courseCode}");
  }
}
