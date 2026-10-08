import 'package:flutter/material.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({super.key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  String? _selectedSession;
  String? _selectedSemester;
  bool _showResult = false;

  final List<String> _sessions = ['2025', '2026', '2027'];
  final List<String> _semesters = ['First Semester', 'Second Semester'];

  void _checkResult() {
    setState(() {
      _showResult = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool canCheck = _selectedSession != null && _selectedSemester != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        backgroundColor:
            Colors.green, // Matching dashboard card color for consistency
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Session Dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Session',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              initialValue: _selectedSession,
              items: _sessions.map((session) {
                return DropdownMenuItem(value: session, child: Text(session));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSession = value;
                  _showResult = false; // Reset result when selection changes
                });
              },
            ),
            const SizedBox(height: 20),

            // Semester Dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Semester',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              initialValue: _selectedSemester,
              items: _semesters.map((semester) {
                return DropdownMenuItem(value: semester, child: Text(semester));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSemester = value;
                  _showResult = false; // Reset result when selection changes
                });
              },
            ),
            const SizedBox(height: 30),

            // Check Result Button
            ElevatedButton(
              onPressed: canCheck ? _checkResult : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canCheck ? Colors.green : Colors.grey[300],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Check Result'),
            ),

            const SizedBox(height: 40),

            // Result Message area
            if (_showResult)
              const Expanded(
                child: Center(
                  child: Text(
                    'Result not available for the selected session and semester.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            else
              const Spacer(),
          ],
        ),
      ),
    );
  }
}
