import 'package:flutter/foundation.dart';
import '../models/game_model.dart';
import '../models/game_result_model.dart';
import '../models/ranking_entry_model.dart';
import '../models/achievement_model.dart';
import '../services/firestore_service.dart';
import 'achievements_engine.dart';

class StudentController extends ChangeNotifier {
  final FirestoreService _db = FirestoreService.instance;

  bool _isLoading = false;
  List<GameModel> _availableGames = [];
  List<GameResultModel> _myResults = [];
  List<RankingEntryModel> _ranking = [];

  bool get isLoading => _isLoading;
  List<GameModel> get availableGames => _availableGames;
  List<GameResultModel> get myResults => _myResults;
  List<RankingEntryModel> get ranking => _ranking;

  int get totalStars {
    return _myResults.fold(0, (sum, r) => sum + r.score);
  }

  int get gamesPlayed => _myResults.length;

  /// Conquistas do aluno (desbloqueadas e em progresso), recalculadas a
  /// partir dos resultados já carregados — não precisa de nenhuma consulta
  /// extra ao banco de dados.
  List<AchievementProgress> get achievements => AchievementsEngine.compute(_myResults);

  /// Carrega os jogos ativados pelo professor daquela sala e os resultados
  /// já registrados por este aluno específico.
  Future<void> loadGames({
    required String professorId,
    required String studentId,
  }) async {
    if (professorId.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      final activation = await _db.fetchGamesActivation(professorId);
      _availableGames = GameModel.allGames.where((g) => activation[g.id] ?? true).toList();

      final allResults = await _db.fetchResults(professorId);
      _myResults = allResults.where((r) => r.studentId == studentId).toList();
    } catch (e) {
      debugPrint('Erro ao carregar jogos do aluno: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Registra o resultado de uma partida no banco, já vinculado à sala do
  /// professor correto, e atualiza a lista local para refletir na hora.
  Future<void> saveResult({
    required String professorId,
    required GameResultModel result,
  }) async {
    try {
      await _db.saveResult(professorId: professorId, result: result);
      _myResults = [result, ..._myResults];
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao salvar resultado: $e');
    }
  }

  /// Monta o ranking da turma: pega todos os alunos daquela sala, soma as
  /// estrelas (acertos) de cada um em todos os jogos, e ordena do maior
  /// para o menor. Sempre da sala do professor certo — nunca mistura turmas.
  Future<void> loadRanking(String professorId) async {
    if (professorId.isEmpty) return;

    try {
      final students = await _db.fetchStudents(professorId);
      final results = await _db.fetchResults(professorId);

      final starsByStudent = <String, int>{};
      for (final r in results) {
        starsByStudent[r.studentId] = (starsByStudent[r.studentId] ?? 0) + r.score;
      }

      final entries = students
          .map((s) => RankingEntryModel(
                studentId: s.id,
                name: s.name,
                avatarIndex: s.avatarIndex,
                stars: starsByStudent[s.id] ?? 0,
              ))
          .toList()
        ..sort((a, b) => b.stars.compareTo(a.stars));

      _ranking = entries;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar ranking: $e');
    }
  }
}
