import 'dart:io';
import 'package:flutter/material.dart';
import 'marketplace/marketplace_page.dart';
import 'news/news_list_page.dart';
import 'ai_chat_page.dart';
import 'hostel/hostel_page.dart';
import 'course_registration/course_registration_page.dart';

import 'package:hive_flutter/hive_flutter.dart';
import '../models/timetable_entry.dart';
import '../models/student_info.dart';
import '../services/lecture_notification_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Defer notification scheduling to avoid blocking the UI during initial render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleTimetableNotifications();
    });
  }

  Future<void> _scheduleTimetableNotifications() async {
    try {
      final box = Hive.box<TimetableEntry>('timetable');
      final entries = box.values.toList();
      await LectureNotificationService.scheduleNotifications(entries);
    } catch (e) {
      debugPrint("Error scheduling notifications from dashboard: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Top Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade800, Colors.green.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(36),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Hive.isBoxOpen('students')
                ? ValueListenableBuilder<Box<Student>>(
                    valueListenable: Hive.box<Student>('students').listenable(),
                    builder: (context, box, _) {
                      final student =
                          box.isNotEmpty ? box.getAt(box.length - 1) : null;
                      final name = student != null
                          ? student.fullName.split(' ').first
                          : 'Student';

                      final hasPhoto = student?.profileImagePath != null &&
                          student!.profileImagePath!.isNotEmpty &&
                          File(student.profileImagePath!).existsSync();

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Hi, $name!",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  student != null
                                      ? student.course
                                      : "Welcome to AKUM CONNECT",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: () =>
                                Navigator.pushNamed(context, '/profile'),
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.white,
                                backgroundImage: hasPhoto
                                    ? FileImage(
                                        File(student.profileImagePath!),
                                      )
                                    : null,
                                child: !hasPhoto
                                    ? Text(
                                        student?.initials ?? 'AK',
                                        style: TextStyle(
                                          color: Colors.green.shade800,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Hi Student!",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Welcome to AKUM CONNECT",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white24,
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                    ],
                  ),
          ),

          // const SizedBox(height: 1),

          // Dashboard Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.88,
                children: [
                  dashboardCard(Icons.person, "Profile", Colors.blue, () {
                    // debugPrint("Profile tapped");
                    Navigator.pushNamed(context, '/profile');
                  }),
                  dashboardCard(Icons.grade, "Result", Colors.green, () {
                    // debugPrint("Result tapped");
                    Navigator.pushNamed(context, '/result');
                  }),
                  dashboardCard(
                    Icons.school,
                    "AI Tutor",
                    Colors.deepPurple,
                    () {
                      Navigator.pushNamed(context, '/ai-tutor');
                    },
                  ),
                  dashboardCard(
                    Icons.apartment,
                    "Hostel",
                    Colors.deepOrange,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HostelPage(),
                        ),
                      );
                    },
                  ),
                  dashboardCard(
                    Icons.app_registration,
                    "Course Reg",
                    Colors.cyan,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CourseRegistrationPage(),
                        ),
                      );
                    },
                  ),
                  dashboardCard(Icons.schedule, "Timetable", Colors.orange, () {
                    // debugPrint("Timetable tapped");
                    Navigator.pushNamed(context, '/timetable');
                  }),
                  dashboardCard(Icons.article, "News", Colors.purple, () {
                    // debugPrint("News tapped");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NewsListPage(),
                      ),
                    );
                  }),
                  dashboardCard(
                    Icons.assignment_turned_in,
                    "Exam Timetable",
                    Colors.teal,
                    () {
                      // debugPrint("Exam Time Table tapped");
                      Navigator.pushNamed(context, '/exam-timetable');
                    },
                  ),
                  dashboardCard(Icons.note, "Notes", Colors.brown, () {
                    // debugPrint("Notes tapped");
                    Navigator.pushNamed(context, '/notes');
                  }),
                  dashboardCard(Icons.store, "Market Place", Colors.indigo, () {
                    // debugPrint("Market Place tapped");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MarketplacePage(),
                      ),
                    );
                  }),
                  dashboardCard(Icons.info, "About", Colors.red, () {
                    // debugPrint("Chat Room tapped");
                    Navigator.pushNamed(context, '/about');
                  }),
                ],
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AiChatPage()),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.support_agent, color: Colors.white),
      ),
    );
  }

  // Reusable Dashboard Card with onPressed
  static Widget dashboardCard(
    IconData icon,
    String title,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              radius: 22,
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
