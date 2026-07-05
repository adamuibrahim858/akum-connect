import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import 'course_registration_summary_page.dart';

class CourseRegistrationPage extends StatefulWidget {
  const CourseRegistrationPage({super.key});

  @override
  State<CourseRegistrationPage> createState() => _CourseRegistrationPageState();
}

class _CourseRegistrationPageState extends State<CourseRegistrationPage> {
  final List<Course> availableCourses = CourseService.getAvailableCourses();
  final Set<String> selectedCourseCodes = {};

  int get totalCreditUnits {
    return availableCourses
        .where((c) => selectedCourseCodes.contains(c.code))
        .fold(0, (sum, c) => sum + c.creditUnit);
  }

  void _submitRegistration() {
    if (selectedCourseCodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one course to register."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mock save logic
    final selectedCourses = availableCourses
        .where((c) => selectedCourseCodes.contains(c.code))
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Registration Successful"),
          content: const Text("Your courses have been successfully registered for this semester."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Navigate to summary/print page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourseRegistrationSummaryPage(
                      registeredCourses: selectedCourses,
                    ),
                  ),
                );
              },
              child: const Text("View Summary"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Course Registration"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text("Selected Courses", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      "${selectedCourseCodes.length}",
                      style: const TextStyle(fontSize: 24, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text("Total Units", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      "$totalCreditUnits",
                      style: const TextStyle(fontSize: 24, color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: availableCourses.length,
              itemBuilder: (context, index) {
                final course = availableCourses[index];
                final isSelected = selectedCourseCodes.contains(course.code);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? Colors.green : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedCourseCodes.add(course.code);
                        } else {
                          selectedCourseCodes.remove(course.code);
                        }
                      });
                    },
                    title: Text(
                      "${course.code} - ${course.title}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("${course.creditUnit} Units • ${course.department}"),
                    activeColor: Colors.green,
                    checkColor: Colors.white,
                    secondary: const Icon(Icons.book, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Submit Registration",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
