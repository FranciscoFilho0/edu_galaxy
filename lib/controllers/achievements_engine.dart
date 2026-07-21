import '../models/achievement_model.dart';
import '../models/game_model.dart';
import '../models/game_result_model.dart';

/// Calcula, a partir do histórico de resultados de um aluno, quais
/// conquistas já foram desbloqueadas e o progresso das que faltam.
///
/// Importante: essa classe não depende de Firestore nem de nada externo —
/// só usa a lista de [GameResultModel] que o `StudentController` já carrega
/// normalmente. Ou seja, as conquistas não exigem nenhuma tabela nova no
/// banco de dados: tudo é recalculado na hora, a partir dos resultados que
/// já existem.
class AchievementsEngine {
  /// Catálogo fixo de conquistas existentes no app. Para adicionar uma nova
  /// conquista no futuro, basta acrescentar aqui e no `compute()` abaixo.
  static const List<AchievementModel> all = [
    AchievementModel(
      id: 'first_game',
      title: 'Primeira Missão',
      description: 'Jogue sua primeira partida.',
      emoji: '🎮',
    ),
    AchievementModel(
      id: 'games_10',
      title: 'Explorador',
      description: 'Jogue 10 partidas.',
      emoji: '🚀',
    ),
    AchievementModel(
      id: 'games_25',
      title: 'Veterano Espacial',
      description: 'Jogue 25 partidas.',
      emoji: '🛸',
    ),
    AchievementModel(
      id: 'stars_50',
      title: 'Colecionador de Estrelas',
      description: 'Junte 50 estrelas no total.',
      emoji: '⭐',
    ),
    AchievementModel(
      id: 'stars_150',
      title: 'Mestre das Estrelas',
      description: 'Junte 150 estrelas no total.',
      emoji: '🌟',
    ),
    AchievementModel(
      id: 'perfect_score',
      title: 'Perfeição!',
      description: 'Acerte 100% das perguntas em uma partida.',
      emoji: '💯',
    ),
    AchievementModel(
      id: 'math_master',
      title: 'Gênio da Matemática',
      description: 'Média de 70% ou mais em 5 partidas de Matemática.',
      emoji: '🔢',
    ),
    AchievementModel(
      id: 'portuguese_master',
      title: 'Craque do Português',
      description: 'Média de 70% ou mais em 5 partidas de Português.',
      emoji: '🔤',
    ),
    AchievementModel(
      id: 'all_subjects',
      title: 'Todo-Terreno',
      description: 'Jogue ao menos uma vez em cada matéria disponível.',
      emoji: '🧭',
    ),
    AchievementModel(
      id: 'streak_3',
      title: 'Em Chamas',
      description: 'Jogue em 3 dias seguidos.',
      emoji: '🔥',
    ),
  ];

  static AchievementModel _find(String id) => all.firstWhere((a) => a.id == id);

  /// Limita [value] a no máximo [max] (só pra não mostrar, por exemplo,
  /// "37/10" numa barra de progresso que já bateu a meta).
  static int _capped(int value, int max) => value > max ? max : value;

  static List<AchievementProgress> compute(List<GameResultModel> results) {
    final totalGames = results.length;
    final totalStars = results.fold<int>(0, (sum, r) => sum + r.score);
    final hasPerfectScore = results.any((r) => r.totalQuestions > 0 && r.score == r.totalQuestions);

    double averageFor(String subject) {
      final list = results.where((r) => r.subject == subject).toList();
      if (list.isEmpty) return 0;
      return list.map((r) => r.percentage).reduce((a, b) => a + b) / list.length;
    }

    int countFor(String subject) => results.where((r) => r.subject == subject).length;

    final mathCount = countFor('Matemática');
    final mathAverage = averageFor('Matemática');
    final portugueseCount = countFor('Português');
    final portugueseAverage = averageFor('Português');

    // Matérias que existem no catálogo de jogos do app (não só as ativadas
    // pelo professor), usadas como meta da conquista "Todo-Terreno".
    final availableSubjects = {for (final g in GameModel.allGames) g.subject};
    final playedSubjects = {for (final r in results) r.subject}..retainAll(availableSubjects);

    final longestStreak = _longestStreakInDays(results);

    return [
      AchievementProgress(
        achievement: _find('first_game'),
        unlocked: totalGames >= 1,
        current: _capped(totalGames, 1),
        target: 1,
      ),
      AchievementProgress(
        achievement: _find('games_10'),
        unlocked: totalGames >= 10,
        current: _capped(totalGames, 10),
        target: 10,
      ),
      AchievementProgress(
        achievement: _find('games_25'),
        unlocked: totalGames >= 25,
        current: _capped(totalGames, 25),
        target: 25,
      ),
      AchievementProgress(
        achievement: _find('stars_50'),
        unlocked: totalStars >= 50,
        current: _capped(totalStars, 50),
        target: 50,
      ),
      AchievementProgress(
        achievement: _find('stars_150'),
        unlocked: totalStars >= 150,
        current: _capped(totalStars, 150),
        target: 150,
      ),
      AchievementProgress(
        achievement: _find('perfect_score'),
        unlocked: hasPerfectScore,
        current: hasPerfectScore ? 1 : 0,
        target: 1,
      ),
      AchievementProgress(
        achievement: _find('math_master'),
        unlocked: mathCount >= 5 && mathAverage >= 70,
        current: _capped(mathCount, 5),
        target: 5,
      ),
      AchievementProgress(
        achievement: _find('portuguese_master'),
        unlocked: portugueseCount >= 5 && portugueseAverage >= 70,
        current: _capped(portugueseCount, 5),
        target: 5,
      ),
      AchievementProgress(
        achievement: _find('all_subjects'),
        unlocked: availableSubjects.isNotEmpty && playedSubjects.length == availableSubjects.length,
        current: playedSubjects.length,
        target: availableSubjects.length,
      ),
      AchievementProgress(
        achievement: _find('streak_3'),
        unlocked: longestStreak >= 3,
        current: _capped(longestStreak, 3),
        target: 3,
      ),
    ];
  }

  /// Maior sequência de dias seguidos em que o aluno jogou pelo menos uma
  /// partida (compara só o dia, ignorando o horário).
  static int _longestStreakInDays(List<GameResultModel> results) {
    if (results.isEmpty) return 0;

    final days = <DateTime>{
      for (final r in results) DateTime(r.playedAt.year, r.playedAt.month, r.playedAt.day),
    }.toList()
      ..sort();

    int longest = 1;
    int current = 1;
    for (int i = 1; i < days.length; i++) {
      final diff = days[i].difference(days[i - 1]).inDays;
      if (diff == 1) {
        current += 1;
        if (current > longest) longest = current;
      } else if (diff > 1) {
        current = 1;
      }
    }
    return longest;
  }
}
