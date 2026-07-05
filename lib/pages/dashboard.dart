import 'package:flutter/material.dart';
import 'marketplace/marketplace_page.dart';
import 'news/news_list_page.dart';
import 'ai_chat_page.dart';
import 'hostel/hostel_page.dart';
import 'course_registration/course_registration_page.dart';

import 'package:hive_flutter/hive_flutter.dart';
import '../models/timetable_entry.dart';
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
            height: 200.0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
            decoration: const BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40)),
            ),
            child: Row(
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
                      style: TextStyle(color: Colors.white70, fontSize: 20),
                    ),
                  ],
                ),
                // const CircleAvatar(
                //   radius: 32,
                //   backgroundImage: AssetImage(
                //     "assets/images/akumlogo.png",
                //   ), // sample avatar
                // ),
              ],
            ),
          ),

          // const SizedBox(height: 1),

          // Dashboard Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  dashboardCard(Icons.person, "Profile", Colors.blue, () {
                    // debugPrint("Profile tapped");
                    Navigator.pushNamed(context, '/profile');
                  }),
                  dashboardCard(Icons.grade, "Result", Colors.green, () {
                    // debugPrint("Result tapped");
                    Navigator.pushNamed(context, '/result');
                  }),
                  dashboardCard(Icons.apartment, "Hostel", Colors.deepOrange, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HostelPage(),
                      ),
                    );
                  }),
                  dashboardCard(Icons.app_registration, "Course Reg", Colors.cyan, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CourseRegistrationPage(),
                      ),
                    );
                  }),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              radius: 30,
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
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
