import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_routes.dart';
import 'widgets/auth_shared_widgets.dart';

/// Tela de entrada exclusiva do aluno.
///
/// Antes, professor e aluno ficavam juntos em `LoginView` (com abas).
/// Essa página contém exatamente o que era a aba "Aluno", só que
/// como uma tela própria, acessada a partir da tela de seleção de perfil.
class StudentLoginView extends StatelessWidget {
  const StudentLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AuthBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go(AppRoutes.login),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        tooltip: 'Voltar',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const AuthLogo(subtitle: 'Portal do Aluno'),
                const SizedBox(height: 32),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1E3C),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🚀', style: TextStyle(fontSize: 56)),
                            const SizedBox(height: 12),
                            const Text('Pronto para a missão?', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text(
                              'Seu professor te dará o código da turma. Use-o para entrar!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF89B4FA), fontSize: 13),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: () => context.go(AppRoutes.studentRoomEntry),
                                icon: const Icon(Icons.vpn_key_outlined),
                                label: const Text('Usar código da turma'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C3AED),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
