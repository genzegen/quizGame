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