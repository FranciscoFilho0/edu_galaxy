class QuizQuestionModel {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String subject;

  const QuizQuestionModel({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.subject,
  });

  String get correctAnswer => options[correctIndex];

  QuizQuestionModel copyWith({
    String? question,
    List<String>? options,
    int? correctIndex,
    String? subject,
  }) {
    return QuizQuestionModel(
      id: id,
      question: question ?? this.question,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      subject: subject ?? this.subject,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'subject': subject,
      };

  factory QuizQuestionModel.fromMap(Map<String, dynamic> map) {
    return QuizQuestionModel(
      id: map['id'] ?? '',
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctIndex: map['correctIndex'] ?? 0,
      subject: map['subject'] ?? '',
    );
  }
}
