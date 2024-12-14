import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gameflow/game/readytoplay.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  late Future<List<Map<String, dynamic>>> _likedQuizzesFuture;

  @override
  void initState() {
    super.initState();
    _likedQuizzesFuture = fetchLikedQuizzes();
  }

  Future<List<Map<String, dynamic>>> fetchLikedQuizzes() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // Fetch the user document to get the liked quizzes
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final likedQuizzes =
          List<String>.from(userDoc.data()?['likedQuizzes'] ?? []);

      // Fetch the quiz details using the quizIds from likedQuizzes
      final quizFutures = likedQuizzes.map((quizId) async {
        // Fetch the quiz details from the quizzes collection
        final quizDoc = await FirebaseFirestore.instance
            .collection('quizzes')
            .doc(quizId)
            .get();

        if (quizDoc.exists) {
          final quizData = quizDoc.data()!;
          // Fetch the userId from the quiz data
          final creatorUserId = quizData['userId'];

          // Fetch the username from the users collection using the userId
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(creatorUserId)
              .get();

          // Make sure the user document exists
          final username = userDoc.exists && userDoc.data() != null
              ? userDoc.data()!['username'] ?? 'Unknown'
              : 'Unknown';

          return {
            'quizId': quizId,
            'title': quizData['title'] ?? 'Untitled Quiz',
            'username': username, // Use the fetched username
            'likesCount': quizData['likesCount'] ?? 0,
            'titleLower': quizData['titleLower'] ?? 'Unknown',
            'createdAt': quizData['createdAt'].toDate() ?? 'Unknown',
          };
        }
        // Return null if quiz document does not exist
        return null;
      }).toList();

      // Wait for all futures to complete and remove null values
      final quizResults = await Future.wait(quizFutures);
      return quizResults.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      print("Error fetching liked quizzes: $e");
      return [];
    }
  }

  Future<void> _refreshPage() async {
    setState(() {
      _likedQuizzesFuture = fetchLikedQuizzes(); // Reload the quizzes data
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(
              Icons.bookmark,
              size: 30,
            ),
            Text(
              " Your Saved Quizzes",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _likedQuizzesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Liked quizzes will show here!", style: TextStyle(fontSize: 20),),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("No favorite quizzes found.", style: TextStyle(fontSize: 16),),
                          Image.asset('assets/img/blair.png', scale: 3,),
                          const Text("-blair", style: TextStyle(fontSize: 12),),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }

            final quizzes = snapshot.data!;
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 23),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "All of your liked quizzes are protected by Blair!",
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                ),
                Image.asset(
                  'assets/img/blair.png',
                  scale: 3,
                ),
                const Text('-blair'),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.only(
                        left: 20, right: 20, bottom: 20, top: 10),
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
                          // Navigate to the quiz game page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ReadyToPlayPage(quizId: quiz['quizId']),
                            ),
                          );
                        },
                        child: Card(
                          color: Theme.of(context).cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 18,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Center(
                                    child: Text(
                                      quiz['title'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 30),
                                    ),
                                  ),
                                  SizedBox(
                                      height: MediaQuery.of(context).size.height *
                                          0.02),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            quiz['username'],
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            quiz['createdAt']
                                                .toLocal()
                                                .toString()
                                                .split(' ')[0],
                                            // Format creation date
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.favorite,
                                              size: 25, color: Colors.red),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${quiz['likesCount']}",
                                            style: const TextStyle(fontSize: 20),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
      ),
    );
  }
}
