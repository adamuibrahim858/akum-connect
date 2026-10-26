import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:akum_connet/models/student_info.dart';
import 'package:akum_connet/pages/profile.dart';
import 'package:akum_connet/pages/edit_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late Box<Student> studentBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_profile_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(StudentAdapter());
    }

    studentBox = await Hive.openBox<Student>('students');
  });

  setUp(() async {
    await studentBox.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Student Model & Initials Tests', () {
    test('Student initials compute correctly for single and multi-word names', () {
      final s1 = Student(
        fullName: 'Ibrahim Adamu',
        matricNo: 'AKU/2023/SCI/001',
        email: 'ibrahim@akum.edu.ng',
        phone: '08012345678',
        faculty: 'Faculty of Science',
        department: 'Computer Science',
        course: 'B.Sc. Computer Science',
      );
      expect(s1.initials, 'IA');

      final s2 = Student(
        fullName: 'Zainab',
        matricNo: 'AKU/2023/SCI/002',
        email: 'zainab@akum.edu.ng',
        phone: '08087654321',
        faculty: 'Faculty of Science',
        department: 'Physics',
        course: 'B.Sc. Physics',
      );
      expect(s2.initials, 'ZA');
    });

    test('Student model persists with optional level and profileImagePath in Hive', () async {
      final s = Student(
        fullName: 'Aisha Bello',
        matricNo: 'AKU/2023/ART/010',
        email: 'aisha@akum.edu.ng',
        phone: '08123456789',
        faculty: 'Faculty of Arts',
        department: 'Languages',
        course: 'B.A. English',
        level: '300 Level',
        profileImagePath: '/path/to/avatar.jpg',
      );

      await studentBox.add(s);
      expect(studentBox.length, 1);

      final retrieved = studentBox.getAt(0)!;
      expect(retrieved.fullName, 'Aisha Bello');
      expect(retrieved.level, '300 Level');
      expect(retrieved.profileImagePath, '/path/to/avatar.jpg');
    });
  });

  group('ProfilePage Widget Tests', () {
    testWidgets('ProfilePage displays empty state when no student registered', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProfilePage()),
      );

      expect(find.text('No Student Profile Found'), findsOneWidget);
      expect(find.byIcon(Icons.person_off_outlined), findsOneWidget);
    });

    testWidgets('ProfilePage displays student details and initials fallback avatar', (tester) async {
      final s = Student(
        fullName: 'Musa Abdullahi',
        matricNo: 'AKU/2022/ENG/015',
        email: 'musa@akum.edu.ng',
        phone: '08099887766',
        faculty: 'Faculty of Engineering',
        department: 'Electrical Engineering',
        course: 'B.Eng. Electrical',
        level: '400 Level',
      );

      await tester.runAsync(() async {
        await studentBox.add(s);
      });

      await tester.pumpWidget(
        const MaterialApp(home: ProfilePage()),
      );

      // Verify header contents
      expect(find.text('Musa Abdullahi'), findsNWidgets(2)); // Header & Contact
      expect(find.text('MA'), findsOneWidget); // Fallback initials
      expect(find.text('AKU/2022/ENG/015'), findsNWidgets(2)); // Header pill & Academic card
      expect(find.text('B.Eng. Electrical • 400 Level'), findsOneWidget);

      // Verify Card Sections
      expect(find.text('Academic Details'), findsOneWidget);
      expect(find.text('Contact Information'), findsOneWidget);
      expect(find.text('Institutional Status'), findsOneWidget);
      expect(find.text('musa@akum.edu.ng'), findsOneWidget);
      expect(find.text('08099887766'), findsOneWidget);
      expect(find.text('Faculty of Engineering'), findsOneWidget);
      expect(find.text('Electrical Engineering'), findsOneWidget);
      expect(find.text('Abdulkadir Kure University'), findsOneWidget);
      expect(find.text('Active Student'), findsOneWidget);

      // Verify edit button
      expect(find.text('Edit Profile Information'), findsOneWidget);
    });
  });

  group('EditProfilePage Widget Tests', () {
    testWidgets('EditProfilePage pre-populates existing data and validates required fields', (tester) async {
      final s = Student(
        fullName: 'Fatima Umar',
        matricNo: 'AKU/2023/SCI/099',
        email: 'fatima@akum.edu.ng',
        phone: '08011223344',
        faculty: 'Faculty of Science',
        department: 'Computer Science',
        course: 'B.Sc. Computer Science',
        level: '200 Level',
      );

      await tester.runAsync(() async {
        await studentBox.add(s);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: EditProfilePage(student: s, index: 0),
        ),
      );

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Fatima Umar'), findsOneWidget);
      expect(find.text('AKU/2023/SCI/099'), findsOneWidget);
      expect(find.text('fatima@akum.edu.ng'), findsOneWidget);
      expect(find.text('08011223344'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      // Test validation: clear name field
      await tester.enterText(find.widgetWithText(TextFormField, 'Fatima Umar'), '');
      await tester.pump();

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Full Name is required'), findsOneWidget);
    });

    testWidgets('EditProfilePage saves updated profile data and updates Hive', (tester) async {
      final s = Student(
        fullName: 'John Doe',
        matricNo: 'AKU/2023/SMS/005',
        email: 'john@akum.edu.ng',
        phone: '08055667788',
        faculty: 'Faculty of Science',
        department: 'Computer Science',
        course: 'B.Sc. Computer Science',
        level: '100 Level',
      );

      await tester.runAsync(() async {
        await studentBox.add(s);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: EditProfilePage(student: s, index: 0),
        ),
      );

      // Update name and phone
      await tester.enterText(
        find.widgetWithText(TextFormField, 'John Doe'),
        'Johnathan Doe',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '08055667788'),
        '08099998888',
      );
      await tester.pump();

      // Tap Save Changes
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(studentBox.getAt(0)!.fullName, 'Johnathan Doe');
      expect(studentBox.getAt(0)!.phone, '08099998888');
    });

    testWidgets('Unsaved changes dialog warns before discarding', (tester) async {
      final s = Student(
        fullName: 'Aliyu Danladi',
        matricNo: 'AKU/2023/SCI/077',
        email: 'aliyu@akum.edu.ng',
        phone: '08012341234',
        faculty: 'Faculty of Science',
        department: 'Computer Science',
        course: 'B.Sc. Computer Science',
      );

      await tester.runAsync(() async {
        await studentBox.add(s);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => EditProfilePage(student: s, index: 0),
                    ),
                  );
                },
                child: const Text('Go to Edit'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go to Edit'));
      await tester.pumpAndSettle();

      // Make a change
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Aliyu Danladi'),
        'Aliyu Danladi Junior',
      );
      await tester.pump();

      // Tap back button
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Discard Changes?'), findsOneWidget);
      expect(find.text('Keep Editing'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);

      // Tap Discard
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      // Back to original page
      expect(find.text('Go to Edit'), findsOneWidget);
    });
  });
}
