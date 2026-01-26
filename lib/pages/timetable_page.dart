import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/timetable_entry.dart';
import '../widgets/timetable_dialog.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
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

  late Box<TimetableEntry> _timetableBox;

  @override
  void initState() {
    super.initState();
    _timetableBox = Hive.box<TimetableEntry>('timetable');
  }

  TimetableEntry? _getEntry(String day, String timeSlot) {
    try {
      return _timetableBox.values.firstWhere(
        (e) => e.day == day && e.timeSlot == timeSlot,
      );
    } catch (e) {
      return null;
    }
  }

  void _manageEntry(String day, String timeSlot) async {
    final existingEntry = _getEntry(day, timeSlot);

    final result = await showDialog(
      context: context,
      builder: (context) => TimetableDialog(
        day: day,
        timeSlot: timeSlot,
        existingEntry: existingEntry,
      ),
    );

    if (result == 'delete') {
      if (existingEntry != null) {
        await existingEntry.delete(); // Delete from Hive
        setState(() {}); // Refresh UI
      }
    } else if (result is TimetableEntry) {
      if (existingEntry != null) {
        // Update existing logic is tricky with HiveObject unless we used key.
        // Easiest is to delete old and add new, or if we had a stable key.
        // Since we query by props, let's delete old matched one first if strictly replacing slot.
        await existingEntry.delete();
      }
      await _timetableBox.add(result);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Lecture Time Table'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder(
        valueListenable: _timetableBox.listenable(),
        builder: (context, Box<TimetableEntry> box, _) {
          // Helper to get entry from the current box state
          TimetableEntry? getEntry(String d, String t) {
            try {
              return box.values.firstWhere(
                (e) => e.day == d && e.timeSlot == t,
              );
            } catch (e) {
              return null;
            }
          }

          final entries = box.values.toList();

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Timetable Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color.fromARGB(255, 187, 251, 206),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Table(
                          defaultColumnWidth: const FixedColumnWidth(100.0),
                          columnWidths: const {
                            0: FixedColumnWidth(60.0), // Day column width
                          },
                          border: TableBorder.all(
                            color: Colors.green.shade200,
                            width: 1,
                            style: BorderStyle.solid,
                          ),
                          children: [
                            // Header Row
                            TableRow(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 2, 87, 23),
                              ),
                              children: [
                                const TableCell(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'Day',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white
                                      ),
                                    ),
                                  ),
                                ),
                                ..._timeSlots.map(
                                  (time) => TableCell(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                        child: Text(
                                          time,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Data Rows
                            ..._days.map((day) {
                              return TableRow(
                                children: [
                                  // Day Column
                                  Container(
                                    color: const Color.fromARGB(255, 2, 87, 23),
                                    height: 30,
                                    alignment: Alignment.center,
                                    child: Text(
                                      day,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  // Time Slots
                                  ..._timeSlots.map((time) {
                                    final entry = getEntry(day, time);
                                    return TableCell(
                                      child: InkWell(
                                        onTap: () => _manageEntry(day, time),
                                        child: Container(
                                          height: 30,
                                          color: entry != null
                                              ? const Color.fromARGB(255, 188, 245, 202)
                                              : Colors.white,
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.all(4),
                                          child: entry != null
                                              ? Text(
                                                  entry.courseCode,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Course Descriptions Table
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Course Descriptions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          const Color.fromARGB(255, 2, 87, 23),
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              'S/N',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Course Code',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Course Title',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Lecturer Name',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                        rows: entries.isEmpty
                            ? []
                            : List.generate(entries.length, (index) {
                                final e = entries[index];
                                return DataRow(
                                  color: WidgetStateProperty.all(Colors.white),
                                  cells: [
                                    DataCell(Text((index + 1).toString())),
                                    DataCell(Text(e.courseCode)),
                                    DataCell(Text(e.courseTitle)),
                                    DataCell(Text(e.lecturerName)),
                                  ],
                                );
                              }),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
