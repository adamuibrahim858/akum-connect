import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'exam_model.g.dart';

@HiveType(typeId: 2)
class ExamModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String courseCode;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String startTime; // Store as String for Hive (TimeOfDay not supported directly)

  @HiveField(4)
  final String endTime; // Store as String for Hive

  @HiveField(5)
  final String venue;

  ExamModel({
    required this.id,
    required this.courseCode,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.venue,
  });

  // Helper to get TimeOfDay from String
  TimeOfDay get startTimeToTimeOfDay {
    final parts = startTime.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // Helper to get TimeOfDay from String
  TimeOfDay get endTimeToTimeOfDay {
    final parts = endTime.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
