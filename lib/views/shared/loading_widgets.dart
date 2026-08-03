import 'package:flutter/material.dart';

// ── Splash de carregamento reutilizável do EduGalaxy ────────────────────────
//
// Usada em todos os fluxos de entrada do app (login do professor, seleção e
// troca de sala, login do aluno com código da turma, criação de perfil) pra
// esconder o tempo de carregamento dos dados antes de abrir o Dashboard do
// professor ou a Base do aluno, no lugar de uma tela em branco ou de um
// spinner solto.
//
// Não tem Scaffold próprio de propósito: pode ser usada tanto como body
// inteiro de uma tela que já tem seu próprio Scaffold (ex.: Dashboard,
// Base do aluno) quanto como camada de cobertura total (Positioned.fill)
// sobre uma tela que ainda está montada (ex.: tela de seleção de sala,
// enquanto os dados carregam antes de navegar pro Dashboard).
//
// As cores vêm do Theme.of(context) (mesmo ColorScheme usado no resto do
// app, tanto no tema claro/profissional do professor quanto no tema escuro
// "galáxia" do aluno), então o fundo já segue automaticamente o tema
// claro/escuro ativo no momento — sem precisar duplicar paletas aqui.
class AppLoadingSplash extends StatefulWidget {
  final String? message;

  const AppLoadingSplash({super.key, this.message});

  @override
  State<AppLoadingSplash> createState() => _AppLoadingSplashState();
}

class _AppLoadingSplashState extends State<AppLoadingSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                final scale = 0.92 + (_pulseCtrl.value * 0.12);
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.secondary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withOpacity(0.5),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.rocket_launch,
                    color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'EduGalaxy',
              style: TextStyle(
                color: isDark ? Colors.white : scheme.primary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.message ?? 'Carregando...',
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF89B4FA)
                    : scheme.primary.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alterna entre o conteúdo normal de uma tela e a [AppLoadingSplash],
/// com uma transição suave (fade), conforme [isLoading]. Pensada para telas
/// que já controlam seu próprio carregamento inicial de dados através de um
/// controller (ex.: Dashboard do professor, Base do aluno), substituindo o
/// `CircularProgressIndicator` solto que existia antes.
class LoadingGate extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingGate({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: isLoading
          ? AppLoadingSplash(key: const ValueKey('loading'), message: message)
          : KeyedSubtree(key: const ValueKey('content'), child: child),
    );
  }
}

/// Cobre uma tela inteira com a [AppLoadingSplash] enquanto [isLoading] for
/// verdadeiro, sem desmontar o [child] por baixo (a tela continua viva,
/// só fica escondida atrás da splash). Usada nos pontos de entrada onde o
/// carregamento acontece antes de navegar para a próxima tela (login do
/// professor/aluno, entrar/trocar de sala, criar perfil do aluno).
///
/// A camada de carregamento é opaca e absorve todos os toques (via
/// [AbsorbPointer]), então nenhum botão por baixo pode ser clicado enquanto
/// os dados ainda estão sendo carregados.
class LoadingOverlayStack extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlayStack({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: 1,
                child: AppLoadingSplash(message: message),
              ),
            ),
          ),
      ],
    );
  }
}
