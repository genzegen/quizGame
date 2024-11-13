import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'gamepage.dart'; // Import the GamePage

class ReadyToPlayPage extends StatefulWidget {
  final String quizId;

  const ReadyToPlayPage({super.key, required this.quizId});

  @override
  State<ReadyToPlayPage> createState() => _ReadyToPlayPageState();
}

class _ReadyToPlayPageState extends State<ReadyToPlayPage> {
  late Future<Map<String, dynamic>> _quizDetailsFuture;

  @override
  void initState() {
    super.initState();
    _quizDetailsFuture = _fetchQuizDetails(widget.quizId);
  }

  // Fetch quiz details from Firestore
  Future<Map<String, dynamic>> _fetchQuizDetails(String quizId) async {
    final quizDoc = await FirebaseFirestore.instance
        .collection('quizzes')
        .doc(quizId)
        .get();
    if (quizDoc.exists) {
      final quizData = quizDoc.data()!;
      return {
        'title': quizData['title'],
        'description': quizData['description'] ?? 'No description available',
      };
    }
    return {
      'title': 'Quiz not found',
      'description': 'No description available'
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Map<String, dynamic>>(
          future: _quizDetailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData) {
              return const Center(child: Text("No quiz details found"));
            }

            final quizData = snapshot.data!;
            return Text(
              quizData['title'],
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            );
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _quizDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("No quiz details found"));
          }

          final quizData = snapshot.data!;
          return Center(
            child: Column(
              children: [
                Text(
                  quizData['title'],
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  quizData['description'],
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to the GamePage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GamePage(quizId: widget.quizId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    elevation: 8,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('PLAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
