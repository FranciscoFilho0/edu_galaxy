class GameModel {
  final String id;
  final String title;
  final String subject;
  final String description;
  final String iconEmoji;
  final String difficulty;
  final bool isActive;

  const GameModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.iconEmoji,
    required this.difficulty,
    this.isActive = true,
  });

  static List<GameModel> get allGames => [
        const GameModel(
          id: 'calculos',
          title: 'Cálculos Espaciais',
          subject: 'Matemática',
          description: 'Resolva contas de soma, subtração, multiplicação e divisão!',
          iconEmoji: '🔢',
          difficulty: 'Médio',
        ),
        const GameModel(
          id: 'soletrar',
          title: 'Soletrar Espacial',
          subject: 'Português',
          description: 'Monte as palavras usando as letras embaralhadas!',
          iconEmoji: '🔤',
          difficulty: 'Fácil',
        ),
        const GameModel(
          id: 'forca',
          title: 'Forca Galáctica',
          subject: 'Português',
          description: 'Salve o astronauta adivinhando a palavra letra por letra!',
          iconEmoji: '🪐',
          difficulty: 'Médio',
        ),
        const GameModel(
          id: 'silabas',
          title: 'Quebra-Sílabas',
          subject: 'Português',
          description: 'Organize as sílabas para formar a palavra correta!',
          iconEmoji: '🧩',
          difficulty: 'Fácil',
        ),
        const GameModel(
          id: 'perguntas',
          title: 'Perguntas Espaciais',
          subject: 'Geral',
          description: 'Responda perguntas de várias matérias pela galáxia!',
          iconEmoji: '❓',
          difficulty: 'Médio',
        ),
      ];
}
