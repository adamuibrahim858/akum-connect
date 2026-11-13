import 'package:flutter/material.dart';
import '../models/timetable_entry.dart';

class TimetableDialog extends StatefulWidget {
  final String day;
  final String timeSlot;
  final TimetableEntry? existingEntry;

  const TimetableDialog({
    super.key,
    required this.day,
    required this.timeSlot,
    this.existingEntry,
  });

  @override
  State<TimetableDialog> createState() => _TimetableDialogState();
}

class _TimetableDialogState extends State<TimetableDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedDay;
  late String _selectedTimeSlot;

  late TextEditingController _codeController;
  late TextEditingController _titleController;
  late TextEditingController _lecturerController;
  late TextEditingController _venueController;

  final List<String> _days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
  final List<String> _timeSlots = [
    '8-9',
    '9-10',
    '10-11',
    '11-12',
    '12-1',
    '1-2',
    '2-3',
    '3-4',
    '4-5',
    '5-6',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.existingEntry?.day ?? widget.day;
    _selectedTimeSlot = widget.existingEntry?.timeSlot ?? widget.timeSlot;

    _codeController = TextEditingController(
      text: widget.existingEntry?.courseCode ?? '',
    );
    _titleController = TextEditingController(
      text: widget.existingEntry?.courseTitle ?? '',
    );
    _lecturerController = TextEditingController(
      text: widget.existingEntry?.lecturerName ?? '',
    );
    _venueController = TextEditingController(
      text: widget.existingEntry?.venue ?? '',
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _lecturerController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingEntry != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.school_rounded, color: Color(0xFF1B5E20), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Lecture Class' : 'Schedule New Class',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            isEditing ? 'Update lecture schedule details' : 'Add class to your timetable',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // Day & Time Selectors Row
                Row(
                  children: [
                    // Day Selector
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedDay,
                        decoration: _inputDecoration(
                          label: 'Day',
                          icon: Icons.calendar_today_rounded,
                        ),
                        items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedDay = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Time Slot Selector
                    Expanded(
                      flex: 5,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedTimeSlot,
                        decoration: _inputDecoration(
                          label: 'Time Slot',
                          icon: Icons.access_time_rounded,
                        ),
                        items: _timeSlots
                            .map((t) => DropdownMenuItem(value: t, child: Text('$t (${_formatSlot(t)})')))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedTimeSlot = val);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Course Code
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _inputDecoration(
                    label: 'Course Code',
                    hint: 'e.g. CSC 301 or MTH 201',
                    icon: Icons.badge_outlined,
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter course code' : null,
                ),

                const SizedBox(height: 14),

                // Course Title
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    label: 'Course Title',
                    hint: 'e.g. Data Structures & Algorithms',
                    icon: Icons.menu_book_rounded,
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter course title' : null,
                ),

                const SizedBox(height: 14),

                // Lecturer Name
                TextFormField(
                  controller: _lecturerController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    label: 'Lecturer Name',
                    hint: 'e.g. Dr. Aliyu or Prof. Bello',
                    icon: Icons.person_outline_rounded,
                  ),
                ),

                const SizedBox(height: 14),

                // Venue
                TextFormField(
                  controller: _venueController,
                  decoration: _inputDecoration(
                    label: 'Lecture Venue / Hall',
                    hint: 'e.g. LT 1, Faculty of Science',
                    icon: Icons.location_on_outlined,
                  ),
                ),

                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    if (isEditing)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context, 'delete'),
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          label: const Text('Delete', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    if (isEditing) const SizedBox(width: 10),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final entry = TimetableEntry(
                              day: _selectedDay,
                              timeSlot: _selectedTimeSlot,
                              courseCode: _codeController.text.trim().toUpperCase(),
                              courseTitle: _titleController.text.trim(),
                              lecturerName: _lecturerController.text.trim().isEmpty
                                  ? 'Department Lecturer'
                                  : _lecturerController.text.trim(),
                              venue: _venueController.text.trim().isEmpty
                                  ? 'Lecture Hall'
                                  : _venueController.text.trim(),
                            );
                            Navigator.pop(context, entry);
                          }
                        },
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          isEditing ? 'Save Changes' : 'Add Class',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatSlot(String slot) {
    final parts = slot.split('-');
    if (parts.length != 2) return slot;
    int s = int.tryParse(parts[0]) ?? 8;
    int e = int.tryParse(parts[1]) ?? 9;

    String formatHour(int h) {
      if (h >= 8 && h <= 11) return '$h AM';
      if (h == 12) return '12 PM';
      return '$h PM';
    }

    return '${formatHour(s)} - ${formatHour(e)}';
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 18, color: const Color(0xFF1B5E20)) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.8),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      isDense: true,
    );
  }
}
