class AppRoutes {
  // Splash (decide, ao abrir o app, se já existe sessão salva)
  static const String splash = '/splash';

  // Auth
  static const String login = '/';
  static const String studentRoomEntry = '/student/room';
  static const String studentProfileSetup = '/student/profile';

  // Professor
  static const String professorDashboard = '/professor/dashboard';
  static const String professorResults = '/professor/results';
  static const String professorStudents = '/professor/students';
  static const String professorStudentDetail = '/professor/students/:studentId';

  /// Monta a URL da tela de detalhe substituindo o :studentId pelo id real.
  static String professorStudentDetailPath(String studentId) =>
      '/professor/students/$studentId';
  static const String professorGames = '/professor/games';
  static const String professorEditQuiz = '/professor/games/edit/quiz';
  static const String professorEditSpelling = '/professor/games/edit/spelling';
  static const String professorEditSyllables = '/professor/games/edit/syllables';
  static const String professorEditMath = '/professor/games/edit/math';

  // Student
  static const String studentHome = '/student/home';
  static const String studentGameSelect = '/student/games';
  static const String studentGamePlay = '/student/games/play/:gameId';
  static const String studentRanking = '/student/ranking';

  // Jogos livres (não pedagógicos — sem professor, sem envio de resultado)
  static const String studentCasualGames = '/student/casual';
  static const String casualGamePlay = '/student/casual/:gameId';
  static String casualGamePath(String gameId) => '/student/casual/$gameId';

  // Game-specific routes
  static const String gameCalculos = '/games/calculos';
  static const String gameSoletrar = '/games/soletrar';
  static const String gameForca = '/games/forca';
  static const String gameSilabas = '/games/silabas';
  static const String gamePerguntas = '/games/perguntas';
}
