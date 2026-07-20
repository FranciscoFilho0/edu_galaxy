import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/casual_game_stats_model.dart';

/// Guarda os recordes dos jogos livres direto no aparelho do aluno, sem
/// passar pelo Firestore e sem vínculo nenhum com professor/sala. Por
/// isso não recebe professorId nem studentId — é por aparelho mesmo,
/// igual um jogo qualquer salva seu "high score" localmente.
///
/// Cada jogo tem sua própria chave (`casual_stats_<gameId>`) guardando um
/// JSON com o CasualGameStats daquele jogo.
class CasualRecordsService {
  static const _prefix = 'casual_stats_';

  Future<CasualGameStats> loadStats(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$gameId');
    if (raw == null) return CasualGameStats.empty();
    try {
      return CasualGameStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return CasualGameStats.empty();
    }
  }

  Future<void> _save(String gameId, CasualGameStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$gameId', jsonEncode(stats.toJson()));
  }

  /// Registra o resultado de uma partida contra o computador (Jogo da
  /// Velha ou Damas) e devolve as estatísticas já atualizadas.
  Future<CasualGameStats> recordMatchOutcome(String gameId, MatchOutcome outcome) async {
    final current = await loadStats(gameId);
    final updated = current.withMatchOutcome(outcome);
    await _save(gameId, updated);
    return updated;
  }

  /// Registra uma partida solo do Jogo da Memória.
  Future<CasualGameStats> recordMemoryRun(String gameId, {required int moves, required int seconds}) async {
    final current = await loadStats(gameId);
    final updated = current.withMemoryRun(moves: moves, seconds: seconds);
    await _save(gameId, updated);
    return updated;
  }

  /// Registra o placar final de uma partida de jogo de pontuação
  /// (Tetris, Explosão de Blocos) e devolve as estatísticas atualizadas,
  /// já com o recorde recalculado se o placar dessa partida for maior.
  Future<CasualGameStats> recordHighScore(String gameId, int score) async {
    final current = await loadStats(gameId);
    final updated = current.withHighScore(score);
    await _save(gameId, updated);
    return updated;
  }
}
