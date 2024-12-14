import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final userId = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('totalScore', descending: true) // Sort by totalScore
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No data available.'));
          }

          // Get the list of users from snapshot
          final users = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text("Leaderboard", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),),
                Expanded(
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      var user = users[index];
                      String username = user['username'];
                      int totalScore = user['totalScore'] ?? 0;
                      bool isTopThree = 3 == index;
                      bool isTopTwo = 2 == index;
                      bool isTopOne = 1 == index;
                      bool isCurrentUser = false;

                      return Card(
                        elevation: 10,
                        child: ListTile(
                          title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold),),
                          subtitle: Text('Score: $totalScore'),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.tertiary,
                            child: Text(username[0].toUpperCase(),style: const TextStyle(fontWeight: FontWeight.bold),), // Display first letter
                          ),
                          trailing: Text('#${index + 1}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),), // Ranking
                        ),
                      );
                    },
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
