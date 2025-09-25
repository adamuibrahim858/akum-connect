import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
              ),
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
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Welcome to AKUM CONNECT",
                      style: TextStyle(color: Colors.white70, fontSize: 20),
                    ),
                  ],
                ),
                const CircleAvatar(
                  radius: 28,
                  backgroundImage: NetworkImage(
                      "https://i.pravatar.cc/150?img=3"), // sample avatar
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Dashboard Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  dashboardCard(
                    Icons.person,
                    "Profile",
                    Colors.blue,
                        () {
                      // debugPrint("Profile tapped");
                      Navigator.pushNamed(context, '/profile');
                        },
                  ),
                  dashboardCard(
                    Icons.grade,
                    "Result",
                    Colors.green,
                        () {
                      debugPrint("Result tapped");
                    },
                  ),
                  dashboardCard(
                    Icons.schedule,
                    "Timetable",
                    Colors.orange,
                        () {
                      debugPrint("Timetable tapped");
                    },
                  ),
                  dashboardCard(
                    Icons.article,
                    "News",
                    Colors.purple,
                        () {
                      debugPrint("News tapped");
                    },
                  ),
                  dashboardCard(
                    Icons.check_circle,
                    "To-Dos",
                    Colors.teal,
                        () {
                      // debugPrint("To-Dos tapped");
                      Navigator.pushNamed(context, '/to-dos');

                        },
                  ),
                  dashboardCard(
                    Icons.chat,
                    "Chat Room",
                    Colors.red,
                        () {
                      // debugPrint("Chat Room tapped");
                          Navigator.pushNamed(context, '/chats');
                        },
                  ),
                  dashboardCard(
                    Icons.note,
                    "Notes",
                    Colors.brown,
                        () {
                      debugPrint("Notes tapped");
                    },
                  ),
                  dashboardCard(
                    Icons.store,
                    "Market Place",
                    Colors.indigo,
                        () {
                      debugPrint("Market Place tapped");
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable Dashboard Card with onPressed
  static Widget dashboardCard(
      IconData icon, String title, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
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
