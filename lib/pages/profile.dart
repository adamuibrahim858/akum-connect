import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/student_info.dart';
import 'edit_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Brand colours (reuse the app's green palette)
  static const Color _primaryGreen = Color(0xFF1B6B35);
  static const Color _lightGreen = Color(0xFFE8F5ED);
  static const Color _pageBg = Color(0xFFF4F6F8);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _navigateToEdit(BuildContext context, Student student, int index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(student: student, index: index),
      ),
    );
    // The ValueListenableBuilder will automatically rebuild with fresh data.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 16,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ValueListenableBuilder<Box<Student>>(
              valueListenable: Hive.box<Student>('students').listenable(),
              builder: (context, box, _) {
                if (box.isEmpty) return const SizedBox.shrink();
                final studentIndex = box.length - 1;
                final student = box.getAt(studentIndex)!;
                return IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  onPressed: () =>
                      _navigateToEdit(context, student, studentIndex),
                );
              },
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<Student>>(
        valueListenable: Hive.box<Student>('students').listenable(),
        builder: (context, box, _) {
          if (box.isEmpty) {
            return _buildEmptyState(context);
          }

          final studentIndex = box.length - 1;
          final student = box.getAt(studentIndex)!;

          return FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: CustomScrollView(
                slivers: [
                  // Hero Header
                  SliverToBoxAdapter(
                    child: _ProfileHeader(
                      student: student,
                      studentIndex: studentIndex,
                      onEditTap: () =>
                          _navigateToEdit(context, student, studentIndex),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 20),

                        // ── Academic Section ───────────────────────────────
                        _SectionCard(
                          icon: Icons.school_rounded,
                          iconBgColor: const Color(0xFFE8F5ED),
                          iconColor: _primaryGreen,
                          title: 'Academic Details',
                          children: [
                            _InfoTile(
                              icon: Icons.account_balance_outlined,
                              label: 'Institution',
                              value: 'Abdulkadir Kure University',
                            ),
                            _InfoTile(
                              icon: Icons.account_balance_outlined,
                              label: 'Faculty',
                              value: student.faculty,
                            ),
                            _InfoTile(
                              icon: Icons.apartment_outlined,
                              label: 'Department',
                              value: student.department,
                            ),
                            _InfoTile(
                              icon: Icons.menu_book_outlined,
                              label: 'Programme',
                              value: student.course,
                            ),
                            _InfoTile(
                              icon: Icons.badge_outlined,
                              label: 'Matriculation No.',
                              value: student.matricNo,
                              copyable: true,
                            ),
                            _InfoTile(
                              icon: Icons.timeline_outlined,
                              label: 'Academic Level',
                              value:
                                  (student.level != null &&
                                      student.level!.isNotEmpty)
                                  ? student.level!
                                  : 'Undergraduate',
                              isLast: true,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Contact Section ────────────────────────────────
                        _SectionCard(
                          icon: Icons.contact_mail_outlined,
                          iconBgColor: const Color(0xFFE3F2FD),
                          iconColor: const Color(0xFF1565C0),
                          title: 'Contact Information',
                          children: [
                            _InfoTile(
                              icon: Icons.person_outline,
                              label: 'Full Name',
                              value: student.fullName,
                            ),
                            _InfoTile(
                              icon: Icons.alternate_email_outlined,
                              label: 'Email Address',
                              value: student.email,
                              copyable: true,
                            ),
                            _InfoTile(
                              icon: Icons.phone_outlined,
                              label: 'Phone Number',
                              value: student.phone,
                              isLast: true,
                              copyable: true,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Institutional Status ───────────────────────────
                        _SectionCard(
                          icon: Icons.verified_user_outlined,
                          iconBgColor: const Color(0xFFFFF8E1),
                          iconColor: const Color(0xFFE65100),
                          title: 'Institutional Status',
                          children: [
                            _InfoTile(
                              icon: Icons.fiber_manual_record_rounded,
                              label: 'Account Status',
                              value: 'Active Student',
                              valueColor: Color(0xFF2E9E56),
                            ),
                            _InfoTile(
                              icon: Icons.calendar_today_outlined,
                              label: 'Academic Session',
                              value: '2025/2026 Academic Session',
                              isLast: true,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Action Buttons ─────────────────────────────────
                        _ActionButton(
                          icon: Icons.edit_outlined,
                          label: 'Edit Profile Information',
                          foreground: _primaryGreen,
                          borderColor: _primaryGreen,
                          onTap: () =>
                              _navigateToEdit(context, student, studentIndex),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _lightGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_off_outlined,
                size: 56,
                color: _primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Profile Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Please register to view and manage your university profile.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/signup'),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Register Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Header Widget
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final Student student;
  final int studentIndex;
  final VoidCallback onEditTap;

  static const Color _primaryGreen = Color(0xFF1B6B35);

  const _ProfileHeader({
    required this.student,
    required this.studentIndex,
    required this.onEditTap,
  });

  bool get _hasImage =>
      student.profileImagePath != null &&
      student.profileImagePath!.isNotEmpty &&
      File(student.profileImagePath!).existsSync();

  @override
  Widget build(BuildContext context) {
    final levelText = (student.level != null && student.level!.isNotEmpty)
        ? student.level!
        : 'Undergraduate';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B6B35), Color(0xFF2E9E56)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -30,
              right: -30,
              child: _decorCircle(120, Colors.white.withValues(alpha: 0.05)),
            ),
            Positioned(
              top: 40,
              right: 60,
              child: _decorCircle(60, Colors.white.withValues(alpha: 0.04)),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: _decorCircle(100, Colors.white.withValues(alpha: 0.04)),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              child: Column(
                children: [
                  const SizedBox(height: 40), // space below transparent app bar
                  // Avatar
                  GestureDetector(
                    onTap: onEditTap,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 52,
                            backgroundColor: Colors.white,
                            backgroundImage: _hasImage
                                ? FileImage(File(student.profileImagePath!))
                                : null,
                            child: !_hasImage ? _buildInitialsAvatar() : null,
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 15,
                              color: _primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Full Name
                  Text(
                    student.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Course & Level
                  Text(
                    '${student.course} · $levelText',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 18),

                  // Matric Badge + Department Pill row
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _pill(icon: Icons.badge_outlined, text: student.matricNo),
                      _pill(
                        icon: Icons.apartment_outlined,
                        text: student.department,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Edit Profile Button inside header
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onEditTap,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: Colors.white54,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

  Widget _buildInitialsAvatar() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B6B35), Color(0xFF145428)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        student.initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _pill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Card Widget
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          // Children
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Tile Widget
// ─────────────────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;
  final bool copyable;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value.isNotEmpty ? value : 'Not specified';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      displayValue,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: valueColor ?? Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (copyable)
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(left: 8),
                  icon: Icon(
                    Icons.copy_outlined,
                    size: 15,
                    color: Colors.grey.shade400,
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: displayValue));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$label copied'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.all(16),
                        backgroundColor: const Color(0xFF1B6B35),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Button Widget
// ─────────────────────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foreground;
  final Color borderColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: borderColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
