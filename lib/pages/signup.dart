import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:akum_connet/data/courses.dart'; // Import the structured data
import '../models/student_info.dart';

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

  // Selected Objects? Or just Strings. Strings are easier for Hive.
  // We can just store the String Names.
  String? _selectedFacultyName;
  String? _selectedDepartmentName;
  String? _selectedProgrammeName;

  // Helpers to get lists based on selection
  List<Department> get _availableDepartments {
    if (_selectedFacultyName == null) return [];
    try {
      return allFaculties
          .firstWhere((f) => f.facultyName == _selectedFacultyName)
          .departments;
    } catch (e) {
      return [];
    }
  }

  List<Programme> get _availableProgrammes {
    if (_selectedDepartmentName == null) return [];
    try {
      // Find faculty first (optimization: simplify if we had the object)
      // Since we store names, we look it up.
      final faculty = allFaculties.firstWhere(
        (f) => f.facultyName == _selectedFacultyName,
        orElse: () => allFaculties.first, // fallback
      );
      return faculty.departments
          .firstWhere((d) => d.departmentName == _selectedDepartmentName)
          .programmes;
    } catch (e) {
      return [];
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedFacultyName == null ||
          _selectedDepartmentName == null ||
          _selectedProgrammeName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select faculty, department, and programme"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final newStudent = Student(
        fullName: _nameC.text.trim(),
        matricNo: _matricC.text.trim(),
        email: _emailC.text.trim(),
        phone: _phoneC.text.trim(),
        faculty: _selectedFacultyName!,
        department: _selectedDepartmentName!,
        course: _selectedProgrammeName!,
      );

      // Save to Hive
      final box = Hive.box<Student>('students');
      await box.add(newStudent);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration successful ✅")),
      );

      debugPrint("Student saved to Hive: ${newStudent.fullName}");

      // Clear fields
      _nameC.clear();
      _matricC.clear();
      _emailC.clear();
      _phoneC.clear();
      setState(() {
        _selectedFacultyName = null;
        _selectedDepartmentName = null;
        _selectedProgrammeName = null;
      });

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      });
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
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                ),
              ),
              child: const Center(
                child: Text(
                  "Student Sign Up",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
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
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
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
                      validator: (v) => v == null || v.isEmpty
                          ? "Enter your full name"
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Matric number
                    TextFormField(
                      controller: _matricC,
                      decoration: _inputDecoration(
                        "Matric Number",
                        Icons.badge,
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Enter matric number" : null,
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
                      decoration: _inputDecoration("Phone Number", Icons.phone),
                      validator: (v) => v == null || v.length < 10
                          ? "Enter a valid phone number"
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Faculty
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration("Faculty", Icons.school),
                      value: _selectedFacultyName,
                      isExpanded: true,
                      items: allFaculties
                          .map(
                            (f) => DropdownMenuItem(
                              value: f.facultyName,
                              child: Text(
                                f.facultyName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedFacultyName = val;
                          _selectedDepartmentName = null;
                          _selectedProgrammeName = null;
                        });
                      },
                      validator: (v) => v == null ? "Select faculty" : null,
                    ),
                    const SizedBox(height: 16),

                    // Department
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration(
                        "Department",
                        Icons.apartment,
                      ),
                      value: _selectedDepartmentName,
                      isExpanded: true,
                      // Only show items if mapped correctly
                      items: _availableDepartments.map((d) {
                        return DropdownMenuItem(
                          value: d.departmentName,
                          child: Text(
                            d.departmentName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _selectedFacultyName == null
                          ? null // Disable if faculty not selected
                          : (val) {
                              setState(() {
                                _selectedDepartmentName = val;
                                _selectedProgrammeName = null;
                              });
                            },
                      validator: (v) => v == null ? "Select department" : null,
                      hint: _selectedFacultyName == null
                          ? const Text("Select Faculty first")
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Programme (Course)
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration(
                        "Programme",
                        Icons.menu_book,
                      ),
                      value: _selectedProgrammeName,
                      isExpanded: true,
                      items: _availableProgrammes.map((p) {
                        return DropdownMenuItem(
                          value: p.programmeName,
                          child: Text(
                            p.programmeName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _selectedDepartmentName == null
                          ? null
                          : (val) {
                              setState(() => _selectedProgrammeName = val);
                            },
                      validator: (v) => v == null ? "Select programme" : null,
                      hint: _selectedDepartmentName == null
                          ? const Text("Select Department first")
                          : null,
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
