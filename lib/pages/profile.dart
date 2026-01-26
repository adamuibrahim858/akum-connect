import 'package:akum_connet/pages/edit_profile.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/student_info.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Student>('students');

    if (box.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.green,
        ),
        body: const Center(child: Text('No student data found!')),
      );
    }

    // Get the last registered student
    final student = box.getAt(box.length - 1)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              final box = Hive.box<Student>('students');
              final studentIndex = box.length - 1; // last student
              final student = box.getAt(studentIndex)!;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EditProfilePage(student: student, index: studentIndex),
                ),
              );
            },
          ),

          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            
            const SizedBox(height: 5),

            // Profile Info Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  profileTile("Full Name", student.fullName, Icons.person),
                  profileTile("Matric Number", student.matricNo, Icons.badge),
                  profileTile("Phone Number", student.phone, Icons.phone),
                  profileTile("Email", student.email, Icons.email),
                  profileTile("Faculty", student.faculty, Icons.school),
                  profileTile("Department", student.department, Icons.computer),
                  profileTile("Course", student.course, Icons.book),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable Profile Tile
  static Widget profileTile(String title, String value, IconData icon) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.1),
          child: Icon(icon, color: Colors.green),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
