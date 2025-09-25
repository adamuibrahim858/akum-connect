import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _matricC = TextEditingController();
  final _emailC = TextEditingController();
  final _phoneC = TextEditingController();

  String? _selectedFaculty;
  String? _selectedDepartment;
  String? _selectedCourse;

  // Mock data
  final Map<String, Map<String, List<String>>> _facultyData = {
    "Science": {
      "Computer Science": ["Cyber Security", "Software Engineering", "AI"],
      "Biology": ["Microbiology", "Biotechnology"],
    },
    "Education": {
      "Mathematics": ["Pure Math", "Applied Math"],
      "Computer Education": ["EdTech", "Programming Pedagogy"],
    },
    "Management": {
      "Business Admin": ["Marketing", "Finance"],
      "Accounting": ["Taxation", "Auditing"],
    },
  };

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedFaculty == null ||
          _selectedDepartment == null ||
          _selectedCourse == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Please select faculty, department, and course")),
        );
        return;
      }

      final data = {
        "fullName": _nameC.text.trim(),
        "matricNo": _matricC.text.trim(),
        "email": _emailC.text.trim(),
        "phone": _phoneC.text.trim(),
        "faculty": _selectedFaculty,
        "department": _selectedDepartment,
        "course": _selectedCourse,
      };

      debugPrint("Student Registered: $data");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration successful ✅")),
      );

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _matricC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.green, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[100],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 50),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.greenAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                BorderRadius.only(bottomLeft: Radius.circular(50)),
              ),
              child: const Center(
                child: Text(
                  "Student Sign Up",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Form Container
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 10, spreadRadius: 2),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Full name
                    TextFormField(
                      controller: _nameC,
                      decoration: _inputDecoration("Full Name", Icons.person),
                      validator: (v) =>
                      v == null || v.isEmpty ? "Enter your full name" : null,
                    ),
                    const SizedBox(height: 16),

                    // Matric number
                    TextFormField(
                      controller: _matricC,
                      decoration:
                      _inputDecoration("Matric Number", Icons.badge),
                      validator: (v) => v == null || v.isEmpty
                          ? "Enter matric number"
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailC,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration("Email", Icons.email),
                      validator: (v) => v == null || !v.contains("@")
                          ? "Enter a valid email"
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneC,
                      keyboardType: TextInputType.phone,
                      decoration:
                      _inputDecoration("Phone Number", Icons.phone),
                      validator: (v) => v == null || v.length < 10
                          ? "Enter a valid phone number"
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Faculty
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration("Faculty", Icons.school),
                      value: _selectedFaculty,
                      items: _facultyData.keys
                          .map((f) =>
                          DropdownMenuItem(value: f, child: Text(f)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedFaculty = val;
                          _selectedDepartment = null;
                          _selectedCourse = null;
                        });
                      },
                      validator: (v) => v == null ? "Select faculty" : null,
                    ),
                    const SizedBox(height: 16),

                    // Department
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration("Department", Icons.apartment),
                      value: _selectedDepartment,
                      items: _selectedFaculty == null
                          ? []
                          : _facultyData[_selectedFaculty]!.keys
                          .map((d) =>
                          DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedDepartment = val;
                          _selectedCourse = null;
                        });
                      },
                      validator: (v) => v == null ? "Select department" : null,
                    ),
                    const SizedBox(height: 16),

                    // Course
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration("Course", Icons.menu_book),
                      value: _selectedCourse,
                      items: _selectedFaculty == null ||
                          _selectedDepartment == null
                          ? []
                          : _facultyData[_selectedFaculty]![_selectedDepartment]!
                          .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        setState(() => _selectedCourse = val);
                      },
                      validator: (v) => v == null ? "Select course" : null,
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: const Text("Register"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
