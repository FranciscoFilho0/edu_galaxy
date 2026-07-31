import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/professor_controller.dart';
import 'controllers/student_controller.dart';
import 'controllers/game_content_controller.dart';
import 'controllers/settings_controller.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'controllers/current_room_controller.dart';

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

    ChangeNotifierProvider(
      create: (_) => AuthController(),
    ),

    ChangeNotifierProvider(
      create: (_) => ProfessorController(),
    ),

    ChangeNotifierProvider(
      create: (_) => CurrentRoomController(),
    ),

    ChangeNotifierProvider(
      create: (_) => StudentController(),
    ),

    ChangeNotifierProvider(
      create: (_) => GameContentController(),
    ),

    ChangeNotifierProvider(
      create: (_) => SettingsController(),
    ),

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
    // Também escuta o SettingsController: quando o professor liga/desliga o
    // modo noturno, isso muda as cores em AppTheme e precisamos reconstruir
    // o MaterialApp para o novo ThemeData valer.
    context.watch<SettingsController>();
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