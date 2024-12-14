import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gameflow/auth/login_or_register.dart';
import 'package:gameflow/components/button.dart';
import 'package:gameflow/components/textfield.dart';
import 'package:gameflow/helper/helper_function.dart';
import 'package:gameflow/pages/login.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;

  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPwController = TextEditingController();

  //register method
  void register() async {
    // showing loading circle
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // matching passwords
    if (passwordController.text != confirmPwController.text) {
      // dismiss loading circle
      Navigator.pop(context);
      displayMessageToUsers("Passwords do not match!", context);
    } else {
      try {
        // create user with Firebase Authentication
        UserCredential? userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        // Check if userCredential is not null and user is created
        if (userCredential != null) {
          String uid = userCredential.user!.uid;

          // Store user data in Firestore
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'username': usernameController.text,
            'email': emailController.text,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Print UID for debugging
          print('User registered with UID: $uid');

          // Close loading dialog
          Navigator.pop(context);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoginOrRegister(), // Ensure you have LoginPage widget ready
            ),
          );

          // You can navigate to the next screen if needed
        } else {
          // Handle case when user creation failed
          Navigator.pop(context);
          displayMessageToUsers("User creation failed. Try again.", context);
        }
      } on FirebaseAuthException catch (e) {
        // dismiss loading circle
        Navigator.pop(context);

        // Log the error for debugging
        print('Error: ${e.message}');

        // Displaying the error to the user
        displayMessageToUsers(e.code, context);
      }
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
          child: SingleChildScrollView(
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
                  hintText: "Username",
                  obscureText: false,
                  controller: usernameController,
                ),

                const SizedBox(
                  height: 10,
                ),

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

                MyTextField(
                  hintText: "Confirm Password",
                  obscureText: true,
                  controller: confirmPwController,
                ),

                const SizedBox(
                  height: 10,
                ),

                const SizedBox(
                  height: 20,
                ),

                // SIGN IN BUTTON

                MyButton(
                  text: 'Register',
                  onTap: register,
                ),

                // dont have a account

                const SizedBox(
                  height: 10,
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account?",
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
                        " Log in here!",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
