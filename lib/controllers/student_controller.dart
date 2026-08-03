
import 'package:flutter/foundation.dart';
import '../models/game_model.dart';
import '../models/game_result_model.dart';
import '../models/ranking_entry_model.dart';
import '../models/achievement_model.dart';
import '../services/firestore_service.dart';
import '../services/audio_service.dart';
import 'achievements_engine.dart';

class StudentController extends ChangeNotifier {
  final FirestoreService _db = FirestoreService.instance;

  bool _isLoading = false;
  List<GameModel> _availableGames = [];
  List<GameResultModel> _myResults = [];
  List<RankingEntryModel> _ranking = [];

  Set<String> _previousAchievementIds = {};

  bool get isLoading => _isLoading;
  List<GameModel> get availableGames => _availableGames;
  List<GameResultModel> get myResults => _myResults;
  List<RankingEntryModel> get ranking => _ranking;

  int get totalStars {
    return _myResults.fold(0, (sum, r) => sum + r.score);
  }

  int get gamesPlayed => _myResults.length;

  /// Conquistas do aluno (desbloqueadas e em progresso), recalculadas a
  /// partir dos resultados já carregados.
  List<AchievementProgress> get achievements =>
      AchievementsEngine.compute(_myResults);

  /// Carrega os jogos ativados pelo professor daquela sala e os resultados
  /// já registrados pelo aluno.
  Future<void> loadGames({
    required String roomId,
    required String studentId,
  }) async {
    if (roomId.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final activation = await _db.fetchGamesActivation(roomId: roomId);

      _availableGames = GameModel.allGames
          .where((g) => activation[g.id] ?? true)
          .toList();

      final allResults = await _db.fetchResults(roomId: roomId);

      _myResults = allResults
          .where((r) => r.studentId == studentId)
          .toList();

      // Guarda as conquistas já desbloqueadas antes de novas partidas.
      _previousAchievementIds = achievements
          .where((a) => a.unlocked)
          .map((a) => a.achievement.id)
          .toSet();

    } catch (e) {
      debugPrint('Erro ao carregar jogos do aluno: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Registra o resultado de uma partida e verifica novas conquistas.
  Future<void> saveResult({
    required String roomId,
    required GameResultModel result,
  }) async {
    try {
      // Estado das conquistas antes do novo resultado.
      final beforeAchievements = achievements
          .where((a) => a.unlocked)
          .map((a) => a.achievement.id)
          .toSet();

      await _db.saveResult(
        roomId: roomId,
        result: result,
      );

      _myResults = [
        result,
        ..._myResults,
      ];

      // Estado das conquistas depois do novo resultado.
      final afterAchievements = achievements
          .where((a) => a.unlocked)
          .map((a) => a.achievement.id)
          .toSet();

      // Detecta somente conquistas novas.
      final unlockedNow =
          afterAchievements.difference(beforeAchievements);

      if (unlockedNow.isNotEmpty) {
        AudioService().playCongratulations();
      }

      _previousAchievementIds = afterAchievements;

      notifyListeners();

    } catch (e) {
      debugPrint('Erro ao salvar resultado: $e');
    }
  }

  /// Monta o ranking da turma.
  Future<void> loadRanking(String roomId) async {
    if (roomId.isEmpty) return;

    try {
      final students = await _db.fetchStudents(roomId: roomId);
      final results = await _db.fetchResults(roomId: roomId);

      final starsByStudent = <String, int>{};

      for (final r in results) {
        starsByStudent[r.studentId] =
            (starsByStudent[r.studentId] ?? 0) + r.score;
      }

      final entries = students
          .map(
            (s) => RankingEntryModel(
              studentId: s.id,
              name: s.name,
              avatarIndex: s.avatarIndex,
              stars: starsByStudent[s.id] ?? 0,
            ),
          )
          .toList()
        ..sort(
          (a, b) => b.stars.compareTo(a.stars),
        );

      _ranking = entries;

      notifyListeners();

    } catch (e) {
      debugPrint('Erro ao carregar ranking: $e');
    }
  }
}
