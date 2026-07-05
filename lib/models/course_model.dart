class Course {
  final String code;
  final String title;
  final int creditUnit;
  final String department;
  final String semester;

  Course({
    required this.code,
    required this.title,
    required this.creditUnit,
    required this.department,
    required this.semester,
  });
}

// Mock Data Service
class CourseService {
  static List<Course> getAvailableCourses() {
    return [
      Course(
        code: 'CSC401',
        title: 'Artificial Intelligence',
        creditUnit: 3,
        department: 'Computer Science',
        semester: 'First Semester',
      ),
      Course(
        code: 'CSC403',
        title: 'Compiler Construction',
        creditUnit: 2,
        department: 'Computer Science',
        semester: 'First Semester',
      ),
      Course(
        code: 'CSC405',
        title: 'Computer Networks',
        creditUnit: 3,
        department: 'Computer Science',
        semester: 'First Semester',
      ),
      Course(
        code: 'CSC407',
        title: 'Human Computer Interaction',
        creditUnit: 2,
        department: 'Computer Science',
        semester: 'First Semester',
      ),
      Course(
        code: 'MTH401',
        title: 'Advanced Calculus',
        creditUnit: 3,
        department: 'Mathematics',
        semester: 'First Semester',
      ),
      Course(
        code: 'PHY401',
        title: 'Quantum Mechanics',
        creditUnit: 3,
        department: 'Physics',
        semester: 'First Semester',
      ),
      Course(
        code: 'GST401',
        title: 'Entrepreneurship',
        creditUnit: 2,
        department: 'General Studies',
        semester: 'First Semester',
      ),
    ];
  }
}
