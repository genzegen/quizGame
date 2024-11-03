import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gameflow/components/button.dart';
import 'package:gameflow/components/textfield.dart';

import '../helper/helper_function.dart';

class LoginPage extends StatefulWidget {


  final void Function()? onTap;

  LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();

  TextEditingController passwordController = TextEditingController();

  //login method
  void login() async {
    //show loading circle
    showDialog(
      context: context,
      builder: (context) =>
      const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // try sign in
    try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: emailController.text,
    password: passwordController.text,
    );
    Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
    Navigator.pop(context);
    displayMessageToUsers(e.code, context);
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Theme
        .of(context)
        .colorScheme
        .surface,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // I C O N

            Image.asset(
              'assets/img/leftOrRightLogo.png',
              color: Theme
                  .of(context)
                  .colorScheme
                  .inversePrimary,
            ),

            const SizedBox(
              height: 25,
            ),

            // Textfields

            MyTextField(
              hintText: "Email",
              obscureText: false,
              controller: emailController,
            ),

            const SizedBox(
              height: 10,
            ),

            MyTextField(
              hintText: "Password",
              obscureText: true,
              controller: passwordController,
            ),

            const SizedBox(
              height: 10,
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Forgot Password?',
                  style: TextStyle(
                      color: Theme
                          .of(context)
                          .colorScheme
                          .inversePrimary),
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            // SIGN IN BUTTON

            MyButton(
              text: 'Login',
              onTap: login,
            ),

            // dont have a account

            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account?",
                  style: TextStyle(
                    color: Theme
                        .of(context)
                        .colorScheme
                        .inversePrimary,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onTap,
                  child: const Text(
                    " Register here!",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}}
