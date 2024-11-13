import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gameflow/game/readytoplay.dart';
import '../../game/gamepage.dart';

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  // fetch quizzes from firestore
  Future<List<Map<String, dynamic>>> _fetchQuizzes() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('quizzes').get();
    return Future.wait(snapshot.docs.map((doc) async {
      final userId = doc['userId']; // Get the userId from the quiz document
      final username = await _fetchUserInfo(
          userId); // Fetch the username from the 'users' collection
      return {
        'quizId': doc.id,
        'title': doc['title'],
        'createdAt': doc['createdAt'].toDate(),
        'username': username,
      };
    }).toList());
  }

  // Fetch user info from the 'users' collection
  Future<String> _fetchUserInfo(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        return userDoc['username'] ?? 'Unknown User';
      } else {
        return 'User not found!';
      }
    } catch (e) {
      return 'Error fetching user';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchQuizzes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child:
                    CircularProgressIndicator()); // Show loading indicator while fetching
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No quizzes found"));
          }

          // List of quizzes retrieved from Firestore
          final quizzes = snapshot.data!;

          return Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.25,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Image.asset(
                          'assets/img/shinigami.png',
                          scale: 8.6,
                        ),
                      ),
                    ),
                    const Text(
                      'Choose from various quizzes below',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(top: 14, right: 20, left: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Number of columns
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = quizzes[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReadyToPlayPage(
                                quizId: quiz['quizId'],
                              ),
                            ));
                      },
                      child: Card(
                        elevation: 18,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                quiz['title'], // Display quiz title
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Text(
                                'Created on: ${quiz['createdAt'].toLocal().toString().split(' ')[0]}', // Format creation date
                                style: const TextStyle(
                                    fontSize: 14,),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 20, right: 10, bottom: 20),
                              child: Text(
                                'Created by: ${quiz['username']}',
                                style: const TextStyle(
                                    fontSize: 14,),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
