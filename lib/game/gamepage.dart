import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GamePage extends StatefulWidget {
  final String quizId;
  const GamePage({super.key, required this.quizId});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late Future<List<Question>> _questionsFuture;
  int _currentQuestionIndex = 0;
  int _score = 0;
  late List<Question> _questions;
  bool _isAnswerSelected = false;
  bool _isAnswerCorrect = false;
  bool _isGameStarted = false;
  int _remainingTime = 5; // 5 seconds per question
  int _countdownTime = 3; // 3-second countdown before the game starts
  Timer? _timer;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _questionsFuture = _fetchQuestions(widget.quizId);

    // Start the game countdown immediately after the page is loaded
    _startGame();
  }

  // Fetch questions for the given quizId
  Future<List<Question>> _fetchQuestions(String quizId) async {
    final questionsQuery = await FirebaseFirestore.instance
        .collection('quizzes')
        .doc(quizId)
        .collection('questions')
        .get();

    return questionsQuery.docs.map((doc) => Question.fromDocument(doc.data())).toList();
  }

  // Start the game after the 3-second countdown
  void _startGame() {
    // Start the countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownTime == 0) {
        _countdownTimer?.cancel();
        setState(() {
          _isGameStarted = true;
        });
        _startQuestionTimer(); // Start the question timer once game starts
      } else {
        setState(() {
          _countdownTime--;
        });
      }
    });
  }

  // Start the 5-second timer for each question
  void _startQuestionTimer() {
    _remainingTime = 5; // 5 seconds per question
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime == 0) {
        _timer?.cancel();
        _goToNextQuestion();
      } else {
        setState(() {
          _remainingTime--;
        });
      }
    });
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _isAnswerSelected = false; // Reset answer selection for the next question
        _isAnswerCorrect = false; // Reset answer feedback
      });
      _startQuestionTimer(); // Start the timer for the next question
    } else {
      _endGame();
    }
  }

  void _endGame() {
    // Show the final score after the game is completed
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Game Over"),
        content: Text("Your score: $_score/${_questions.length}"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the game over dialog
              Navigator.pop(context); // Go back to the previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleAnswerSelection(String selectedOption) {
    if (!_isAnswerSelected) {
      setState(() {
        _isAnswerSelected = true;
        final correctAnswer = _questions[_currentQuestionIndex].correctAnswer;
        if (selectedOption == correctAnswer) {
          _score++;
          _isAnswerCorrect = true;
        } else {
          _isAnswerCorrect = false;
        }
      });

      // Wait for 0.5 seconds before going to the next question
      Future.delayed(const Duration(milliseconds: 500), _goToNextQuestion);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Page'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: FutureBuilder<List<Question>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No questions found"));
          }

          _questions = snapshot.data!;
          final currentQuestion = _questions[_currentQuestionIndex];

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Countdown or Game Start
                if (!_isGameStarted)
                  Text(
                    'Starting in: $_countdownTime',
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                if (_isGameStarted) ...[
                  Text(
                    'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    currentQuestion.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  currentQuestion.imageUrl.isNotEmpty
                      ? Image.network(currentQuestion.imageUrl)
                      : Container(),
                  const SizedBox(height: 20),
                  Text(
                    'Time Remaining: $_remainingTime',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Score: $_score',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => _handleAnswerSelection(currentQuestion.option1),
                    child: Text(currentQuestion.option1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAnswerSelected
                          ? (_isAnswerCorrect ? Colors.green : Colors.red)
                          : Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _handleAnswerSelection(currentQuestion.option2),
                    child: Text(currentQuestion.option2),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAnswerSelected
                          ? (_isAnswerCorrect ? Colors.green : Colors.red)
                          : Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _goToNextQuestion,
                    child: const Text('Next Question'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class Question {
  final String correctAnswer;
  final String option1;
  final String option2;
  final String imageUrl;
  final String title;

  Question({
    required this.correctAnswer,
    required this.option1,
    required this.option2,
    required this.imageUrl,
    required this.title,
  });

  // Factory constructor to create Question object from Firestore document
  factory Question.fromDocument(Map<String, dynamic> doc) {
    return Question(
      correctAnswer: doc['correctAnswer'] ?? 'No correct answer',
      option1: doc['option1'] ?? 'Option 1 not available',
      option2: doc['option2'] ?? 'Option 2 not available',
      imageUrl: doc['imageUrl'] ?? '',
      title: doc['title'] ?? '',
    );
  }
}
