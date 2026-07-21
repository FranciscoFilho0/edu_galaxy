import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_routes.dart';
import 'widgets/auth_shared_widgets.dart';

/// Tela de seleção de perfil.
///
/// Primeira tela que o usuário vê ao abrir o app (depois da splash), caso
/// não haja sessão salva. Aqui ele escolhe se é "Professor" ou "Aluno" e é
/// enviado para a tela de login correspondente:
///   - Professor -> ProfessorLoginView (AppRoutes.professorLogin)
///   - Aluno     -> StudentLoginView   (AppRoutes.studentLogin)
///
/// Antes, professor e aluno faziam login na mesma tela usando abas, o que
/// deixava tudo meio misturado. Agora cada perfil tem sua própria página.
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AuthBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AuthLogo(),
                  const SizedBox(height: 8),
                  const Text(
                    'Quem está entrando?',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 40),
                  _ProfileOptionCard(
                    emoji: '👨‍🏫',
                    title: 'Sou Professor',
                    subtitle: 'Acompanhe o progresso da turma',
                    onTap: () => context.go(AppRoutes.professorLogin),
                  ),
                  const SizedBox(height: 20),
                  _ProfileOptionCard(
                    emoji: '🚀',
                    title: 'Sou Aluno',
                    subtitle: 'Entrar com o código da turma',
                    onTap: () => context.go(AppRoutes.studentLogin),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Cartão de opção usado na tela de seleção de perfil.
class _ProfileOptionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileOptionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1E3C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)]),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF89B4FA), fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF89B4FA)),
          ],
        ),
      ),
    );
  }
}
