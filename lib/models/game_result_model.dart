class GameResultModel {
  final String id;
  final String studentId;
  final String studentName;
  final String gameId;
  final String gameName;
  final String subject;
  final int score;
  final int totalQuestions;
  final DateTime playedAt;
  final int durationSeconds;

  const GameResultModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.gameId,
    required this.gameName,
    required this.subject,
    required this.score,
    required this.totalQuestions,
    required this.playedAt,
    required this.durationSeconds,
  });

  double get percentage => totalQuestions > 0 ? (score / totalQuestions) * 100 : 0;

  factory GameResultModel.fromMap(Map<String, dynamic> map) {
    return GameResultModel(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      gameId: map['gameId'] ?? '',
      gameName: map['gameName'] ?? '',
      subject: map['subject'] ?? '',
      score: map['score'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
      playedAt: DateTime.tryParse(map['playedAt'] ?? '') ?? DateTime.now(),
      durationSeconds: map['durationSeconds'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'gameId': gameId,
        'gameName': gameName,
        'subject': subject,
        'score': score,
        'totalQuestions': totalQuestions,
        'playedAt': playedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
      };
}
