import 'package:hive/hive.dart';

part 'student_info.g.dart';

@HiveType(typeId: 0)
class Student extends HiveObject {
  @HiveField(0)
  String fullName;

  @HiveField(1)
  String matricNo;

  @HiveField(2)
  String email;

  @HiveField(3)
  String phone;

  @HiveField(4)
  String faculty;

  @HiveField(5)
  String department;

  @HiveField(6)
  String course;

  @HiveField(7)
  String? profileImagePath;

  @HiveField(8)
  String? level;

  Student({
    required this.fullName,
    required this.matricNo,
    required this.email,
    required this.phone,
    required this.faculty,
    required this.department,
    required this.course,
    this.profileImagePath,
    this.level,
  });

  /// Helper to get user initials for fallback avatar (e.g. "Adamu Ibrahim" -> "AI")
  String get initials {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'AK';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
      final second = parts[1].isNotEmpty ? parts[1][0].toUpperCase() : '';
      return '$first$second';
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }
}
