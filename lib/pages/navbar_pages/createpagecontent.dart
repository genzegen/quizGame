import 'package:flutter/material.dart';

class CreatePageContent extends StatefulWidget {
  const CreatePageContent({super.key});

  @override
  State<CreatePageContent> createState() => _CreatePageContentState();
}

class _CreatePageContentState extends State<CreatePageContent> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/createpage');
              },
              child: Text(
                "Create",
                style: TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 5,
                backgroundColor: Theme.of(context).colorScheme.tertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
