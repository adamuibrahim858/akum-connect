import 'package:akum_connet/pages/chatroom.dart';
import 'package:akum_connet/pages/dashboard.dart';
import 'package:akum_connet/pages/home.dart';
import 'package:akum_connet/pages/login.dart';
import 'package:akum_connet/pages/profile.dart';
import 'package:akum_connet/pages/signup.dart';
import 'package:akum_connet/pages/todos.dart';
import 'package:akum_connet/pages/timetable_page.dart';
import 'package:akum_connet/pages/exam_timetable.dart';
import 'package:akum_connet/pages/about.dart';
import 'package:akum_connet/pages/result_page.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/student_info.dart';
import 'models/timetable_entry.dart';
import 'models/exam_model.dart';
import 'models/note_model.dart';
import 'models/ai_tutor_model.dart';
import 'pages/notes/notes_page.dart';
import 'pages/ai_tutor/ai_tutor_page.dart';
import 'services/lecture_notification_service.dart';
import 'services/exam_notification_service.dart';
import 'services/school_knowledge_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint(
      "Warning: No .env file found. AI features may fall back to default.",
    );
  }
  await Hive.initFlutter();

  Hive.registerAdapter(StudentAdapter());
  Hive.registerAdapter(TimetableEntryAdapter());
  Hive.registerAdapter(ExamModelAdapter());
  Hive.registerAdapter(NoteAdapter());
  Hive.registerAdapter(AITutorTaskAdapter());
  Hive.registerAdapter(AITutorDocumentAdapter());
  await Hive.openBox<Student>('students'); // our box for student data
  await Hive.openBox<TimetableEntry>('timetable'); // box for timetable
  await Hive.openBox<ExamModel>('exams'); // box for exams
  await Hive.openBox<Note>('notes'); // box for notes
  await Hive.openBox<AITutorDocument>(
    'ai_tutor_documents',
  ); // box for AI tutor docs

  await LectureNotificationService.init();
  await ExamNotificationService.init();
  await SchoolKnowledgeService().loadData();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // home: Home(),
      routes: {
        '/': (context) => const Home(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/dashboard': (context) => const DashboardPage(),
        '/profile': (context) => const ProfilePage(),
        '/about': (context) => const AboutPage(),
        '/chats': (context) => const ChatInbox(),
        '/to-dos': (context) => const TodoApp(),
        '/timetable': (context) => const TimetablePage(),
        '/exam-timetable': (context) => const ExamTimetablePage(),
        '/notes': (context) => const NotesPage(),
        '/result': (context) => const ResultPage(),
        '/ai-tutor': (context) => const AITutorPage(),
      }, // home: Home(),
    );
  }
}
