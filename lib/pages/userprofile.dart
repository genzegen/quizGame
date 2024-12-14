import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final String? username;
  final user = FirebaseAuth.instance.currentUser;

  ProfilePage({super.key, this.username});

  // Fetch total score for the user
  Future<int> _fetchTotalScore() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();
      return doc['totalScore'] ?? 0;
    } catch (e) {
      return 0; // Return 0 if there's an error or the field doesn't exist
    }
  }

  // Fetch leaderboard rank for the user
  Future<int> _fetchLeaderboardRank() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('totalScore', descending: true)
          .get();
      final userIds = snapshot.docs.map((doc) => doc.id).toList();
      return userIds.indexOf(user!.uid) + 1; // Rank is 1-based
    } catch (e) {
      return 0; // Return 0 if there's an error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.05,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 30,
                  )),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.07,
            ),
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 12),
              child: Center(
                child: Text(
                  username ?? 'User',
                  style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Center(
                child: Text("Short Bio",
                    style: TextStyle(
                        fontStyle: FontStyle.italic, fontSize: 15))),
            Padding(
              padding:
              const EdgeInsets.only(top: 24, left: 12, right: 12, bottom: 12),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      "Achievements",
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FutureBuilder<int>(
                        future: _fetchLeaderboardRank(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }

                          final rank = snapshot.data ?? 0;

                          // Determine the card color based on rank
                          Color cardColor;
                          if (rank == 1) {
                            cardColor = Colors.amber; // Gold for rank 1
                          } else if (rank == 2) {
                            cardColor = Colors.grey; // Silver for rank 2
                          } else if (rank == 3) {
                            cardColor = const Color(0xFFCD7F32); // Bronze for rank 3
                          } else {
                            cardColor = Theme.of(context).cardColor; // Default card color for other ranks
                          }

                          return Card(
                            color: cardColor, // Apply dynamic card color
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(45),
                            ),
                            child: Container(
                              width: 100,
                              height: 100,
                              child: Center(
                                child: Text(
                                  rank > 0 ? "Rank\n#$rank" : "Rank\nN/A", // Show rank or "N/A" if invalid
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      FutureBuilder<int>(
                        future: _fetchTotalScore(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          return Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                "Score\n${snapshot.data}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            "Other\nAchievement",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.4,
                child: Column(
                  children: [
                    Text(
                      "$username's Quizzes",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('quizzes')
                            .where('userId', isEqualTo: user?.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Column(
                                children: [
                                  Image.asset('assets/img/empty.png', color: Theme.of(context).colorScheme.inversePrimary,),
                                  const Text("No quizzes created yet."),
                                ],
                              ),
                            );
                          }

                          final quizzes = snapshot.data!.docs;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5.0),
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // Number of items per row
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 2.1,
                              ),
                              itemCount: quizzes.length,
                              itemBuilder: (context, index) {
                                final quiz = quizzes[index];
                                final title = quiz['title'] ?? 'Untitled';
                                final createdAt = quiz['createdAt'].toDate();
                                final formattedDate =
                                createdAt.toLocal().toString().split(' ')[0];

                                return GestureDetector(
                                  onTap: () {
                                    // Add navigation logic here if needed
                                  },
                                  child: Card(
                                    color: Theme.of(context).cardColor,
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Expanded(
                                            child: Text(
                                              "Created: $formattedDate",
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
