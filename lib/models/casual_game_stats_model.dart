/// Estatísticas locais de um aluno num jogo livre específico. Cobre os
/// dois formatos de "recorde" que os jogos usam:
/// - Jogo da Velha / Damas (contra o computador): vitórias, derrotas,
///   empates e a maior sequência de vitórias seguidas.
/// - Jogo da Memória: menor número de jogadas e menor tempo pra terminar.
class CasualGameStats {
  final int wins;
  final int losses;
  final int draws;
  final int currentStreak;
  final int bestStreak;
  final int? bestMoves;
  final int? bestTimeSeconds;
  final int? bestScore;

  const CasualGameStats({
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.bestMoves,
    this.bestTimeSeconds,
    this.bestScore,
  });

  factory CasualGameStats.empty() => const CasualGameStats();

  int get totalMatches => wins + losses + draws;

  factory CasualGameStats.fromJson(Map<String, dynamic> json) => CasualGameStats(
        wins: json['wins'] ?? 0,
        losses: json['losses'] ?? 0,
        draws: json['draws'] ?? 0,
        currentStreak: json['currentStreak'] ?? 0,
        bestStreak: json['bestStreak'] ?? 0,
        bestMoves: json['bestMoves'],
        bestTimeSeconds: json['bestTimeSeconds'],
        bestScore: json['bestScore'],
      );

  Map<String, dynamic> toJson() => {
        'wins': wins,
        'losses': losses,
        'draws': draws,
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'bestMoves': bestMoves,
        'bestTimeSeconds': bestTimeSeconds,
        'bestScore': bestScore,
      };

  /// Usado pelo Jogo da Velha e por Damas ao final de uma partida contra
  /// o computador. A sequência (streak) zera a cada derrota ou empate.
  CasualGameStats withMatchOutcome(MatchOutcome outcome) {
    switch (outcome) {
      case MatchOutcome.win:
        final newStreak = currentStreak + 1;
        return CasualGameStats(
          wins: wins + 1,
          losses: losses,
          draws: draws,
          currentStreak: newStreak,
          bestStreak: newStreak > bestStreak ? newStreak : bestStreak,
          bestMoves: bestMoves,
          bestTimeSeconds: bestTimeSeconds,
          bestScore: bestScore,
        );
      case MatchOutcome.loss:
        return CasualGameStats(
          wins: wins,
          losses: losses + 1,
          draws: draws,
          currentStreak: 0,
          bestStreak: bestStreak,
          bestMoves: bestMoves,
          bestTimeSeconds: bestTimeSeconds,
          bestScore: bestScore,
        );
      case MatchOutcome.draw:
        return CasualGameStats(
          wins: wins,
          losses: losses,
          draws: draws + 1,
          currentStreak: 0,
          bestStreak: bestStreak,
          bestMoves: bestMoves,
          bestTimeSeconds: bestTimeSeconds,
          bestScore: bestScore,
        );
    }
  }

  /// Usado pelo Jogo da Memória no modo solo: guarda o melhor (menor)
  /// número de jogadas e o melhor (menor) tempo já alcançados.
  CasualGameStats withMemoryRun({required int moves, required int seconds}) {
    final newBestMoves = (bestMoves == null || moves < bestMoves!) ? moves : bestMoves;
    final newBestTime = (bestTimeSeconds == null || seconds < bestTimeSeconds!) ? seconds : bestTimeSeconds;
    return CasualGameStats(
      wins: wins + 1,
      losses: losses,
      draws: draws,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      bestMoves: newBestMoves,
      bestTimeSeconds: newBestTime,
      bestScore: bestScore,
    );
  }

  /// Usado por jogos de pontuação (Tetris, Explosão de Blocos): guarda
  /// o maior placar já alcançado numa partida.
  CasualGameStats withHighScore(int score) {
    final newBestScore = (bestScore == null || score > bestScore!) ? score : bestScore;
    return CasualGameStats(
      wins: wins + 1,
      losses: losses,
      draws: draws,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      bestMoves: bestMoves,
      bestTimeSeconds: bestTimeSeconds,
      bestScore: newBestScore,
    );
  }
}

enum MatchOutcome { win, loss, draw }
