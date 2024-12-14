import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'gamepage.dart';

class ReadyToPlayPage extends StatefulWidget {
  final String quizId;

  const ReadyToPlayPage({super.key, required this.quizId});

  @override
  State<ReadyToPlayPage> createState() => _ReadyToPlayPageState();
}

class _ReadyToPlayPageState extends State<ReadyToPlayPage> {
  late Future<Map<String, dynamic>> _quizDetailsFuture;
  late Future<Map<String, dynamic>> _userScoresFuture;

  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _quizDetailsFuture = _fetchQuizDetails(widget.quizId);
    _userScoresFuture = _fetchUserScores();
    _checkIfLiked();
  }

  // Fetch quiz details from Firestore
  Future<Map<String, dynamic>> _fetchQuizDetails(String quizId) async {
    final quizDoc = await FirebaseFirestore.instance
        .collection('quizzes')
        .doc(quizId)
        .get();
    if (quizDoc.exists) {
      final quizData = quizDoc.data()!;
      final userId =
          quizData['userId']; // Get the userId from the quiz document
      final username = await _fetchUserInfo(userId); // Fetch the username

      // Check if the 'createdAt' field exists and is of type Timestamp
      final createdAtTimestamp = quizData['createdAt'];

      String createdAt = 'Unknown';
      if (createdAtTimestamp is Timestamp) {
        createdAt = createdAtTimestamp
            .toDate()
            .toLocal()
            .toString()
            .split(' ')[0]; // Format to YYYY-MM-DD
      }

      return {
        'title': quizData['title'],
        'description': quizData['description'] ?? 'No description available',
        'username': username,
        'createdAt': createdAt,
      };
    }
    return {
      'title': 'Quiz not found',
      'description': 'No description available',
      'username': 'Unknown',
      'createdAt': 'Unknown',
    };
  }

  // Fetch the currently logged-in user's ID
  String getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.uid; // Returns the current user's unique ID
    } else {
      throw Exception("No user is logged in");
    }
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

  // Fetch the user's scores (highscore and latestscore) for a specific quiz
  Future<Map<String, dynamic>> _fetchUserScores() async {
    try {
      final userId = getCurrentUserId(); // Get the current user ID
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        // Fetch the scores map for the user
        Map<String, dynamic> scores = userDoc.data()!['scores'] ?? {};

        if (scores.containsKey(widget.quizId)) {
          // Access data for the specific quiz
          Map<String, dynamic> quizScores = scores[widget.quizId];
          int highScore = quizScores['highScore'] ?? 0;
          int lastScore = quizScores['lastScore'] ?? 0;

          return {
            'highScore': highScore,
            'lastScore': lastScore,
          };
        } else {
          return {'highScore': 0, 'lastScore': 0};
        }
      } else {
        return {'highScore': 0, 'lastScore': 0};
      }
    } catch (e) {
      return {
        'highScore': 0,
        'lastScore': 0
      }; // Return default values in case of error
    }
  }

  // LIKING AND UNLIKING THE QUIZ
  Future<void> likeQuiz(String quizId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final quizRef = FirebaseFirestore.instance.collection('quizzes').doc(quizId);

      await userRef.update({
        'likedQuizzes': FieldValue.arrayUnion([quizId]),
      });

      await quizRef.update({
        'likesCount': FieldValue.increment(1),
      });

      setState(() {
        _isLiked = true;
      });
      _checkIfLiked();  // Recheck if the quiz is liked after updating
    } catch (e) {
      print("Error adding like: $e");
    }
  }

  Future<void> unlikeQuiz(String quizId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final quizRef = FirebaseFirestore.instance.collection('quizzes').doc(quizId);

      await userRef.update({
        'likedQuizzes': FieldValue.arrayRemove([quizId]),
      });

      await quizRef.update({
        'likesCount': FieldValue.increment(-1),
      });

      setState(() {
        _isLiked = false;
      });
      _checkIfLiked();  // Recheck if the quiz is liked after updating
    } catch (e) {
      print("Error removing like: $e");
    }
  }


  Future<void> _checkIfLiked() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        final likedQuizzes = List.from(userDoc.data()?['likedQuizzes'] ?? []);
        setState(() {
          _isLiked = likedQuizzes.contains(widget.quizId);
        });
      }
    } catch (e) {
      print("Error checking liked status: $e");
    }
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
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            );
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: FutureBuilder<Map<String, dynamic>>(
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
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.05,
                  ),
                  Text(
                    quizData['title'],
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Description of the quiz:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18.0, vertical: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              quizData['description'],
                              style: const TextStyle(
                                  fontSize: 17, fontStyle: FontStyle.italic),
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.02,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Created by:',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${quizData['username']}',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Created on:',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${quizData['createdAt']} ',
                                      style: const TextStyle(fontSize: 15),
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
                      child: Text(
                        'PLAY',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 30),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.01,
                  ),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _userScoresFuture,
                    builder: (context, scoreSnapshot) {
                      if (scoreSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (scoreSnapshot.hasError) {
                        return Center(
                            child: Text("Error: ${scoreSnapshot.error}"));
                      } else if (!scoreSnapshot.hasData) {
                        return const Center(child: Text("No scores found"));
                      }

                      final userScores = scoreSnapshot.data!;
                      final highScore = userScores['highScore'] ?? 0;
                      final lastScore = userScores['lastScore'] ?? 0;

                      return Column(
                        children: [
                          Image.asset(
                            'assets/img/shinigamiscore.png',
                            scale: 3,
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12.0),
                                      child: Column(
                                        children: [
                                          const Text('Your High Score:',
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold)),
                                          Text(
                                            "$highScore",
                                            style: const TextStyle(
                                                fontSize: 40,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const Text('Your Last Score:',
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold)),
                                          Text(
                                            "$lastScore",
                                            style: const TextStyle(
                                                fontSize: 40,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 30,
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                          onPressed: () {
                                            if(_isLiked) {
                                              unlikeQuiz(widget.quizId);
                                            } else {
                                              likeQuiz(widget.quizId);
                                            }
                                          },
                                          icon: Icon(
                                            _isLiked
                                                ? Icons.favorite_rounded
                                                : Icons.favorite_border_rounded,
                                            size: 50,
                                            color: const Color(0xffCC3535),
                                          )),
                                      const Text(
                                        "Like so you can\ncome back later",
                                        style: TextStyle(fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * .1,
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
