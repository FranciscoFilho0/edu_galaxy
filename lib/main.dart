import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:audioplayers/audioplayers.dart';

import 'firebase_options.dart';
import 'services/audio_service.dart';
import 'controllers/auth_controller.dart';
import 'controllers/professor_controller.dart';
import 'controllers/student_controller.dart';
import 'controllers/game_content_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/current_room_controller.dart';

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

    debugPrint(
      "Erro Firebase: $e",
    );

  }



  try {

    await AudioService().initialize();

  } catch(e){

    debugPrint(
      "Erro AudioService: $e",
    );

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

      child:
      const EduGalaxyApp(),

    ),

  );

}


Future<void> _configureAudio() async {

  try {

    await AudioPlayer.global.setAudioContext(

      AudioContext(

        android: AudioContextAndroid(

          // Não interrompe outros players
          // (música de fundo continua)

          audioFocus:
              AndroidAudioFocus.none,

        ),

        iOS: AudioContextIOS(

          // Permite mistura de sons no iPhone/iPad

          category:
              AVAudioSessionCategory.playAndRecord,

          options: const {

            AVAudioSessionOptions.mixWithOthers,

          },

        ),

      ),

    );


  } catch (e) {

    debugPrint(
      'Erro ao configurar áudio: $e',
    );

  }

}





class EduGalaxyApp extends StatefulWidget {

  const EduGalaxyApp({
    super.key,
  });


  @override
  State<EduGalaxyApp> createState() =>
      _EduGalaxyAppState();

}



class _EduGalaxyAppState
    extends State<EduGalaxyApp> {


  late final _router =
      createRouter();



  @override
  Widget build(BuildContext context) {


    final auth =
        context.watch<AuthController>();


    // Escuta configurações do aplicativo
    // para atualizar tema em tempo real.

    context.watch<SettingsController>();


    final theme =
        auth.isProfessor
            ? AppTheme.professorTheme()
            : AppTheme.studentTheme();



    return MaterialApp.router(

      title: 'EduGalaxy',

      debugShowCheckedModeBanner:
          false,

      theme:
          theme,

      routerConfig:
          _router,

    );

  }

}