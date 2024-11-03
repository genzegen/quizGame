import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gameflow/auth/login_or_register.dart';
import '../pages/home.dart';

class AuthPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  const AuthPage({super.key, required this.toggleTheme});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // if user is logged in
          if(snapshot.hasData){
            return HomePage(toggleTheme: widget.toggleTheme);
          } else {
            return const LoginOrRegister();
          }
        },
      ),
    );
  }
}
