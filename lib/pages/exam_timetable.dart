import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/exam_model.dart';
import '../services/exam_notification_service.dart';

class ExamTimetablePage extends StatefulWidget {
  const ExamTimetablePage({super.key});

  @override
  State<ExamTimetablePage> createState() => _ExamTimetablePageState();
}

class _ExamTimetablePageState extends State<ExamTimetablePage> {
  late Box<ExamModel> _examBox;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _examBox = Hive.box<ExamModel>('exams');
    // Tick every minute to update statuses/countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _addOrEditExam({ExamModel? existingExam}) async {
    final result = await showDialog(
      context: context,
      builder: (context) => ExamDialog(existingExam: existingExam),
    );

    if (result != null && result is ExamModel) {
      if (existingExam != null) {
        final key = _examBox.keys.firstWhere(
          (k) => _examBox.get(k)?.id == existingExam.id,
          orElse: () => null,
        );
        if (key != null) {
          _examBox.put(key, result);
        } else {
          _examBox.add(result);
        }
        // Cancel old notifications and schedule new ones
        await ExamNotificationService.cancelExamNotifications(existingExam);
        await ExamNotificationService.scheduleExamNotifications(result);
      } else {
        _examBox.add(result);
        await ExamNotificationService.scheduleExamNotifications(result);
      }
    }
  }

  void _removeExam(ExamModel exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Exam'),
        content: Text('Are you sure you want to remove ${exam.courseCode}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              await ExamNotificationService.cancelExamNotifications(exam);
              await exam.delete();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Exam Timetable'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder(
        valueListenable: _examBox.listenable(),
        builder: (context, Box<ExamModel> box, _) {
          final exams = box.values.toList();

          if (exams.isEmpty) {
            return const Center(
              child: Text('No exams scheduled. Tap + to add completely.'),
            );
          }

          // Optional: Sort exams by date?
          exams.sort((a, b) => a.date.compareTo(b.date));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: exams.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final exam = exams[index];
              return ExamCard(
                exam: exam,
                onEdit: () => _addOrEditExam(existingExam: exam),
                onRemove: () => _removeExam(exam),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditExam(),
        backgroundColor: Colors.green,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class ExamCard extends StatelessWidget {
  final ExamModel exam;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const ExamCard({
    super.key,
    required this.exam,
    required this.onEdit,
    required this.onRemove,
  });

  Map<String, dynamic> _getStatus(ExamModel exam) {
    final now = DateTime.now();

    // Combine date and time to get full DateTime objects
    final examDate = DateTime(exam.date.year, exam.date.month, exam.date.day);

    final startParts = exam.startTime.split(':');
    final endParts = exam.endTime.split(':');

    final startDt = DateTime(
      exam.date.year,
      exam.date.month,
      exam.date.day,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );

    final endDt = DateTime(
      exam.date.year,
      exam.date.month,
      exam.date.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );

    if (now.isAfter(endDt)) {
      return {'text': 'Exam Ended', 'color': Colors.red, 'sub': ''};
    } else if (now.isAfter(startDt) && now.isBefore(endDt)) {
      return {'text': 'In Exam', 'color': Colors.green, 'sub': 'Good Luck!'};
    } else {
      // Upcoming - Calculate countdown
      final diff = startDt.difference(now);
      String countdown = '';
      if (diff.inDays > 0) {
        countdown = '${diff.inDays}d ${diff.inHours % 24}h Left';
      } else {
        countdown =
            '${diff.inHours}h ${diff.inMinutes % 60}m ${diff.inSeconds % 60}s';
      }
      return {'text': 'Upcoming', 'color': Colors.orange, 'sub': countdown};
    }
  }

  String _formatTimeStr(String timeStr, BuildContext context) {
    final parts = timeStr.split(':');
    final time = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    return time.format(context);
  }

  @override
  Widget build(BuildContext context) {
    final statusData = _getStatus(exam);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (statusData['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusData['color'] as Color),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 14,
                        color: statusData['color'] as Color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusData['text'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusData['color'] as Color,
                          fontSize: 12,
                        ),
                      ),
                      if (statusData['sub'].toString().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          "|  ${statusData['sub']}",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: statusData['color'] as Color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'remove') onRemove();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Remove'),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Two Column Layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column 1: Course & Venue
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Course Code",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        exam.courseCode,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Venue",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              exam.venue,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Vertical Divider
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),

                // Column 2: Date & Time
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Date",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        DateFormat('EEE, dd MMM').format(exam.date),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Time",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        "${_formatTimeStr(exam.startTime, context)} \n ${_formatTimeStr(exam.endTime, context)}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ExamDialog extends StatefulWidget {
  final ExamModel? existingExam;

  const ExamDialog({super.key, this.existingExam});

  @override
  State<ExamDialog> createState() => _ExamDialogState();
}

class _ExamDialogState extends State<ExamDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _venueController;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(
      text: widget.existingExam?.courseCode ?? '',
    );
    _venueController = TextEditingController(
      text: widget.existingExam?.venue ?? '',
    );
    _selectedDate = widget.existingExam?.date ?? DateTime.now();
    _startTime = widget.existingExam != null
        ? widget.existingExam!.startTimeToTimeOfDay
        : const TimeOfDay(hour: 9, minute: 0);
    _endTime = widget.existingExam != null
        ? widget.existingExam!.endTimeToTimeOfDay
        : const TimeOfDay(hour: 12, minute: 0);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour}:${time.minute}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingExam == null ? 'Add Exam' : 'Edit Exam'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Course Code',
                  hintText: 'e.g. MTH 201',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.book),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Time',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_startTime.format(context)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickTime(false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Time',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_endTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _venueController,
                decoration: const InputDecoration(
                  labelText: 'Venue',
                  hintText: 'e.g. Hall B',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newExam = ExamModel(
                id:
                    widget.existingExam?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                courseCode: _codeController.text,
                date: _selectedDate,
                startTime: _formatTimeOfDay(_startTime),
                endTime: _formatTimeOfDay(_endTime),
                venue: _venueController.text,
              );
              Navigator.pop(context, newExam);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('SAVE'),
        ),
      ],
    );
  }
}
