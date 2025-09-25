import 'package:akum_connet/pages/chatroom.dart';
import 'package:akum_connet/pages/dashboard.dart';
import 'package:akum_connet/pages/home.dart';
import 'package:akum_connet/pages/login.dart';
import 'package:akum_connet/pages/profile.dart';
import 'package:akum_connet/pages/signup.dart';
import 'package:akum_connet/pages/todos.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

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
        '/chats': (context) => const ChatInbox(),
        '/to-dos': (context) => const TodoApp()

      }, // home: Home(),
    );
  }
}