import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:akum_connet/models/ai_tutor_model.dart';
import 'package:akum_connet/services/ai_tutor_storage_service.dart';
import 'package:akum_connet/services/ai_tutor_service.dart';
import 'package:akum_connet/pages/dashboard.dart';
import 'package:akum_connet/pages/ai_tutor/ai_tutor_page.dart';
import 'package:akum_connet/pages/ai_tutor/ai_tutor_tasks_page.dart';
import 'package:akum_connet/pages/ai_tutor/add_task_dialog.dart';
import 'package:akum_connet/pages/ai_tutor/summary_view_page.dart';
import 'package:akum_connet/pages/ai_tutor/essay_practice_page.dart';
import 'package:akum_connet/pages/ai_tutor/essay_results_page.dart';
import 'package:akum_connet/pages/ai_tutor/objective_practice_page.dart';
import 'package:akum_connet/pages/ai_tutor/objective_results_page.dart';

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

        // Add task with type and generated content
        final task = await AITutorStorageService.addTask(
          doc,
          title: 'Read chapter 1 summary',
          type: kTaskTypeSummarize,
          status: kTaskStatusCompleted,
          generatedContent: '# Chapter 1 Summary\nKey points here.',
        );

        expect(doc.tasks.length, 1);
        expect(doc.tasks.first.title, 'Read chapter 1 summary');
        expect(doc.tasks.first.type, kTaskTypeSummarize);
        expect(doc.tasks.first.generatedContent, contains('Chapter 1 Summary'));
        expect(doc.tasks.first.isCompleted, false);

        // Add questions
        task.questions = [
          AITutorQuestion(
            id: 'q1',
            question: 'What is an algorithm?',
            expectedAnswer: 'A step-by-step procedure.',
            topic: 'Algorithms',
          ),
        ];
        expect(task.questions.length, 1);
        expect(task.questions.first.question, 'What is an algorithm?');

        // Record attempt
        final attempt = AITutorAttempt(
          id: 'att_1',
          taskId: task.id,
          score: 8.0,
          maxScore: 10.0,
          percentage: 80.0,
          performance: 'Good',
          feedback: 'Great understanding of algorithms.',
          recommendations: ['Revise complexity.'],
          areasToRead: ['Topic 2'],
          submittedAt: DateTime.now(),
        );
        await AITutorStorageService.recordAttempt(doc, task.id, attempt);
        expect(task.attempts.length, 1);
        expect(task.latestAttempt!.score, 8.0);
        expect(task.isCompleted, true);

        // Delete task
        await AITutorStorageService.deleteTask(doc, task.id);
        expect(doc.tasks.isEmpty, true);
      },
    );

    test('AiTutorService JSON parser handles code fences and dirty text', () {
      const fencedJson = '''
```json
{
  "questions": [
    {
      "id": "1",
      "question": "What is polymorphism?",
      "options": ["A", "B", "C", "D"],
      "correctAnswer": 1
    }
  ]
}
```
''';
      final parsed = AiTutorService.extractJson(fencedJson);
      expect(parsed, isA<Map>());
      expect(parsed['questions'].length, 1);
      expect(parsed['questions'][0]['question'], 'What is polymorphism?');
    });
  });

  group('Dashboard Grid Tests', () {
    testWidgets('Dashboard renders 2-column grid with AI Tutor card', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {'/ai-tutor': (context) => const AITutorPage()},
          home: const DashboardPage(),
        ),
      );

      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);
      final gridView = tester.widget<GridView>(gridFinder);
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);

      // Scroll to AI Tutor card (may be below fold in 2-col layout)
      await tester.scrollUntilVisible(find.text('AI Tutor'), 100.0);
      expect(find.text('AI Tutor'), findsOneWidget);
    });
  });

  group('AI Tutor Pages and CBT UI Widget Tests', () {
    testWidgets(
      'AI Tutor Page shows document card with Add Task and View Tasks',
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

    testWidgets(
      'Add Task Dialog renders with Title, Dropdown, and Create Task button',
      (tester) async {
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
        expect(find.text('Task Type'), findsOneWidget);
        expect(find.text('Summarize'), findsOneWidget);
        expect(find.text('Create Task'), findsOneWidget);

        // Validate empty title
        await tester.tap(find.text('Create Task'));
        await tester.pumpAndSettle();
        expect(find.text('Please enter a task title'), findsOneWidget);
      },
    );

    testWidgets('AITutorTasksPage shows tasks with correct types and badges', (
      tester,
    ) async {
      final doc = AITutorDocument(
        id: 'doc_tasks_test',
        title: 'Chemistry 101',
        pdfFileName: 'chem.pdf',
        pdfPath: '/test/chem.pdf',
        createdAt: DateTime.now(),
      );

      final task1 = AITutorTask(
        id: 't1',
        documentId: doc.id,
        title: 'Organic Chemistry Summary',
        type: kTaskTypeSummarize,
        createdAt: DateTime.now(),
        generatedContent: '# Summary of Organic Chemistry',
      );

      final task2 = AITutorTask(
        id: 't2',
        documentId: doc.id,
        title: 'Equilibrium Essay Test',
        type: kTaskTypeEssay,
        createdAt: DateTime.now(),
      );

      doc.tasks.addAll([task1, task2]);

      await tester.runAsync(() async {
        await box.add(doc);
      });

      await tester.pumpWidget(
        MaterialApp(home: AITutorTasksPage(documentId: doc.id)),
      );

      expect(find.text('Document Tasks'), findsOneWidget);
      expect(find.text('Organic Chemistry Summary'), findsOneWidget);
      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('Equilibrium Essay Test'), findsOneWidget);
      expect(find.text('Essay Practice'), findsOneWidget);
      expect(find.text('Open'), findsNWidgets(2));
    });

    testWidgets('SummaryViewPage renders markdown content and action buttons', (
      tester,
    ) async {
      final doc = AITutorDocument(
        id: 'doc_s',
        title: 'Bio 101',
        pdfFileName: 'bio.pdf',
        pdfPath: '/test/bio.pdf',
        createdAt: DateTime.now(),
      );

      final task = AITutorTask(
        id: 't_s',
        documentId: doc.id,
        title: 'Cell Biology Notes',
        type: kTaskTypeSummarize,
        generatedContent:
            '# Cell Biology\n\n- Mitochondria is the powerhouse of the cell.',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SummaryViewPage(document: doc, task: task),
        ),
      );

      expect(find.text('Academic Summary'), findsOneWidget);
      expect(find.text('Cell Biology Notes'), findsOneWidget);
      expect(find.text('Download Summary as PDF'), findsOneWidget);
      expect(
        find.text('Mitochondria is the powerhouse of the cell.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'EssayPracticePage renders CBT questions and handles answer typing',
      (tester) async {
        final doc = AITutorDocument(
          id: 'doc_e',
          title: 'Law 101',
          pdfFileName: 'law.pdf',
          pdfPath: '/test/law.pdf',
          createdAt: DateTime.now(),
        );

        final task = AITutorTask(
          id: 't_e',
          documentId: doc.id,
          title: 'Constitutional Law Essay',
          type: kTaskTypeEssay,
          createdAt: DateTime.now(),
        );

        task.questions = [
          AITutorQuestion(
            id: 'q1',
            question: 'Critically analyze the principle of Rule of Law.',
            marks: 10,
            topic: 'Constitutionalism',
            expectedAnswer: 'Should cover Dicey\'s three formulations.',
          ),
          AITutorQuestion(
            id: 'q2',
            question: 'Discuss Separation of Powers.',
            marks: 10,
            topic: 'Governance',
            expectedAnswer: 'Montesquieu\'s doctrine.',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: EssayPracticePage(document: doc, task: task),
          ),
        );

        expect(find.text('Essay Practice Exam'), findsOneWidget);
        expect(find.text('Question 1 of 2'), findsOneWidget);
        expect(
          find.text('Critically analyze the principle of Rule of Law.'),
          findsOneWidget,
        );
        expect(find.text('10 Marks'), findsOneWidget);

        // Type an answer
        await tester.enterText(
          find.byType(TextFormField),
          'The Rule of Law according to A.V. Dicey implies supremacy of regular law.',
        );
        await tester.pump();
        expect(
          find.text(
            'The Rule of Law according to A.V. Dicey implies supremacy of regular law.',
          ),
          findsOneWidget,
        );

        // Navigate to next question
        await tester.tap(find.text('Next Question'));
        await tester.pumpAndSettle();

        expect(find.text('Question 2 of 2'), findsOneWidget);
        expect(find.text('Discuss Separation of Powers.'), findsOneWidget);
        expect(find.text('Submit Examination'), findsOneWidget);
      },
    );

    testWidgets(
      'EssayResultsPage displays score, AI feedback, and marking guide',
      (tester) async {
        final doc = AITutorDocument(
          id: 'doc_er',
          title: 'Law 101',
          pdfFileName: 'law.pdf',
          pdfPath: '/test/law.pdf',
          createdAt: DateTime.now(),
        );

        final task = AITutorTask(
          id: 't_er',
          documentId: doc.id,
          title: 'Constitutional Law Practice',
          type: kTaskTypeEssay,
          createdAt: DateTime.now(),
        );

        task.questions = [
          AITutorQuestion(
            id: 'q1',
            question: 'Explain Judicial Review.',
            marks: 10,
            expectedAnswer: 'Marbury v Madison principle.',
          ),
        ];

        final attempt = AITutorAttempt(
          id: 'att_1',
          taskId: task.id,
          score: 8.0,
          maxScore: 10.0,
          percentage: 80.0,
          performance: 'Good',
          feedback: 'Strong grasp of judicial precedence.',
          recommendations: ['Read Marbury v Madison citations.'],
          areasToRead: ['Constitutional Limits'],
          questionGradings: [
            {
              'questionId': 'q1',
              'score': 8.0,
              'maxScore': 10.0,
              'whatWentWell': 'Accurate explanation of checks and balances.',
              'whatWasMissed': 'Omitted local case law.',
              'expectedAnswer': 'Marbury v Madison principle.',
              'feedback': 'Good depth.',
            },
          ],
          submittedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: EssayResultsPage(document: doc, task: task, attempt: attempt),
          ),
        );

        expect(find.text('Essay Practice Result'), findsOneWidget);
        expect(find.text('80%'), findsOneWidget);
        expect(find.text('Performance: Good'), findsOneWidget);
        expect(find.text('AI Tutor Evaluation'), findsOneWidget);
        expect(
          find.text('Strong grasp of judicial precedence.'),
          findsOneWidget,
        );
        expect(find.text('Constitutional Limits'), findsOneWidget);
        expect(find.text('Marbury v Madison principle.'), findsOneWidget);
      },
    );

    testWidgets(
      'ObjectivePracticePage renders options and enables selecting answers',
      (tester) async {
        final doc = AITutorDocument(
          id: 'doc_obj',
          title: 'Physics 101',
          pdfFileName: 'phy.pdf',
          pdfPath: '/test/phy.pdf',
          createdAt: DateTime.now(),
        );

        final task = AITutorTask(
          id: 't_obj',
          documentId: doc.id,
          title: 'Newtonian Mechanics Quiz',
          type: kTaskTypeObjective,
          createdAt: DateTime.now(),
        );

        task.questions = [
          AITutorQuestion(
            id: 'q1',
            question: 'What is Newton\'s First Law of Motion?',
            options: [
              'Law of Inertia',
              'F = ma',
              'Action and Reaction',
              'Law of Gravitation',
            ],
            correctAnswer: 0,
            explanation: 'Newton\'s first law is the law of inertia.',
            topic: 'Mechanics',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: ObjectivePracticePage(document: doc, task: task),
          ),
        );

        expect(find.text('Objective Practice (CBT)'), findsOneWidget);
        expect(find.text('Question 1 of 1'), findsOneWidget);
        expect(
          find.text('What is Newton\'s First Law of Motion?'),
          findsOneWidget,
        );
        expect(find.text('Law of Inertia'), findsOneWidget);
        expect(find.text('F = ma'), findsOneWidget);

        // Select an option
        await tester.tap(find.text('Law of Inertia'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
        expect(find.text('Submit Test'), findsOneWidget);
      },
    );

    testWidgets(
      'ObjectiveResultsPage displays calculated score and question review',
      (tester) async {
        final doc = AITutorDocument(
          id: 'doc_obj_res',
          title: 'Physics 101',
          pdfFileName: 'phy.pdf',
          pdfPath: '/test/phy.pdf',
          createdAt: DateTime.now(),
        );

        final task = AITutorTask(
          id: 't_obj_res',
          documentId: doc.id,
          title: 'Mechanics CBT',
          type: kTaskTypeObjective,
          createdAt: DateTime.now(),
        );

        task.questions = [
          AITutorQuestion(
            id: 'q1',
            question: 'Unit of force?',
            options: ['Newton', 'Joule', 'Watt', 'Pascal'],
            correctAnswer: 0,
            explanation: 'Force is measured in Newtons (N).',
            topic: 'Units',
          ),
        ];

        final attempt = AITutorAttempt(
          id: 'att_obj_1',
          taskId: task.id,
          score: 1.0,
          maxScore: 1.0,
          percentage: 100.0,
          performance: 'Excellent',
          feedback: 'Outstanding mastery of mechanical units.',
          recommendations: ['Proceed to rotational motion.'],
          areasToRead: ['Rotational Dynamics'],
          questionGradings: [
            {
              'questionId': 'q1',
              'question': 'Unit of force?',
              'options': ['Newton', 'Joule', 'Watt', 'Pascal'],
              'selectedAnswerIndex': 0,
              'correctAnswerIndex': 0,
              'isCorrect': true,
              'explanation': 'Force is measured in Newtons (N).',
              'topic': 'Units',
            },
          ],
          submittedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ObjectiveResultsPage(
              document: doc,
              task: task,
              attempt: attempt,
            ),
          ),
        );

        expect(find.text('Objective Practice Result'), findsOneWidget);
        expect(find.text('100%'), findsOneWidget);
        expect(find.text('Performance: Excellent'), findsOneWidget);
        expect(find.text('AI Diagnostic Recommendation'), findsOneWidget);
        expect(
          find.text('Outstanding mastery of mechanical units.'),
          findsOneWidget,
        );
        expect(find.text('Rotational Dynamics'), findsOneWidget);
        expect(find.text('Unit of force?'), findsOneWidget);
        expect(find.text('Newton'), findsOneWidget);
      },
    );
  });
}
