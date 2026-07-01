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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ProfessorController()),
        ChangeNotifierProvider(create: (_) => StudentController()),
        ChangeNotifierProvider(create: (_) => GameContentController()..loadContent()),
      ],
      child: const EduGalaxyApp(),
    ),
  );
}

class EduGalaxyApp extends StatelessWidget {
  const EduGalaxyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final router = createRouter();

    final theme = auth.isProfessor
        ? AppTheme.professorTheme()
        : AppTheme.studentTheme();

    return MaterialApp.router(
      title: 'EduGalaxy',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: router,
    );
  }
}
