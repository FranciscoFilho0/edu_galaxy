/// Descreve uma conquista/badge disponível no app: só os dados fixos
/// (título, descrição, emoji). Quem decide se ela está desbloqueada e qual
/// o progresso atual é o `AchievementsEngine`, então esse modelo não sabe
/// nada sobre resultados de jogos.
class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String emoji;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
  });
}

/// Uma conquista já calculada para um aluno específico: o `AchievementModel`
/// (dados fixos) + se está desbloqueada + o progresso atual rumo à meta
/// (ex.: 7 de 10 partidas jogadas).
class AchievementProgress {
  final AchievementModel achievement;
  final bool unlocked;
  final int current;
  final int target;

  const AchievementProgress({
    required this.achievement,
    required this.unlocked,
    required this.current,
    required this.target,
  });

  /// Progresso de 0.0 a 1.0, para exibir numa barrinha de progresso.
  double get progressRatio {
    if (target <= 0) return 0.0;
    final ratio = current / target;
    return ratio > 1.0 ? 1.0 : ratio;
  }
}
