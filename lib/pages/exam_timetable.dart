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
  Timer? _countdownTimer;
  String _selectedFilter = 'All'; // All, Upcoming, Completed

  @override
  void initState() {
    super.initState();
    _examBox = Hive.box<ExamModel>('exams');

    // Live 1-second ticking timer for real-time exam countdown clocks
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
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
        await ExamNotificationService.cancelExamNotifications(existingExam);
        await ExamNotificationService.scheduleExamNotifications(result);
      } else {
        _examBox.add(result);
        await ExamNotificationService.scheduleExamNotifications(result);
      }
      if (mounted) setState(() {});
    }
  }

  void _removeExam(ExamModel exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Exam'),
        content: Text('Are you sure you want to remove ${exam.courseCode} from your exam schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ExamNotificationService.cancelExamNotifications(exam);
              await exam.delete();
              if (mounted) {
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSampleExams() async {
    final now = DateTime.now();
    final sampleExams = [
      ExamModel(
        id: '1',
        courseCode: 'CSC 301',
        date: now.add(const Duration(days: 3, hours: 2)),
        startTime: '09:00',
        endTime: '12:00',
        venue: 'University Convocation Hall, Seat A-14',
      ),
      ExamModel(
        id: '2',
        courseCode: 'MTH 201',
        date: now.add(const Duration(days: 6, hours: 5)),
        startTime: '13:00',
        endTime: '16:00',
        venue: 'Science Lecture Theatre 1',
      ),
      ExamModel(
        id: '3',
        courseCode: 'CSC 305',
        date: now.add(const Duration(days: 9, hours: 1)),
        startTime: '09:00',
        endTime: '11:30',
        venue: 'Computing Complex, Room 102',
      ),
      ExamModel(
        id: '4',
        courseCode: 'GST 311',
        date: now.add(const Duration(days: 13, hours: 4)),
        startTime: '14:00',
        endTime: '16:00',
        venue: 'E-Testing Center, West Campus',
      ),
    ];

    await _examBox.clear();
    for (final e in sampleExams) {
      await _examBox.add(e);
      await ExamNotificationService.scheduleExamNotifications(e);
    }
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sample exam schedule loaded!'),
          backgroundColor: Color(0xFF00897B),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.assignment_turned_in_rounded, size: 22, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Exam Timetable & Countdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00897B), // Teal theme for Exam Timetable
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Load Sample Schedule',
            icon: const Icon(Icons.auto_stories_rounded),
            onPressed: _loadSampleExams,
          ),
          IconButton(
            tooltip: 'Exam Hall Regulations',
            icon: const Icon(Icons.shield_outlined),
            onPressed: _showHallRulesDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditExam(),
        backgroundColor: const Color(0xFF00897B),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Exam',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 3,
      ),
      body: ValueListenableBuilder(
        valueListenable: _examBox.listenable(),
        builder: (context, Box<ExamModel> box, _) {
          final allExams = box.values.toList();

          if (allExams.isEmpty) {
            return _buildEmptyState();
          }

          // Sort exams by date ascending
          allExams.sort((a, b) => a.date.compareTo(b.date));

          // Filter
          final now = DateTime.now();
          List<ExamModel> filteredExams = allExams;
          if (_selectedFilter == 'Upcoming') {
            filteredExams = allExams.where((e) {
              final endDt = _getEndDateTime(e);
              return now.isBefore(endDt);
            }).toList();
          } else if (_selectedFilter == 'Completed') {
            filteredExams = allExams.where((e) {
              final endDt = _getEndDateTime(e);
              return now.isAfter(endDt);
            }).toList();
          }

          // Find the next upcoming exam for the hero countdown
          final upcomingExams = allExams.where((e) {
            final endDt = _getEndDateTime(e);
            return now.isBefore(endDt);
          }).toList();
          final nextExam = upcomingExams.isNotEmpty ? upcomingExams.first : null;

          return CustomScrollView(
            slivers: [
              // Hero Live Next Exam Countdown Header
              if (nextExam != null)
                SliverToBoxAdapter(
                  child: _buildNextExamHero(nextExam),
                ),

              // Filter Tabs Row
              SliverToBoxAdapter(
                child: _buildFilterTabs(allExams.length),
              ),

              // Exam List
              filteredExams.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No $_selectedFilter exams found.',
                          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final exam = filteredExams[index];
                            return _buildExamCard(exam);
                          },
                          childCount: filteredExams.length,
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  // Hero Live Next Exam Countdown Banner
  Widget _buildNextExamHero(ExamModel nextExam) {
    final now = DateTime.now();
    final startDt = _getStartDateTime(nextExam);
    final diff = startDt.difference(now);

    final isLiveNow = now.isAfter(startDt) && now.isBefore(_getEndDateTime(nextExam));
    final days = diff.inDays > 0 ? diff.inDays : 0;
    final hours = (diff.inHours % 24) > 0 ? (diff.inHours % 24) : 0;
    final mins = (diff.inMinutes % 60) > 0 ? (diff.inMinutes % 60) : 0;
    final secs = (diff.inSeconds % 60) > 0 ? (diff.inSeconds % 60) : 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF00897B), Color(0xFF26A69A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00897B).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      isLiveNow ? Icons.bolt : Icons.alarm_rounded,
                      color: Colors.amber,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isLiveNow ? 'EXAM IN PROGRESS' : 'NEXT UPCOMING EXAM',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('EEE, MMM d').format(nextExam.date),
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                nextExam.courseCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                '${nextExam.startTime} - ${nextExam.endTime}',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  nextExam.venue,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Countdown Blocks
          if (isLiveNow)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_note_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Good luck! Exam is currently in progress.',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                _buildCountdownBox('$days', 'DAYS'),
                const SizedBox(width: 8),
                _buildCountdownBox(hours.toString().padLeft(2, '0'), 'HOURS'),
                const SizedBox(width: 8),
                _buildCountdownBox(mins.toString().padLeft(2, '0'), 'MINS'),
                const SizedBox(width: 8),
                _buildCountdownBox(secs.toString().padLeft(2, '0'), 'SECS'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCountdownBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Filter Tabs
  Widget _buildFilterTabs(int totalCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('All'),
          const SizedBox(width: 8),
          _buildFilterChip('Upcoming'),
          const SizedBox(width: 8),
          _buildFilterChip('Completed'),
          const Spacer(),
          Text(
            '$totalCount Scheduled',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = label),
      selectedColor: const Color(0xFF00897B),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF475569),
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? const Color(0xFF00897B) : const Color(0xFFE2E8F0)),
      ),
      showCheckmark: false,
    );
  }

  // Modern Exam Card
  Widget _buildExamCard(ExamModel exam) {
    final status = _getExamStatus(exam);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (status['color'] as Color).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (status['color'] as Color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: (status['color'] as Color).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(status['icon'] as IconData, size: 12, color: status['color'] as Color),
                      const SizedBox(width: 4),
                      Text(
                        status['text'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: status['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF94A3B8)),
                  onSelected: (val) {
                    if (val == 'edit') _addOrEditExam(existingExam: exam);
                    if (val == 'remove') _removeExam(exam);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: Color(0xFF00897B)),
                          SizedBox(width: 8),
                          Text('Edit Exam'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Remove Exam'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Course Code & Countdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  exam.courseCode,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (status['sub'].toString().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status['sub'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: status['color'] as Color,
                      ),
                    ),
                  ),
              ],
            ),

            const Divider(height: 20, color: Color(0xFFF1F5F9)),

            // Date, Time, Venue Details
            Row(
              children: [
                // Date & Time Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF00897B)),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('EEEE, MMM d, yyyy').format(exam.date),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            '${exam.startTime} - ${exam.endTime} (${_calculateDuration(exam.startTime, exam.endTime)})',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Venue Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFF00897B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      exam.venue,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                color: Color(0xFFE0F2F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment_turned_in_rounded, size: 54, color: Color(0xFF00897B)),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Exams Scheduled',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your semester exam timetable to get live countdown timers and alarm reminders before each paper.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _addOrEditExam(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Exam'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _loadSampleExams,
                  icon: const Icon(Icons.auto_stories_rounded, size: 18),
                  label: const Text('Load Sample Schedule'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00897B),
                    side: const BorderSide(color: Color(0xFF00897B)),
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

  void _showHallRulesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Color(0xFF00897B)),
            SizedBox(width: 8),
            Text('AKUM Exam Regulations'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _RuleBullet(
                title: 'Mandatory Credentials',
                desc: 'Students must display their valid University Student ID Card and stamped Examination Clearance Card on their desk.',
              ),
              _RuleBullet(
                title: 'Prohibited Devices',
                desc: 'Smartphones, smartwatches, programmable scientific calculators, and ear pods are strictly prohibited in the exam hall.',
              ),
              _RuleBullet(
                title: 'Arrival Time',
                desc: 'Arrive at your assigned exam hall at least 30 minutes prior to paper commencement for biometric verification.',
              ),
              _RuleBullet(
                title: 'Dress Code Compliance',
                desc: 'Senate dress code rules strictly apply. Inappropriate attire will lead to disallowance from the examination hall.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF00897B)),
            child: const Text('UNDERSTOOD', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  DateTime _getStartDateTime(ExamModel exam) {
    final startParts = exam.startTime.split(':');
    return DateTime(
      exam.date.year,
      exam.date.month,
      exam.date.day,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );
  }

  DateTime _getEndDateTime(ExamModel exam) {
    final endParts = exam.endTime.split(':');
    return DateTime(
      exam.date.year,
      exam.date.month,
      exam.date.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );
  }

  Map<String, dynamic> _getExamStatus(ExamModel exam) {
    final now = DateTime.now();
    final startDt = _getStartDateTime(exam);
    final endDt = _getEndDateTime(exam);

    if (now.isAfter(endDt)) {
      return {'text': 'COMPLETED', 'color': const Color(0xFF64748B), 'icon': Icons.check_circle_outline, 'sub': ''};
    } else if (now.isAfter(startDt) && now.isBefore(endDt)) {
      return {'text': 'IN EXAM NOW', 'color': const Color(0xFF1B5E20), 'icon': Icons.bolt, 'sub': 'Good Luck!'};
    } else {
      final diff = startDt.difference(now);
      String countdown = '';
      if (diff.inDays > 0) {
        countdown = '${diff.inDays}d ${diff.inHours % 24}h Left';
      } else {
        countdown = '${diff.inHours}h ${diff.inMinutes % 60}m Left';
      }

      final isUrgent = diff.inHours < 24;
      return {
        'text': isUrgent ? 'STARTING SOON' : 'UPCOMING',
        'color': isUrgent ? Colors.redAccent : const Color(0xFFE65100),
        'icon': Icons.timer_outlined,
        'sub': countdown,
      };
    }
  }

  String _calculateDuration(String start, String end) {
    try {
      final s = start.split(':');
      final e = end.split(':');
      final sMins = int.parse(s[0]) * 60 + int.parse(s[1]);
      final eMins = int.parse(e[0]) * 60 + int.parse(e[1]);
      final diffMins = eMins - sMins;
      if (diffMins <= 0) return '2h';
      final h = diffMins ~/ 60;
      final m = diffMins % 60;
      if (m == 0) return '${h}h';
      return '${h}h ${m}m';
    } catch (_) {
      return '2h';
    }
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
    _codeController = TextEditingController(text: widget.existingExam?.courseCode ?? '');
    _venueController = TextEditingController(text: widget.existingExam?.venue ?? '');
    _selectedDate = widget.existingExam?.date ?? DateTime.now().add(const Duration(days: 7));
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
      firstDate: DateTime(2025),
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingExam != null;

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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF00897B), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Examination' : 'Schedule Exam',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            isEditing ? 'Update date, time, or venue' : 'Set paper countdown & notification',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // Course Code
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _inputDecoration(
                    label: 'Course Code',
                    hint: 'e.g. CSC 301',
                    icon: Icons.badge_outlined,
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter course code' : null,
                ),

                const SizedBox(height: 14),

                // Date Picker Tile
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF00897B)),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Examination Date', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            Text(
                              DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Time Pickers Row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickTime(true),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start Time', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              const SizedBox(height: 2),
                              Text(
                                _startTime.format(context),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickTime(false),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('End Time', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              const SizedBox(height: 2),
                              Text(
                                _endTime.format(context),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Venue
                TextFormField(
                  controller: _venueController,
                  decoration: _inputDecoration(
                    label: 'Examination Venue / Hall',
                    hint: 'e.g. Convocation Arena, Hall A',
                    icon: Icons.location_on_outlined,
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter venue' : null,
                ),

                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
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
                            String formatTimeStr(TimeOfDay t) =>
                                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

                            final exam = ExamModel(
                              id: widget.existingExam?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                              courseCode: _codeController.text.trim().toUpperCase(),
                              date: _selectedDate,
                              startTime: formatTimeStr(_startTime),
                              endTime: formatTimeStr(_endTime),
                              venue: _venueController.text.trim(),
                            );
                            Navigator.pop(context, exam);
                          }
                        },
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          isEditing ? 'Save Changes' : 'Schedule Exam',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00897B),
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

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 18, color: const Color(0xFF00897B)) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF00897B), width: 1.8),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      isDense: true,
    );
  }
}

class _RuleBullet extends StatelessWidget {
  final String title;
  final String desc;

  const _RuleBullet({required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF00897B), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.35),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
