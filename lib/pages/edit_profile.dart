import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:akum_connet/data/courses.dart';
import '../models/student_info.dart';

class EditProfilePage extends StatefulWidget {
  final Student student;
  final int index; // Hive index

  const EditProfilePage({
    super.key,
    required this.student,
    required this.index,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameC;
  late TextEditingController _matricC;
  late TextEditingController _emailC;
  late TextEditingController _phoneC;

  // Replaced Controllers with String state variables for dropdowns
  String? _selectedFacultyName;
  String? _selectedDepartmentName;
  String? _selectedProgrammeName;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _nameC = TextEditingController(text: s.fullName);
    _matricC = TextEditingController(text: s.matricNo);
    _emailC = TextEditingController(text: s.email);
    _phoneC = TextEditingController(text: s.phone);

    // Initialize dropdowns
    _selectedFacultyName = s.faculty;
    _selectedDepartmentName = s.department;
    _selectedProgrammeName = s.course;
  }

  // Helpers to get lists based on selection (Consistent with Signup logic)
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
      final faculty = allFaculties.firstWhere(
        (f) => f.facultyName == _selectedFacultyName,
        orElse: () => allFaculties.first, // fallback safe-guard
      );
      return faculty.departments
          .firstWhere((d) => d.departmentName == _selectedDepartmentName)
          .programmes;
    } catch (e) {
      return [];
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

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFacultyName == null ||
        _selectedDepartmentName == null ||
        _selectedProgrammeName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all academic fields')),
      );
      return;
    }

    final box = Hive.box<Student>('students');

    final updatedStudent = Student(
      fullName: _nameC.text.trim(),
      matricNo: _matricC.text.trim(),
      email: _emailC.text.trim(),
      phone: _phoneC.text.trim(),
      faculty: _selectedFacultyName!,
      department: _selectedDepartmentName!,
      course: _selectedProgrammeName!,
    );

    await box.putAt(widget.index, updatedStudent);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully ✅')),
      );
      Navigator.pop(context); // Return to profile page
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
    fillColor: Colors.grey[100],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameC,
                decoration: _dec('Full Name', Icons.person),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _matricC,
                decoration: _dec('Matric Number', Icons.badge),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailC,
                decoration: _dec('Email', Icons.email),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneC,
                decoration: _dec('Phone', Icons.phone),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),

              // FACULTY DROPDOWN
              DropdownButtonFormField<String>(
                decoration: _dec("Faculty", Icons.school),
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
                    // Reset children
                    _selectedDepartmentName = null;
                    _selectedProgrammeName = null;
                  });
                },
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 10),

              // DEPARTMENT DROPDOWN
              DropdownButtonFormField<String>(
                decoration: _dec("Department", Icons.computer),
                value: _selectedDepartmentName,
                isExpanded: true,
                items: _availableDepartments
                    .map(
                      (d) => DropdownMenuItem(
                        value: d.departmentName,
                        child: Text(
                          d.departmentName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _selectedFacultyName == null
                    ? null
                    : (val) {
                        setState(() {
                          _selectedDepartmentName = val;
                          // Reset child
                          _selectedProgrammeName = null;
                        });
                      },
                validator: (v) => v == null ? 'Required' : null,
                hint: _selectedFacultyName == null
                    ? const Text("Select Faculty first")
                    : null,
              ),
              const SizedBox(height: 10),

              // PROGRAMME DROPDOWN
              DropdownButtonFormField<String>(
                decoration: _dec("Programme", Icons.book),
                value: _selectedProgrammeName,
                isExpanded: true,
                items: _availableProgrammes
                    .map(
                      (p) => DropdownMenuItem(
                        value: p.programmeName,
                        child: Text(
                          p.programmeName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _selectedDepartmentName == null
                    ? null
                    : (val) {
                        setState(() {
                          _selectedProgrammeName = val;
                        });
                      },
                validator: (v) => v == null ? 'Required' : null,
                hint: _selectedDepartmentName == null
                    ? const Text("Select Department first")
                    : null,
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
