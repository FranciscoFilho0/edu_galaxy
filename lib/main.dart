import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/professor_controller.dart';
import 'controllers/student_controller.dart';
import 'controllers/game_content_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("Erro ao inicializar Firebase: $e");
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ProfessorController()),
        ChangeNotifierProvider(create: (_) => StudentController()),
        // O conteúdo dos jogos agora é por sala/professor, então só é carregado
        // depois do login (professor) ou depois de entrar na turma (aluno) —
        // veja professor_dashboard_view.dart e student_home_view.dart.
        ChangeNotifierProvider(create: (_) => GameContentController()),
      ],
      child: const EduGalaxyApp(),
    ),
  );
}

class EduGalaxyApp extends StatefulWidget {
  const EduGalaxyApp({super.key});

  @override
  State<EduGalaxyApp> createState() => _EduGalaxyAppState();
}

class _EduGalaxyAppState extends State<EduGalaxyApp> {
  late final _router = createRouter();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final theme = auth.isProfessor
        ? AppTheme.professorTheme()
        : AppTheme.studentTheme();

    return MaterialApp.router(
      title: 'EduGalaxy',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: _router,
    );
  }
}