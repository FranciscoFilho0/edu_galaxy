import 'package:flutter/foundation.dart';
import '../models/student_model.dart';
import '../models/game_result_model.dart';
import '../models/room_model.dart';
import '../models/game_model.dart';

class ProfessorController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<StudentModel> _students = [];
  List<GameResultModel> _results = [];
  RoomModel? _room;
  List<GameModel> _games = GameModel.allGames;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<StudentModel> get students => _students;
  List<GameResultModel> get results => _results;
  RoomModel? get room => _room;
  List<GameModel> get games => _games;

  Future<void> loadData(String professorId) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    _students = [
      const StudentModel(id: 's1', name: 'Ana Silva', roomCode: 'ABC123', avatarIndex: '0'),
      const StudentModel(id: 's2', name: 'Bruno Costa', roomCode: 'ABC123', avatarIndex: '2'),
      const StudentModel(id: 's3', name: 'Carla Mendes', roomCode: 'ABC123', avatarIndex: '1'),
      const StudentModel(id: 's4', name: 'Diego Souza', roomCode: 'ABC123', avatarIndex: '3'),
      const StudentModel(id: 's5', name: 'Elena Rocha', roomCode: 'ABC123', avatarIndex: '4'),
    ];

    _results = [
      GameResultModel(
        id: 'r1', studentId: 's1', studentName: 'Ana Silva',
        gameId: 'calculos', gameName: 'Cálculos Espaciais', subject: 'Matemática',
        score: 8, totalQuestions: 10, durationSeconds: 120,
        playedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      GameResultModel(
        id: 'r2', studentId: 's2', studentName: 'Bruno Costa',
        gameId: 'soletrar', gameName: 'Soletrar Espacial', subject: 'Português',
        score: 6, totalQuestions: 10, durationSeconds: 180,
        playedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      GameResultModel(
        id: 'r3', studentId: 's3', studentName: 'Carla Mendes',
        gameId: 'calculos', gameName: 'Cálculos Espaciais', subject: 'Matemática',
        score: 10, totalQuestions: 10, durationSeconds: 95,
        playedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      GameResultModel(
        id: 'r4', studentId: 's4', studentName: 'Diego Souza',
        gameId: 'forca', gameName: 'Forca Galáctica', subject: 'Português',
        score: 5, totalQuestions: 10, durationSeconds: 210,
        playedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      GameResultModel(
        id: 'r5', studentId: 's1', studentName: 'Ana Silva',
        gameId: 'perguntas', gameName: 'Perguntas Espaciais', subject: 'Geral',
        score: 9, totalQuestions: 10, durationSeconds: 110,
        playedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];

    _room = RoomModel(
      code: 'ABC123',
      professorId: professorId,
      professorName: 'Professor',
      students: _students,
      activeSubjects: ['Matemática', 'Português', 'Ciências'],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addStudent(String name) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final newStudent = StudentModel(
      id: 's${_students.length + 1}',
      name: name,
      roomCode: _room?.code ?? '',
      avatarIndex: '${_students.length % 5}',
    );

    _students = [..._students, newStudent];
    _isLoading = false;
    notifyListeners();
    return true;
  }

  void toggleGameActive(String gameId) {
    _games = _games.map((g) {
      if (g.id == gameId) {
        return GameModel(
          id: g.id,
          title: g.title,
          subject: g.subject,
          description: g.description,
          iconEmoji: g.iconEmoji,
          difficulty: g.difficulty,
          isActive: !g.isActive,
        );
      }
      return g;
    }).toList();
    notifyListeners();
  }

  List<GameResultModel> getResultsForStudent(String studentId) {
    return _results.where((r) => r.studentId == studentId).toList();
  }

  double get averageScore {
    if (_results.isEmpty) return 0;
    return _results.map((r) => r.percentage).reduce((a, b) => a + b) / _results.length;
  }
}
