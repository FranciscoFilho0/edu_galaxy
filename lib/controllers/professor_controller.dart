import 'package:flutter/foundation.dart';
import '../models/student_model.dart';
import '../models/game_result_model.dart';
import '../models/room_model.dart';
import '../models/game_model.dart';
import '../services/firestore_service.dart';

class ProfessorController extends ChangeNotifier {
  final FirestoreService _db = FirestoreService.instance;

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

  /// Carrega a sala, os alunos, os resultados e os jogos ativos desse
  /// professor — tudo filtrado pelo professorId, então um professor nunca
  /// enxerga dado de outro.
  Future<void> loadData(String professorId, {String professorName = 'Professor'}) async {
    if (professorId.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      final room = await _db.getOrCreateRoom(professorId: professorId, professorName: professorName);
      final students = await _db.fetchStudents(professorId);
      final results = await _db.fetchResults(professorId);
      final activation = await _db.fetchGamesActivation(professorId);

      _room = room;
      _students = students;
      _results = results;
      _games = GameModel.allGames
          .map((g) => GameModel(
                id: g.id,
                title: g.title,
                subject: g.subject,
                description: g.description,
                iconEmoji: g.iconEmoji,
                difficulty: g.difficulty,
                isActive: activation[g.id] ?? true,
              ))
          .toList();
    } catch (e) {
      _errorMessage = 'Não foi possível carregar os dados da turma.';
      debugPrint('Erro ao carregar dados do professor: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addStudent(String name) async {
    if (_room == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final newStudent = await _db.addStudent(
        professorId: _room!.professorId,
        roomCode: _room!.code,
        name: name,
        avatarIndex: '${_students.length % 5}',
      );
      _students = [..._students, newStudent];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Erro ao cadastrar aluno: $e');
      return false;
    }
  }

  /// Renomeia um aluno já cadastrado. Atualiza o banco e a lista local
  /// (inclusive o studentName guardado nos resultados antigos, só na
  /// exibição — o histórico no banco mantém o nome de quando o jogo foi
  /// jogado).
  Future<bool> updateStudentName(String studentId, String newName) async {
    final name = newName.trim();
    if (_room == null || name.isEmpty) return false;

    try {
      await _db.updateStudentName(
        professorId: _room!.professorId,
        studentId: studentId,
        name: name,
      );
      _students = _students
          .map((s) => s.id == studentId ? s.copyWith(name: name) : s)
          .toList();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erro ao renomear aluno: $e');
      return false;
    }
  }

  /// Exclui o aluno e seus resultados, e atualiza as listas locais.
  Future<bool> deleteStudent(String studentId) async {
    if (_room == null) return false;

    try {
      await _db.deleteStudent(professorId: _room!.professorId, studentId: studentId);
      _students = _students.where((s) => s.id != studentId).toList();
      _results = _results.where((r) => r.studentId != studentId).toList();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erro ao excluir aluno: $e');
      return false;
    }
  }

  Future<void> toggleGameActive(String gameId) async {
    if (_room == null) return;
    final game = _games.firstWhere((g) => g.id == gameId);
    final newValue = !game.isActive;

    // Atualiza a tela imediatamente...
    _games = _games.map((g) {
      if (g.id == gameId) {
        return GameModel(
          id: g.id, title: g.title, subject: g.subject, description: g.description,
          iconEmoji: g.iconEmoji, difficulty: g.difficulty, isActive: newValue,
        );
      }
      return g;
    }).toList();
    notifyListeners();

    // ...e depois salva no banco, para o aluno passar a ver a mudança.
    await _db.setGameActive(_room!.professorId, gameId, newValue);
  }

  /// Tenta trocar o código da sala. Retorna false se o código já estiver em uso.
  Future<bool> changeRoomCode(String newCode) async {
    if (_room == null) return false;
    final ok = await _db.changeRoomCode(
      professorId: _room!.professorId,
      currentCode: _room!.code,
      newCode: newCode,
    );
    if (ok) {
      _room = _room!.copyWith(code: newCode.trim().toUpperCase());
      notifyListeners();
    }
    return ok;
  }

  List<GameResultModel> getResultsForStudent(String studentId) {
    return _results.where((r) => r.studentId == studentId).toList();
  }

  double get averageScore {
    if (_results.isEmpty) return 0;
    return _results.map((r) => r.percentage).reduce((a, b) => a + b) / _results.length;
  }
}
