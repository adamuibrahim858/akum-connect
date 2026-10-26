import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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

class _EditProfilePageState extends State<EditProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  late TextEditingController _nameC;
  late TextEditingController _matricC;
  late TextEditingController _emailC;
  late TextEditingController _phoneC;

  String? _selectedFacultyName;
  String? _selectedDepartmentName;
  String? _selectedProgrammeName;
  String? _selectedLevel;
  String? _profileImagePath;

  bool _isSaving = false;
  bool _hasPickedNewImage = false;

  // Page-level entry animation
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Brand colours
  static const Color _primaryGreen = Color(0xFF1B6B35);
  static const Color _pageBg = Color(0xFFF4F6F8);

  final List<String> _academicLevels = [
    '100 Level',
    '200 Level',
    '300 Level',
    '400 Level',
    '500 Level',
    'Post-Graduate',
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _nameC = TextEditingController(text: s.fullName);
    _matricC = TextEditingController(text: s.matricNo);
    _emailC = TextEditingController(text: s.email);
    _phoneC = TextEditingController(text: s.phone);

    _selectedFacultyName = s.faculty;
    _selectedDepartmentName = s.department;
    _selectedProgrammeName = s.course;
    _selectedLevel = s.level ?? '100 Level';
    _profileImagePath = s.profileImagePath;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
    _nameC.dispose();
    _matricC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ── Unsaved changes detection ──────────────────────────────────────────────
  bool get _hasUnsavedChanges {
    final s = widget.student;
    return _nameC.text.trim() != s.fullName ||
        _matricC.text.trim() != s.matricNo ||
        _emailC.text.trim() != s.email ||
        _phoneC.text.trim() != s.phone ||
        _selectedFacultyName != s.faculty ||
        _selectedDepartmentName != s.department ||
        _selectedProgrammeName != s.course ||
        _selectedLevel != (s.level ?? '100 Level') ||
        _hasPickedNewImage;
  }

  // ── Faculty / Department / Programme helpers ───────────────────────────────
  List<String> get _facultyOptions {
    final list = allFaculties.map((f) => f.facultyName).toList();
    if (_selectedFacultyName != null &&
        _selectedFacultyName!.isNotEmpty &&
        !list.contains(_selectedFacultyName)) {
      list.insert(0, _selectedFacultyName!);
    }
    return list;
  }

  List<Department> get _availableDepartments {
    if (_selectedFacultyName == null) return [];
    try {
      return allFaculties
          .firstWhere((f) => f.facultyName == _selectedFacultyName)
          .departments;
    } catch (_) {
      return [];
    }
  }

  List<String> get _departmentOptions {
    final list = _availableDepartments.map((d) => d.departmentName).toList();
    if (_selectedDepartmentName != null &&
        _selectedDepartmentName!.isNotEmpty &&
        !list.contains(_selectedDepartmentName)) {
      list.insert(0, _selectedDepartmentName!);
    }
    return list;
  }

  List<Programme> get _availableProgrammes {
    if (_selectedDepartmentName == null) return [];
    try {
      final faculty = allFaculties.firstWhere(
        (f) => f.facultyName == _selectedFacultyName,
        orElse: () => allFaculties.first,
      );
      return faculty.departments
          .firstWhere((d) => d.departmentName == _selectedDepartmentName)
          .programmes;
    } catch (_) {
      return [];
    }
  }

  List<String> get _programmeOptions {
    final list = _availableProgrammes.map((p) => p.programmeName).toList();
    if (_selectedProgrammeName != null &&
        _selectedProgrammeName!.isNotEmpty &&
        !list.contains(_selectedProgrammeName)) {
      list.insert(0, _selectedProgrammeName!);
    }
    return list;
  }

  List<String> get _levelOptions {
    final list = List<String>.from(_academicLevels);
    if (_selectedLevel != null &&
        _selectedLevel!.isNotEmpty &&
        !list.contains(_selectedLevel)) {
      list.add(_selectedLevel!);
    }
    return list;
  }

  // ── Image picker ──────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final profileDir = Directory('${appDir.path}/profile_photos');
      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }
      final fileName =
          'student_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = File('${profileDir.path}/$fileName');
      await File(picked.path).copy(savedFile.path);

      setState(() {
        _profileImagePath = savedFile.path;
        _hasPickedNewImage = true;
      });
    } catch (e) {
      if (!mounted) return;
      _showErrorSnack('Failed to pick image. Please try again.');
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ImagePickerSheet(
        hasImage: _profileImagePath != null,
        onGallery: () {
          Navigator.pop(ctx);
          _pickImage(ImageSource.gallery);
        },
        onCamera: () {
          Navigator.pop(ctx);
          _pickImage(ImageSource.camera);
        },
        onRemove: () {
          Navigator.pop(ctx);
          setState(() {
            _profileImagePath = null;
            _hasPickedNewImage = true;
          });
        },
      ),
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> _handleSave() async {
    if (_isSaving) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      _showErrorSnack('Please correct the highlighted form errors.');
      return;
    }

    if (_selectedFacultyName == null ||
        _selectedDepartmentName == null ||
        _selectedProgrammeName == null) {
      _showErrorSnack('Please select faculty, department, and programme.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final box = Hive.box<Student>('students');
      final updatedStudent = Student(
        fullName: _nameC.text.trim(),
        matricNo: _matricC.text.trim(),
        email: _emailC.text.trim(),
        phone: _phoneC.text.trim(),
        faculty: _selectedFacultyName!,
        department: _selectedDepartmentName!,
        course: _selectedProgrammeName!,
        profileImagePath: _profileImagePath,
        level: _selectedLevel,
      );
      await box.putAt(widget.index, updatedStudent);

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'Profile updated successfully.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: _primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );

      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showErrorSnack('Failed to update profile. Please try again.');
    }
  }

  // ── Unsaved-changes dialog ─────────────────────────────────────────────────
  Future<bool> _handleWillPop() async {
    if (_isSaving) return false;
    if (!_hasUnsavedChanges) return true;

    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Discard Changes?'),
          ],
        ),
        content: const Text(
          'You have unsaved changes. Are you sure you want to go back and discard them?',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  InputDecoration _inputDec({
    required String label,
    required IconData icon,
    String? hintText,
    String? helperText,
    bool readOnly = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      helperText: helperText,
      helperStyle: TextStyle(color: Colors.grey.shade500, fontSize: 11),
      prefixIcon: Icon(icon, color: _primaryGreen, size: 20),
      suffixIcon: readOnly
          ? Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade400)
          : null,
      filled: true,
      fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade500, width: 2),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final hasCustomImage =
        _profileImagePath != null &&
        _profileImagePath!.isNotEmpty &&
        File(_profileImagePath!).existsSync();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_isSaving) return;
        if (!_hasUnsavedChanges) {
          if (context.mounted) Navigator.pop(context);
          return;
        }
        final shouldPop = await _handleWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: _pageBg,
        appBar: _buildAppBar(),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: CustomScrollView(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Avatar Section ────────────────────────
                            _buildAvatarSection(hasCustomImage),

                            const SizedBox(height: 28),

                            // ── Personal Details Card ─────────────────
                            _buildSectionCard(
                              icon: Icons.person_outline,
                              iconBgColor: const Color(0xFFE8F5ED),
                              iconColor: _primaryGreen,
                              title: 'Personal Details',
                              child: Column(
                                children: [
                                  // Full Name
                                  TextFormField(
                                    controller: _nameC,
                                    enabled: !_isSaving,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    decoration: _inputDec(
                                      label: 'Full Name',
                                      icon: Icons.badge_outlined,
                                      hintText: 'e.g. Ibrahim Adamu',
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Full Name is required';
                                      }
                                      if (val.trim().length < 3) {
                                        return 'Please enter your complete name';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  // Email
                                  TextFormField(
                                    controller: _emailC,
                                    enabled: !_isSaving,
                                    keyboardType: TextInputType.emailAddress,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.deny(
                                        RegExp(r'\s'),
                                      ),
                                    ],
                                    decoration: _inputDec(
                                      label: 'Email Address',
                                      icon: Icons.alternate_email_outlined,
                                      hintText: 'student@akum.edu.ng',
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Email is required';
                                      }
                                      if (!RegExp(
                                        r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
                                      ).hasMatch(val.trim())) {
                                        return 'Enter a valid email address';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  // Phone
                                  TextFormField(
                                    controller: _phoneC,
                                    enabled: !_isSaving,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: _inputDec(
                                      label: 'Phone Number',
                                      icon: Icons.phone_outlined,
                                      hintText: '08012345678',
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Phone number is required';
                                      }
                                      if (val.trim().length < 10) {
                                        return 'Enter a valid phone number (min 10 digits)';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ── Academic Information Card ──────────────
                            _buildSectionCard(
                              icon: Icons.school_outlined,
                              iconBgColor: const Color(0xFFE3F2FD),
                              iconColor: const Color(0xFF1565C0),
                              title: 'Academic Information',
                              child: Column(
                                children: [
                                  // Matric Number
                                  TextFormField(
                                    controller: _matricC,
                                    enabled: !_isSaving,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    decoration: _inputDec(
                                      label: 'Matriculation Number',
                                      icon: Icons.badge_outlined,
                                      hintText: 'AKU/2023/SCI/042',
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Matriculation number is required';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  // Academic Level
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedLevel,
                                    decoration: _inputDec(
                                      label: 'Academic Level',
                                      icon: Icons.timeline_outlined,
                                    ),
                                    isExpanded: true,
                                    borderRadius: BorderRadius.circular(14),
                                    items: _levelOptions.map((lvl) {
                                      return DropdownMenuItem<String>(
                                        value: lvl,
                                        child: Text(lvl),
                                      );
                                    }).toList(),
                                    onChanged: _isSaving
                                        ? null
                                        : (val) => setState(
                                            () => _selectedLevel = val,
                                          ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Faculty
                                  DropdownButtonFormField<String>(
                                    key: ValueKey('faculty_$_selectedFacultyName'),
                                    initialValue: _selectedFacultyName,
                                    decoration: _inputDec(
                                      label: 'Faculty',
                                      icon: Icons.account_balance_outlined,
                                    ),
                                    isExpanded: true,
                                    borderRadius: BorderRadius.circular(14),
                                    items: _facultyOptions.map((fName) {
                                      return DropdownMenuItem<String>(
                                        value: fName,
                                        child: Text(
                                          fName,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: _isSaving
                                        ? null
                                        : (val) {
                                            setState(() {
                                              _selectedFacultyName = val;
                                              _selectedDepartmentName = null;
                                              _selectedProgrammeName = null;
                                            });
                                          },
                                    validator: (v) => v == null
                                        ? 'Faculty is required'
                                        : null,
                                  ),

                                  const SizedBox(height: 16),

                                  // Department
                                  DropdownButtonFormField<String>(
                                    key: ValueKey('dept_${_selectedFacultyName}_$_selectedDepartmentName'),
                                    initialValue: _selectedDepartmentName,
                                    decoration: _inputDec(
                                      label: 'Department',
                                      icon: Icons.apartment_outlined,
                                      hintText: _selectedFacultyName == null
                                          ? 'Select Faculty first'
                                          : null,
                                    ),
                                    isExpanded: true,
                                    borderRadius: BorderRadius.circular(14),
                                    items: _departmentOptions.map((deptName) {
                                      return DropdownMenuItem<String>(
                                        value: deptName,
                                        child: Text(
                                          deptName,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged:
                                        (_isSaving ||
                                            _selectedFacultyName == null)
                                        ? null
                                        : (val) {
                                            setState(() {
                                              _selectedDepartmentName = val;
                                              _selectedProgrammeName = null;
                                            });
                                          },
                                    validator: (v) => v == null
                                        ? 'Department is required'
                                        : null,
                                  ),

                                  const SizedBox(height: 16),

                                  // Programme
                                  DropdownButtonFormField<String>(
                                    key: ValueKey('prog_${_selectedDepartmentName}_$_selectedProgrammeName'),
                                    initialValue: _selectedProgrammeName,
                                    decoration: _inputDec(
                                      label: 'Programme / Course',
                                      icon: Icons.menu_book_outlined,
                                      hintText: _selectedDepartmentName == null
                                          ? 'Select Department first'
                                          : null,
                                    ),
                                    isExpanded: true,
                                    borderRadius: BorderRadius.circular(14),
                                    items: _programmeOptions.map((progName) {
                                      return DropdownMenuItem<String>(
                                        value: progName,
                                        child: Text(
                                          progName,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged:
                                        (_isSaving ||
                                            _selectedDepartmentName == null)
                                        ? null
                                        : (val) => setState(
                                            () => _selectedProgrammeName = val,
                                          ),
                                    validator: (v) => v == null
                                        ? 'Programme is required'
                                        : null,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 36),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Floating Save Button ─────────────────────────────────────────
        bottomNavigationBar: _buildSaveBar(),
      ),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Edit Profile',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      backgroundColor: _primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      actions: [
        if (_isSaving)
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Avatar Section ─────────────────────────────────────────────────────────
  Widget _buildAvatarSection(bool hasCustomImage) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _isSaving ? null : _showImagePickerOptions,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _primaryGreen, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: const Color(0xFFE8F5ED),
                    backgroundImage: hasCustomImage
                        ? FileImage(File(_profileImagePath!))
                        : null,
                    child: !hasCustomImage ? _buildInitialsAvatar() : null,
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: _primaryGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _isSaving ? null : _showImagePickerOptions,
            icon: const Icon(Icons.photo_camera_outlined, size: 16),
            label: const Text('Change Profile Photo'),
            style: TextButton.styleFrom(
              foregroundColor: _primaryGreen,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_hasPickedNewImage)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5ED),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 13, color: _primaryGreen),
                  SizedBox(width: 5),
                  Text(
                    'New photo selected — not saved yet',
                    style: TextStyle(
                      fontSize: 11,
                      color: _primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
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
        widget.student.initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ── Section Card ───────────────────────────────────────────────────────────
  Widget _buildSectionCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: child,
          ),
        ],
      ),
    );
  }

  // ── Save Button Bar ────────────────────────────────────────────────────────
  Widget _buildSaveBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryGreen,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(
              0xFF1B6B35,
            ).withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: _isSaving
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Saving Changes...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_outlined, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image Picker Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _ImagePickerSheet extends StatelessWidget {
  final bool hasImage;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onRemove;

  const _ImagePickerSheet({
    required this.hasImage,
    required this.onGallery,
    required this.onCamera,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Update Profile Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              const Divider(height: 16),

              _SheetOption(
                icon: Icons.photo_library_outlined,
                iconColor: const Color(0xFF1B6B35),
                iconBg: const Color(0xFFE8F5ED),
                title: 'Choose from Gallery',
                onTap: onGallery,
              ),
              _SheetOption(
                icon: Icons.camera_alt_outlined,
                iconColor: const Color(0xFF1565C0),
                iconBg: const Color(0xFFE3F2FD),
                title: 'Take a New Photo',
                onTap: onCamera,
              ),
              if (hasImage)
                _SheetOption(
                  icon: Icons.delete_outline_rounded,
                  iconColor: Colors.red.shade600,
                  iconBg: Colors.red.shade50,
                  title: 'Remove Current Photo',
                  titleColor: Colors.red.shade600,
                  onTap: onRemove,
                ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final Color? titleColor;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: titleColor ?? Colors.black87,
          fontSize: 15,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
