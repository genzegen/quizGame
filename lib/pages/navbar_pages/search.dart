import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gameflow/game/readytoplay.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Quiz> _searchResults = [];

  // Method to perform search
  void _searchQuizzes(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    // Fetch quizzes matching title
    final querySnapshot = await FirebaseFirestore.instance
        .collection('quizzes')
        .where('titleLower', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('titleLower', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    // Fetch each quiz asynchronously with the creator's username
    List<Quiz> quizzes = [];
    for (var doc in querySnapshot.docs) {
      final quiz = Quiz.fromDocument(doc); // Create Quiz object without username
      final creatorUsername = await Quiz.fetchCreatorUsername(doc['userId']); // Fetch creator's username
      quizzes.add(Quiz(
        title: quiz.title,
        quizId: quiz.quizId,
        createdAt: quiz.createdAt,
        creatorUsername: creatorUsername,  // Set the fetched creator username
      ));
    }

    setState(() {
      _searchResults = quizzes;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = []; // Clear the search results as well
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            child: Card(
              elevation: 5,
              child: TextField(
                controller: _searchController,
                onChanged: _searchQuizzes,
                decoration: InputDecoration(
                  hintText: 'Search for quizzes...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(onPressed: _clearSearch, icon: const Icon(Icons.clear)),
                ),
              ),
            ),
          ),
          Expanded(
            child: _searchResults.isEmpty
                ? const Center(child: Text('No results found'))
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final quiz = _searchResults[index];
                return QuizTile(
                  title: quiz.title,
                  quizId: quiz.quizId,
                  createdAt: quiz.createdAt,
                  creatorUsername: quiz.creatorUsername,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class QuizTile extends StatelessWidget {
  final String title;
  final String quizId;
  final String createdAt;
  final String creatorUsername; // Add creatorUsername

  const QuizTile({
    super.key,
    required this.title,
    required this.quizId,
    required this.createdAt,
    required this.creatorUsername, // Add creatorUsername to constructor
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.01,)
            ],
          ),
          subtitle: Text('Created on: $createdAt\nby $creatorUsername', style: const TextStyle(fontSize: 15)),
          onTap: () {
            // Check if the quizId is valid
            if (quizId.isNotEmpty) {
              // Navigate to the ReadyToPlayPage with the quizId
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReadyToPlayPage(quizId: quizId),
                ),
              );
            } else {
              // If the quizId is empty, show a message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Invalid quiz ID"),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class Quiz {
  final String title;
  final String quizId;
  final String createdAt;
  final String creatorUsername;

  Quiz({
    required this.title,
    required this.quizId,
    required this.createdAt,
    required this.creatorUsername,
  });

  // Factory constructor to create a Quiz object from Firestore document
  factory Quiz.fromDocument(DocumentSnapshot doc) {
    final createdAtTimestamp = doc['createdAt'] as Timestamp?;
    final createdAt = createdAtTimestamp != null
        ? createdAtTimestamp.toDate().toLocal().toString().split(' ')[0] // Format to YYYY-MM-DD
        : 'Unknown';

    // Create the Quiz object without fetching username yet
    return Quiz(
      title: doc['title'] ?? 'Untitled',
      quizId: doc.id,
      createdAt: createdAt,
      creatorUsername: 'Unknown',  // Default username initially
    );
  }

  // Function to fetch creator's username asynchronously
  static Future<String> fetchCreatorUsername(String userId) async {
    if (userId.isEmpty) return 'Unknown';

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (userDoc.exists) {
      return userDoc['username'] ?? 'Unknown';
    }
    return 'Unknown';
  }
}
