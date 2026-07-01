import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../../views/auth/login_view.dart';
import '../../views/auth/student_room_entry_view.dart';
import '../../views/auth/student_profile_setup_view.dart';
import '../../views/professor/professor_dashboard_view.dart';
import '../../views/professor/professor_results_view.dart';
import '../../views/professor/professor_students_view.dart';
import '../../views/professor/professor_games_view.dart';
import '../../views/professor/content_editors/quiz_editor_view.dart';
import '../../views/professor/content_editors/word_list_editor_view.dart';
import '../../views/professor/content_editors/math_config_editor_view.dart';
import '../../views/student/student_home_view.dart';
import '../../views/student/student_game_select_view.dart';
import '../../views/student/student_ranking_view.dart';
import '../../views/games/game_placeholder_view.dart';
import '../../views/games/calculos/calculos_game_view.dart';
import '../../views/games/soletrar/soletrar_game_view.dart';
import '../../views/games/forca/forca_game_view.dart';
import '../../views/games/silabas/silabas_game_view.dart';
import '../../views/games/perguntas/perguntas_game_view.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.login,
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: AppRoutes.studentRoomEntry,
        builder: (context, state) => const StudentRoomEntryView(),
      ),
      GoRoute(
        path: AppRoutes.studentProfileSetup,
        builder: (context, state) {
          final roomCode = state.uri.queryParameters['roomCode'] ?? '';
          return StudentProfileSetupView(roomCode: roomCode);
        },
      ),

      // ── Professor (ShellRoute for bottom nav) ────────────────────────────
      ShellRoute(
        builder: (context, state, child) => ProfessorShell(child: child, state: state),
        routes: [
          GoRoute(
            path: AppRoutes.professorDashboard,
            builder: (context, state) => const ProfessorDashboardView(),
          ),
          GoRoute(
            path: AppRoutes.professorResults,
            builder: (context, state) => const ProfessorResultsView(),
          ),
          GoRoute(
            path: AppRoutes.professorStudents,
            builder: (context, state) => const ProfessorStudentsView(),
          ),
          GoRoute(
            path: AppRoutes.professorGames,
            builder: (context, state) => const ProfessorGamesView(),
          ),
        ],
      ),

      // ── Student (ShellRoute for bottom nav) ──────────────────────────────
      ShellRoute(
        builder: (context, state, child) => StudentShell(child: child, state: state),
        routes: [
          GoRoute(
            path: AppRoutes.studentHome,
            builder: (context, state) => const StudentHomeView(),
          ),
          GoRoute(
            path: AppRoutes.studentGameSelect,
            builder: (context, state) => const StudentGameSelectView(),
          ),
          GoRoute(
            path: AppRoutes.studentRanking,
            builder: (context, state) => const StudentRankingView(),
          ),
        ],
      ),

      GoRoute(
        path: AppRoutes.studentGamePlay,
        builder: (context, state) {
          final gameId = state.pathParameters['gameId'] ?? '';
          switch (gameId) {
            case 'calculos':
              return const CalculosGameView();
            case 'soletrar':
              return const SoletrarGameView();
            case 'forca':
              return const ForcaGameView();
            case 'silabas':
              return const SilabasGameView();
            case 'perguntas':
              return const PerguntasGameView();
            default:
              return GamePlaceholderView(gameId: gameId);
          }
        },
      ),

      // ── Professor content editors ────────────────────────────────────────
      GoRoute(
        path: AppRoutes.professorEditQuiz,
        builder: (context, state) => const QuizEditorView(),
      ),
      GoRoute(
        path: AppRoutes.professorEditSpelling,
        builder: (context, state) => const WordListEditorView(type: WordListType.spelling),
      ),
      GoRoute(
        path: AppRoutes.professorEditSyllables,
        builder: (context, state) => const WordListEditorView(type: WordListType.syllables),
      ),
      GoRoute(
        path: AppRoutes.professorEditMath,
        builder: (context, state) => const MathConfigEditorView(),
      ),
    ],
  );
}

// ── Professor Shell (bottom navigation bar) ──────────────────────────────────
class ProfessorShell extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const ProfessorShell({super.key, required this.child, required this.state});

  int _selectedIndex(String location) {
    if (location.startsWith(AppRoutes.professorResults)) return 1;
    if (location.startsWith(AppRoutes.professorStudents)) return 2;
    if (location.startsWith(AppRoutes.professorGames)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final idx = _selectedIndex(state.uri.toString());

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go(AppRoutes.professorDashboard);
            case 1: context.go(AppRoutes.professorResults);
            case 2: context.go(AppRoutes.professorStudents);
            case 3: context.go(AppRoutes.professorGames);
          }
        },
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.primary.withOpacity(0.15),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Resultados'),
          NavigationDestination(icon: Icon(Icons.people_outlined), selectedIcon: Icon(Icons.people), label: 'Alunos'),
          NavigationDestination(icon: Icon(Icons.games_outlined), selectedIcon: Icon(Icons.games), label: 'Jogos'),
        ],
      ),
    );
  }
}

// ── Student Shell (bottom navigation bar, galactic style) ────────────────────
class StudentShell extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const StudentShell({super.key, required this.child, required this.state});

  int _selectedIndex(String location) {
    if (location.startsWith(AppRoutes.studentGameSelect)) return 1;
    if (location.startsWith(AppRoutes.studentRanking)) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _selectedIndex(state.uri.toString());

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1E3C),
          border: Border(top: BorderSide(color: Color(0xFF7C3AED), width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: idx,
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFF7C3AED).withOpacity(0.3),
          onDestinationSelected: (i) {
            switch (i) {
              case 0: context.go(AppRoutes.studentHome);
              case 1: context.go(AppRoutes.studentGameSelect);
              case 2: context.go(AppRoutes.studentRanking);
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.rocket_launch_outlined, color: Color(0xFF89B4FA)),
              selectedIcon: Icon(Icons.rocket_launch, color: Color(0xFFB45AF2)),
              label: 'Base',
            ),
            NavigationDestination(
              icon: Icon(Icons.videogame_asset_outlined, color: Color(0xFF89B4FA)),
              selectedIcon: Icon(Icons.videogame_asset, color: Color(0xFFB45AF2)),
              label: 'Jogos',
            ),
            NavigationDestination(
              icon: Icon(Icons.leaderboard_outlined, color: Color(0xFF89B4FA)),
              selectedIcon: Icon(Icons.leaderboard, color: Color(0xFFB45AF2)),
              label: 'Ranking',
            ),
          ],
        ),
      ),
    );
  }
}
