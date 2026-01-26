import 'package:hive/hive.dart';

part 'student_info.g.dart'; // generated file

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

  Student({
    required this.fullName,
    required this.matricNo,
    required this.email,
    required this.phone,
    required this.faculty,
    required this.department,
    required this.course,
  });
}
