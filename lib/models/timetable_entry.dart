import 'package:hive/hive.dart';

part 'timetable_entry.g.dart';

@HiveType(typeId: 1)
class TimetableEntry extends HiveObject {
  @HiveField(0)
  final String day;

  @HiveField(1)
  final String timeSlot;

  @HiveField(2)
  String courseCode;

  @HiveField(3)
  String courseTitle;

  @HiveField(4)
  String lecturerName;

  @HiveField(5)
  String venue;

  TimetableEntry({
    required this.day,
    required this.timeSlot,
    required this.courseCode,
    required this.courseTitle,
    required this.lecturerName,
    required this.venue,
  });

  // Create a copy for editing
  TimetableEntry copyWith({
    String? day,
    String? timeSlot,
    String? courseCode,
    String? courseTitle,
    String? lecturerName,
    String? venue,
  }) {
    return TimetableEntry(
      day: day ?? this.day,
      timeSlot: timeSlot ?? this.timeSlot,
      courseCode: courseCode ?? this.courseCode,
      courseTitle: courseTitle ?? this.courseTitle,
      lecturerName: lecturerName ?? this.lecturerName,
      venue: venue ?? this.venue,
    );
  }
}
