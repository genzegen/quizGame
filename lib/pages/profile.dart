import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final String? username;const
  ProfilePage({super.key, this.username});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text("${username ?? 'User'}'s Profile"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(username ?? 'User'),

          ],
        ),
      ),
    );
  }
}
