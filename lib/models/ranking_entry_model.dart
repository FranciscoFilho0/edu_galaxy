/// Uma linha do ranking da turma: um aluno e o total de estrelas (soma dos
/// acertos em todos os jogos) que ele já conquistou. É calculado, não é
/// salvo direto no banco — vem da junção dos alunos com os resultados.
class RankingEntryModel {
  final String studentId;
  final String name;
  final String avatarIndex;
  final int stars;

  const RankingEntryModel({
    required this.studentId,
    required this.name,
    required this.avatarIndex,
    required this.stars,
  });
}
