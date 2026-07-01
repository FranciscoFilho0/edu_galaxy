import 'package:flutter/foundation.dart';
import '../models/game_model.dart';
import '../models/game_result_model.dart';

class StudentController extends ChangeNotifier {
  bool _isLoading = false;
  List<GameModel> _availableGames = [];
  List<GameResultModel> _myResults = [];

  bool get isLoading => _isLoading;
  List<GameModel> get availableGames => _availableGames;
  List<GameResultModel> get myResults => _myResults;

  int get totalStars {
    return _myResults.fold(0, (sum, r) => sum + r.score);
  }

  int get gamesPlayed => _myResults.length;

  Future<void> loadGames(String roomCode) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    _availableGames = GameModel.allGames.where((g) => g.isActive).toList();

    _myResults = [
      GameResultModel(
        id: 'r1', studentId: 'me', studentName: 'Eu',
        gameId: 'calculos', gameName: 'Cálculos Espaciais', subject: 'Matemática',
        score: 8, totalQuestions: 10, durationSeconds: 120,
        playedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      GameResultModel(
        id: 'r2', studentId: 'me', studentName: 'Eu',
        gameId: 'soletrar', gameName: 'Soletrar Espacial', subject: 'Português',
        score: 7, totalQuestions: 10, durationSeconds: 150,
        playedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }
}
