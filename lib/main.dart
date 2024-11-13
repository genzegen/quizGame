import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gameflow/auth/auth.dart';
import 'package:gameflow/game/gamepage.dart';
import 'package:gameflow/game/upload.dart';
import 'package:gameflow/pages/navbar_pages/create.dart';
import 'package:gameflow/pages/profile.dart';
import 'package:gameflow/theme/darkmode.dart';
import 'package:gameflow/theme/lightmode.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure binding is initialized
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // default mode light
  ThemeMode _themeMode = ThemeMode.light;

  // toggle between
  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthPage(toggleTheme: _toggleTheme),
      theme: lightMode,
      darkTheme: darkMode,
      themeMode: _themeMode,

      routes: {
        '/profile' : (context) => const ProfilePage(),
        '/gamepage' : (context) => const GamePage(quizId: '',),
        '/upload' : (context) => const UploadPage(),
        '/createpage' : (context) => const CreatePage(),
      },
    );
  }
}
