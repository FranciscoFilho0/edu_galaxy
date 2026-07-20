import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/router/app_routes.dart';

/// Primeira tela que abre quando o app inicia.
///
/// Ela não tem nenhum botão: só existe pra dar tempo do [AuthController]
/// checar se já existe uma sessão salva (professor logado pelo Firebase
/// Auth, ou aluno salvo localmente pelo SharedPreferences) antes de decidir
/// pra onde mandar o usuário — tela de login, dashboard do professor ou
/// base do aluno.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    // Espera o primeiro frame ser desenhado antes de mexer no router,
    // porque context.go() não pode ser chamado durante o build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSession());
  }

  Future<void> _checkSession() async {
    final auth = context.read<AuthController>();
    await auth.tryAutoLogin();

    if (!mounted) return;

    if (auth.isProfessor) {
      context.go(AppRoutes.professorDashboard);
    } else if (auth.currentStudent != null) {
      context.go(AppRoutes.studentHome);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1B6E), Color(0xFF1A237E), Color(0xFF0A0E27)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.rocket_launch, color: Colors.white, size: 56),
              SizedBox(height: 20),
              CircularProgressIndicator(color: Color(0xFF7C3AED)),
            ],
          ),
        ),
      ),
    );
  }
}
