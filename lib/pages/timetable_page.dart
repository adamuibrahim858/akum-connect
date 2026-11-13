import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/timetable_entry.dart';
import '../services/lecture_notification_service.dart';
import '../widgets/timetable_dialog.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> with SingleTickerProviderStateMixin {
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
  late TabController _dayTabController;
  bool _isWeeklyGridView = false; // Toggle between Daily Agenda & Weekly Table Matrix

  @override
  void initState() {
    super.initState();
    _timetableBox = Hive.box<TimetableEntry>('timetable');

    // Automatically default to today's day of week
    int initialDayIndex = _getTodayIndex();
    _dayTabController = TabController(
      length: _days.length,
      vsync: this,
      initialIndex: initialDayIndex,
    );
  }

  @override
  void dispose() {
    _dayTabController.dispose();
    super.dispose();
  }

  int _getTodayIndex() {
    final weekday = DateTime.now().weekday; // 1 = Mon, ..., 6 = Sat, 7 = Sun
    if (weekday >= 1 && weekday <= 6) {
      return weekday - 1;
    }
    return 0; // Default to Monday on Sundays
  }

  TimetableEntry? _getEntry(String day, String timeSlot) {
    try {
      return _timetableBox.values.firstWhere(
        (e) => e.day == day && e.timeSlot == timeSlot,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _manageEntry(String day, String timeSlot) async {
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
        await existingEntry.delete();
        _syncNotifications();
        if (mounted) setState(() {});
      }
    } else if (result is TimetableEntry) {
      if (existingEntry != null) {
        await existingEntry.delete();
      }
      await _timetableBox.add(result);
      _syncNotifications();
      if (mounted) setState(() {});
    }
  }

  Future<void> _addNewClass() async {
    final currentDay = _days[_dayTabController.index];
    await _manageEntry(currentDay, '8-9');
  }

  void _syncNotifications() {
    try {
      final entries = _timetableBox.values.toList();
      LectureNotificationService.scheduleNotifications(entries);
    } catch (_) {}
  }

  Future<void> _loadSampleSchedule() async {
    final sampleClasses = [
      TimetableEntry(
        day: 'MON',
        timeSlot: '8-9',
        courseCode: 'CSC 301',
        courseTitle: 'Data Structures & Algorithms',
        lecturerName: 'Dr. Ibrahim Aliyu',
        venue: 'Computing Lab 1, West Campus',
      ),
      TimetableEntry(
        day: 'MON',
        timeSlot: '10-11',
        courseCode: 'MTH 201',
        courseTitle: 'Mathematical Methods I',
        lecturerName: 'Prof. Bello Abubakar',
        venue: 'Lecture Theatre A',
      ),
      TimetableEntry(
        day: 'TUE',
        timeSlot: '9-10',
        courseCode: 'CSC 305',
        courseTitle: 'Database Management Systems',
        lecturerName: 'Dr. Fatima Zahra',
        venue: 'Software Eng Lab',
      ),
      TimetableEntry(
        day: 'TUE',
        timeSlot: '11-12',
        courseCode: 'GST 311',
        courseTitle: 'Entrepreneurship & Innovation',
        lecturerName: 'Dr. Usman Danladi',
        venue: 'University Main Auditorium',
      ),
      TimetableEntry(
        day: 'WED',
        timeSlot: '8-9',
        courseCode: 'CSC 303',
        courseTitle: 'Operating Systems & Architecture',
        lecturerName: 'Engr. Samuel Okafor',
        venue: 'Hardware Lab',
      ),
      TimetableEntry(
        day: 'WED',
        timeSlot: '2-3',
        courseCode: 'STA 201',
        courseTitle: 'Probability & Statistics for Engineers',
        lecturerName: 'Dr. Halima Garba',
        venue: 'Science Hall 2',
      ),
      TimetableEntry(
        day: 'THU',
        timeSlot: '10-11',
        courseCode: 'CSC 307',
        courseTitle: 'Web Technologies & Mobile Apps',
        lecturerName: 'Dr. David Adeleke',
        venue: 'Tech Innovation Hub',
      ),
      TimetableEntry(
        day: 'FRI',
        timeSlot: '9-10',
        courseCode: 'CSC 309',
        courseTitle: 'Artificial Intelligence & Machine Learning',
        lecturerName: 'Dr. Aisha Mohammed',
        venue: 'AI Lab, ICT Complex',
      ),
    ];

    await _timetableBox.clear();
    for (final c in sampleClasses) {
      await _timetableBox.add(c);
    }
    _syncNotifications();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sample semester schedule loaded successfully!'),
          backgroundColor: Color(0xFF1B5E20),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewClass,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Class', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 3,
      ),
      body: ValueListenableBuilder(
        valueListenable: _timetableBox.listenable(),
        builder: (context, Box<TimetableEntry> box, _) {
          final entries = box.values.toList();

          if (entries.isEmpty) {
            return _buildEmptyState();
          }

          if (_isWeeklyGridView) {
            return _buildWeeklyMatrixGrid(entries);
          }

          return _buildDailyAgendaView(entries);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1B5E20),
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Row(
        children: [
          Icon(Icons.calendar_month_rounded, size: 22, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Lecture Timetable',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        // View Toggle (Daily Agenda vs Weekly Matrix Grid)
        IconButton(
          tooltip: _isWeeklyGridView ? 'Switch to Daily View' : 'Switch to Weekly Grid',
          icon: Icon(_isWeeklyGridView ? Icons.view_day_rounded : Icons.grid_view_rounded),
          onPressed: () {
            setState(() => _isWeeklyGridView = !_isWeeklyGridView);
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (val) {
            if (val == 'sample') _loadSampleSchedule();
            if (val == 'clear') _confirmClearTimetable();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'sample',
              child: Row(
                children: [
                  Icon(Icons.auto_stories_rounded, color: Color(0xFF1B5E20), size: 18),
                  SizedBox(width: 8),
                  Text('Load Sample Schedule'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Text('Clear Entire Timetable'),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: _isWeeklyGridView
          ? null
          : TabBar(
              controller: _dayTabController,
              isScrollable: false,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: _days.map((day) {
                final dayEntriesCount = _timetableBox.values.where((e) => e.day == day).length;
                return Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(day),
                      if (dayEntriesCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$dayEntriesCount',
                            style: const TextStyle(fontSize: 9, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  // Daily Schedule Agenda View
  Widget _buildDailyAgendaView(List<TimetableEntry> allEntries) {
    return TabBarView(
      controller: _dayTabController,
      children: _days.map((day) {
        final dayClasses = allEntries.where((e) => e.day == day).toList();

        // Sort chronologically by slot order
        dayClasses.sort((a, b) {
          final idxA = _timeSlots.indexOf(a.timeSlot);
          final idxB = _timeSlots.indexOf(b.timeSlot);
          return idxA.compareTo(idxB);
        });

        if (dayClasses.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.weekend_rounded, size: 48, color: Color(0xFF1B5E20)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Classes Scheduled on $day',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enjoy your lecture-free day or tap "+" below to add a class.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: dayClasses.length,
          itemBuilder: (context, index) {
            final entry = dayClasses[index];
            return _buildTimelineClassCard(entry);
          },
        );
      }).toList(),
    );
  }

  // Timeline Lecture Card
  Widget _buildTimelineClassCard(TimetableEntry entry) {
    final status = _determineSlotStatus(entry.timeSlot, entry.day);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'LIVE NOW' ? const Color(0xFF1B5E20) : const Color(0xFFE2E8F0),
          width: status == 'LIVE NOW' ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _manageEntry(entry.day, entry.timeSlot),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Time Badge & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF475569)),
                        const SizedBox(width: 6),
                        Text(
                          _formatSlot(entry.timeSlot),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status Chip
                  if (status == 'LIVE NOW')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFA5D6A7)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.fiber_manual_record, size: 10, color: Color(0xFF1B5E20)),
                          SizedBox(width: 4),
                          Text(
                            'LIVE NOW',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF94A3B8)),
                      onSelected: (val) {
                        if (val == 'edit') _manageEntry(entry.day, entry.timeSlot);
                        if (val == 'delete') _deleteEntry(entry);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18, color: Color(0xFF1B5E20)),
                              SizedBox(width: 8),
                              Text('Edit Class'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete Class'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Course Code & Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.courseCode,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.courseTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 13, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                entry.lecturerName,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 24, color: Color(0xFFF1F5F9)),

              // Venue Footnote
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFF1B5E20)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entry.venue,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _manageEntry(entry.day, entry.timeSlot),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Edit', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1B5E20),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Weekly Matrix Grid View
  Widget _buildWeeklyMatrixGrid(List<TimetableEntry> entries) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.touch_app_rounded, size: 18, color: Color(0xFF1B5E20)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Scroll horizontally to view all time slots. Tap any slot to add or edit a lecture.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1B5E20), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Horizontal scrollable table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Table(
                defaultColumnWidth: const FixedColumnWidth(110.0),
                columnWidths: const {
                  0: FixedColumnWidth(64.0), // Day column
                },
                border: TableBorder.all(color: const Color(0xFFE2E8F0)),
                children: [
                  // Header Row
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFF1B5E20)),
                    children: [
                      const TableCell(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: Center(
                            child: Text(
                              'Day',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                      ..._timeSlots.map(
                        (slot) => TableCell(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                            child: Center(
                              child: Text(
                                _formatSlot(slot),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
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
                        // Day Cell
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Container(
                            color: const Color(0xFFF1F5F9),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                day,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Time Slots
                        ..._timeSlots.map((time) {
                          final entry = _getEntry(day, time);
                          final hasClass = entry != null;

                          return TableCell(
                            child: InkWell(
                              onTap: () => _manageEntry(day, time),
                              child: Container(
                                height: 56,
                                padding: const EdgeInsets.all(4),
                                color: hasClass ? const Color(0xFFE8F5E9) : Colors.white,
                                child: hasClass
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            entry.courseCode,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: Color(0xFF1B5E20),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          Text(
                                            entry.venue,
                                            style: const TextStyle(
                                              fontSize: 8,
                                              color: Color(0xFF64748B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      )
                                    : const Center(
                                        child: Icon(Icons.add, size: 14, color: Color(0xFFCBD5E1)),
                                      ),
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

          const SizedBox(height: 28),

          // Course Catalog Summary Table
          const Text(
            'Enrolled Course Catalog',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          _buildCourseCatalog(entries),
        ],
      ),
    );
  }

  Widget _buildCourseCatalog(List<TimetableEntry> entries) {
    // Distinct courses
    final Map<String, TimetableEntry> distinct = {};
    for (var e in entries) {
      distinct[e.courseCode] = e;
    }
    final courseList = distinct.values.toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: courseList.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final c = courseList[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE8F5E9),
              child: Text(
                c.courseCode.substring(0, 3),
                style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              '${c.courseCode}: ${c.courseTitle}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Lecturer: ${c.lecturerName} • Venue: ${c.venue}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          );
        },
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_note_rounded, size: 54, color: Color(0xFF1B5E20)),
            ),
            const SizedBox(height: 18),
            const Text(
              'Your Timetable is Empty',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Schedule your lectures to get automatic class reminders before each session.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _addNewClass,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Class'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _loadSampleSchedule,
                  icon: const Icon(Icons.auto_stories_rounded, size: 18),
                  label: const Text('Load Sample Schedule'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1B5E20),
                    side: const BorderSide(color: Color(0xFF1B5E20)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _deleteEntry(TimetableEntry entry) async {
    await entry.delete();
    _syncNotifications();
    if (mounted) setState(() {});
  }

  void _confirmClearTimetable() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Classes?'),
        content: const Text('This will delete all scheduled lectures from your timetable.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _timetableBox.clear();
              _syncNotifications();
              if (mounted) {
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('CLEAR ALL'),
          ),
        ],
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

  String _determineSlotStatus(String slot, String day) {
    final now = DateTime.now();
    final todayDayStr = _days[_getTodayIndex()];
    if (day != todayDayStr) return 'UPCOMING';

    final parts = slot.split('-');
    if (parts.length != 2) return 'UPCOMING';
    int startHour = int.tryParse(parts[0]) ?? 8;
    int endHour = int.tryParse(parts[1]) ?? 9;

    // Convert 12h to 24h
    int to24(int h) {
      if (h >= 1 && h <= 6) return h + 12;
      return h;
    }

    final s24 = to24(startHour);
    final e24 = to24(endHour);

    final currentHour = now.hour;
    if (currentHour >= s24 && currentHour < e24) {
      return 'LIVE NOW';
    } else if (currentHour < s24) {
      return 'UPCOMING';
    } else {
      return 'COMPLETED';
    }
  }
}
