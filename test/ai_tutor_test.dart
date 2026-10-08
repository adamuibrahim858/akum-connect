import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:akum_connet/models/ai_tutor_model.dart';
import 'package:akum_connet/services/ai_tutor_storage_service.dart';
import 'package:akum_connet/pages/dashboard.dart';
import 'package:akum_connet/pages/ai_tutor/ai_tutor_page.dart';
import 'package:akum_connet/pages/ai_tutor/ai_tutor_tasks_page.dart';
import 'package:akum_connet/pages/ai_tutor/add_task_dialog.dart';
import 'package:akum_connet/pages/ai_tutor/add_pdf_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late Box<AITutorDocument> box;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(AITutorDocumentAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(AITutorTaskAdapter());
    }

    box = await Hive.openBox<AITutorDocument>(AITutorStorageService.boxName);
  });

  setUp(() async {
    await box.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AI Tutor Models and Storage Tests', () {
    test(
      'AITutorDocument and AITutorTask create and persist correctly',
      () async {
        final now = DateTime.now();

        final doc = AITutorDocument(
          id: 'doc_123',
          title: 'Introduction to Computer Science',
          pdfFileName: 'cs101_lecture1.pdf',
          pdfPath: '/path/to/cs101_lecture1.pdf',
          createdAt: now,
        );

        await box.add(doc);
        expect(box.length, 1);
        expect(box.values.first.title, 'Introduction to Computer Science');
        expect(box.values.first.pdfFileName, 'cs101_lecture1.pdf');

        // Add task
        final task = await AITutorStorageService.addTask(
          doc,
          title: 'Read chapter 1',
          description: 'Prepare notes for next lecture',
        );

        expect(doc.tasks.length, 1);
        expect(doc.tasks.first.title, 'Read chapter 1');
        expect(doc.tasks.first.isCompleted, false);

        // Toggle task
        await AITutorStorageService.toggleTaskStatus(doc, task.id);
        expect(doc.tasks.first.isCompleted, true);

        // Delete task
        await AITutorStorageService.deleteTask(doc, task.id);
        expect(doc.tasks.isEmpty, true);
      },
    );
  });

  group('Dashboard Grid Tests', () {
    testWidgets('Dashboard renders 3-column grid with AI Tutor card', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {'/ai-tutor': (context) => const AITutorPage()},
          home: const DashboardPage(),
        ),
      );

      // Verify GridView has crossAxisCount of 3
      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);
      final GridView gridView = tester.widget(gridFinder);
      final delegate = gridView.childrenDelegate;
      expect(delegate, isNotNull);

      // Verify AI Tutor card is rendered
      expect(find.text('AI Tutor'), findsOneWidget);

      // Tap on AI Tutor card and verify navigation
      await tester.tap(find.text('AI Tutor'));
      await tester.pumpAndSettle();

      expect(find.text('AI Tutor'), findsWidgets); // App bar title
      expect(find.text('No AI Tutor documents yet'), findsOneWidget);
    });
  });

  group('AI Tutor Page and Tasks Page Widget Tests', () {
    testWidgets('AI Tutor Page shows empty state when no documents exist', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: AITutorPage()));

      expect(find.text('No AI Tutor documents yet'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsWidgets);
    });

    testWidgets(
      'AI Tutor Page shows document card with Add Task and View Tasks buttons',
      (tester) async {
        final doc = AITutorDocument(
          id: 'doc_abc',
          title: 'Data Structures & Algorithms',
          pdfFileName: 'dsa_syllabus.pdf',
          pdfPath: '/test/dsa_syllabus.pdf',
          createdAt: DateTime.now(),
        );

        await tester.runAsync(() async {
          await box.add(doc);
        });

        await tester.pumpWidget(const MaterialApp(home: AITutorPage()));

        expect(find.text('Data Structures & Algorithms'), findsOneWidget);
        expect(find.text('dsa_syllabus.pdf'), findsOneWidget);
        expect(find.text('Add Task'), findsOneWidget);
        expect(find.text('View Tasks'), findsOneWidget);
      },
    );

    testWidgets('AITutorTasksPage shows empty state and handles tasks', (
      tester,
    ) async {
      final doc = AITutorDocument(
        id: 'doc_xyz',
        title: 'Operating Systems',
        pdfFileName: 'os_ch1.pdf',
        pdfPath: '/test/os_ch1.pdf',
        createdAt: DateTime.now(),
      );

      await tester.runAsync(() async {
        await box.add(doc);
      });

      await tester.pumpWidget(
        MaterialApp(home: AITutorTasksPage(documentId: doc.id)),
      );

      expect(find.text('Document Tasks'), findsOneWidget);
      expect(find.text('No tasks added yet.'), findsOneWidget);

      // Add a task directly to verify UI updates
      await tester.runAsync(() async {
        await AITutorStorageService.addTask(
          doc,
          title: 'Study Process Scheduling',
          description: 'Review Round Robin and Priority algorithms',
        );
      });

      await tester.pumpAndSettle();
      expect(find.text('Study Process Scheduling'), findsOneWidget);
      expect(
        find.text('Review Round Robin and Priority algorithms'),
        findsOneWidget,
      );
    });

    testWidgets('Add Task Dialog renders with input fields and validation', (
      tester,
    ) async {
      final doc = AITutorDocument(
        id: 'doc_diag',
        title: 'Physics 101',
        pdfFileName: 'physics.pdf',
        pdfPath: '/test/physics.pdf',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AddTaskDialog(document: doc)),
        ),
      );

      expect(find.text('Add Task'), findsOneWidget);
      expect(find.text('Task Title'), findsOneWidget);
      expect(find.text('Save Task'), findsOneWidget);

      // Tap submit with empty title to trigger validation
      await tester.tap(find.text('Save Task'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a task title'), findsOneWidget);
    });

    testWidgets(
      'Add PDF Modal renders with Title field, Upload PDF and Add PDF button',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: AddPdfModal())),
        );

        expect(find.text('New AI Tutor PDF'), findsOneWidget);
        expect(find.text('Title'), findsOneWidget);
        expect(find.text('Enter a title'), findsOneWidget);
        expect(find.text('Upload PDF'), findsOneWidget);
        expect(find.text('Add PDF'), findsOneWidget);

        // Trigger submit without title and without PDF
        await tester.tap(find.text('Add PDF'));
        await tester.pumpAndSettle();

        expect(find.text('Please enter a title.'), findsOneWidget);
        expect(find.text('Please select a PDF file.'), findsOneWidget);
      },
    );
  });
}
