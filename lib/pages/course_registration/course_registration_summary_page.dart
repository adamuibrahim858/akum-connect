import 'package:flutter/material.dart';
import '../../models/course_model.dart';

class CourseRegistrationSummaryPage extends StatelessWidget {
  final List<Course> registeredCourses;

  const CourseRegistrationSummaryPage({
    super.key,
    required this.registeredCourses,
  });

  @override
  Widget build(BuildContext context) {
    int totalUnits = registeredCourses.fold(0, (sum, c) => sum + c.creditUnit);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Registration Summary"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "AKUM CONNECT",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const Center(
              child: Text(
                "Course Registration Form",
                style: TextStyle(fontSize: 16),
              ),
            ),
            const Divider(height: 30, thickness: 2),
            const SizedBox(height: 10),
            const Text(
              "Student Name: John Doe",
              style: TextStyle(fontSize: 16),
            ),
            const Text(
              "Matric Number: AKUM/2023/001",
              style: TextStyle(fontSize: 16),
            ),
            const Text(
              "Department: Computer Science",
              style: TextStyle(fontSize: 16),
            ),
            const Text("Level: 400L", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            const Text(
              "Registered Courses",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  itemCount: registeredCourses.length + 1,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index == registeredCourses.length) {
                      // Total row
                      return ListTile(
                        title: const Text(
                          "TOTAL CREDIT UNITS",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                          "$totalUnits",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }
                    final course = registeredCourses[index];
                    return ListTile(
                      title: Text("${course.code} - ${course.title}"),
                      trailing: Text("${course.creditUnit} Units"),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Print logic will be integrated later."),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                icon: const Icon(Icons.print),
                label: const Text(
                  "Print Course Registration",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Back to Dashboard",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
