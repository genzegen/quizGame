import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gameflow/game/question.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  int _correctAnswers = 0;
  List<Question>? _questions;
  bool _isAnswerSelected = false;
  bool _isAnswerCorrect = false;
  bool _isGameStarted = false;
  bool _isGameOver = false;
  int _remainingTime = 5;
  int _countdownTime = 3;
  Timer? _timer;
  Timer? _countdownTimer;

  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;
  final Stopwatch _questionStopwatch = Stopwatch(); // To track time per question

  @override
  void initState() {
    super.initState();
    _questionsFuture = _fetchQuestions(widget.quizId);
    _questionsFuture.then((questions) {
      setState(() {
        _questions = questions;
      });
      _startGame();
    });

    // Listen for accelerometer events (tilt detection)
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      if (_questions != null && _currentQuestionIndex < _questions!.length) {
        if (event.x < -5 && !_isAnswerSelected) {
          _handleAnswerSelection(_questions![_currentQuestionIndex].option2);
        } else if (event.x > 5 && !_isAnswerSelected) {
          _handleAnswerSelection(_questions![_currentQuestionIndex].option1);
        }
      }
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription.cancel();
    _timer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<List<Question>> _fetchQuestions(String quizId) async {
    final questionsQuery = await FirebaseFirestore.instance
        .collection('quizzes')
        .doc(quizId)
        .collection('questions')
        .get();

    return questionsQuery.docs.map((doc) => Question.fromDocument(doc.data())).toList();
  }

  void _startGame() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownTime == 0) {
        _countdownTimer?.cancel();
        setState(() {
          _isGameStarted = true;
        });
        _startQuestionTimer();
      } else {
        setState(() {
          _countdownTime--;
        });
      }
    });
  }

  void _startQuestionTimer() {
    _remainingTime = 5;
    _questionStopwatch.start();
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
    if (_currentQuestionIndex < (_questions?.length ?? 0) - 1) {
      setState(() {
        _currentQuestionIndex++;
        _isAnswerSelected = false;
        _isAnswerCorrect = false;
      });
      _startQuestionTimer();
    } else {
      _endGame();
    }
  }

  void _endGame() {
    if (_isGameOver) return;

    // Stop the stopwatch to calculate time for the last question
    _questionStopwatch.stop();

    setState(() {
      _isGameOver = true;
    });

    // Save the play data to Firestore
    _savePlayData();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Game Over"),
        content: Text("Your score: $_score\nCorrect Answers: $_correctAnswers/${_questions?.length ?? 0}"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => GamePage(quizId: widget.quizId),
                ),
              );
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  String getUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.uid;  // Return the userId (UID) of the logged-in user
    } else {
      throw Exception("No user is currently logged in.");
    }
  }

  Future<void> _savePlayData() async {
    final userId = getUserId();
    final quizId = widget.quizId;
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);

      // Get the current high score and total score
      int totalScore = userDoc.data()?['totalScore'] ?? 0;
      int currentHighScore = userDoc.data()?['scores']?[quizId]?['highScore'] ?? 0;

      if (_score > currentHighScore) {
        // Calculate the score difference to add to the total score
        int scoreDifference = _score - currentHighScore;
        totalScore += scoreDifference;

        // Update Firestore with the new high score, last score, and cumulative total score
        transaction.update(userRef, {
          'totalScore': totalScore,
          'scores.$quizId': {
            'highScore': _score,
            'lastScore': _score,
            'correctAnswers': _correctAnswers,
          },
        });
      } else {
        // Update only the last score if it's not a new high score
        transaction.update(userRef, {
          'scores.$quizId.lastScore': _score,
        });
      }
    });
  }

  void _handleAnswerSelection(String selectedOption) {
    if (!_isAnswerSelected) {
      setState(() {
        _isAnswerSelected = true;
        final correctAnswer = _questions![_currentQuestionIndex].correctAnswer;
        if (selectedOption == correctAnswer) {
          _score += _remainingTime;  // Score based on remaining time (bonus)
          _correctAnswers++;
          _isAnswerCorrect = true;  // Answer is correct
        } else {
          _isAnswerCorrect = false;  // Answer is incorrect
        }
      });

      _questionStopwatch.stop();  // Stop the stopwatch when the answer is selected

      // Delay the transition to the next question to show feedback
      Future.delayed(const Duration(milliseconds: 500), _goToNextQuestion);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

          _questions = snapshot.data;
          final currentQuestion = _questions![_currentQuestionIndex];

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!_isGameStarted)
                  Text(
                    'Starting in: $_countdownTime',
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                if (_isGameStarted) ...[
                  Text(
                    'Question ${_currentQuestionIndex + 1}/${_questions!.length}',
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
                      ? Image.network(currentQuestion.imageUrl, scale: 2)
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                      ElevatedButton(
                        onPressed: () => _handleAnswerSelection(currentQuestion.option1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isAnswerSelected
                              ? (_isAnswerCorrect ? Colors.green : Colors.red)
                              : Theme.of(context).colorScheme.tertiary,
                        ),
                        child: Text(currentQuestion.option1, style: const TextStyle(fontSize: 20)),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                      ElevatedButton(
                        onPressed: () => _handleAnswerSelection(currentQuestion.option2),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isAnswerSelected
                              ? (_isAnswerCorrect ? Colors.green : Colors.red)
                              : Theme.of(context).colorScheme.tertiary,
                        ),
                        child: Text(currentQuestion.option2, style: const TextStyle(fontSize: 20)),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    ],
                  ),
                ]
              ],
            ),
          );
        },
      ),
    );
  }
}
