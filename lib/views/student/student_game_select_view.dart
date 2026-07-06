import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/student_controller.dart';
import '../../models/game_model.dart';
import '../../core/theme/app_theme.dart';

class StudentGameSelectView extends StatelessWidget {
  const StudentGameSelectView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<StudentController>();

    return Scaffold(
      backgroundColor: AppTheme.galaxyDeep,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Missões Disponíveis', style: TextStyle(
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold,
                  )),
                  const SizedBox(height: 4),
                  Text('${ctrl.availableGames.length} jogos desbloqueados', style: const TextStyle(
                    color: AppTheme.galaxyCyan, fontSize: 13,
                  )),
                ],
              ),
            ),
            Expanded(
              child: ctrl.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.galaxyViolet))
                  : ctrl.availableGames.isEmpty
                      ? _NoGamesWidget()
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, 
                            crossAxisSpacing: 14, 
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.78,
                          ),
                          itemCount: ctrl.availableGames.length,
                          itemBuilder: (context, i) => _GameCard(game: ctrl.availableGames[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final GameModel game;
  const _GameCard({required this.game});

  Color get _cardColor {
    switch (game.subject) {
      case 'Matemática': return const Color(0xFF7C3AED);
      case 'Português': return const Color(0xFF0891B2);
      case 'Ciências': return const Color(0xFF059669);
      case 'História': return const Color(0xFFD97706);
      case 'Geografia': return const Color(0xFF0284C7);
      default: return const Color(0xFF7C3AED);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/student/games/play/${game.id}'),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_cardColor, _cardColor.withOpacity(0.6)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _cardColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -16, top: -16,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.iconEmoji, style: const TextStyle(fontSize: 36)),
                  const Spacer(),
                  Text(
                    game.title, 
                    style: const TextStyle(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    game.subject, 
                    style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            game.difficulty, 
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoGamesWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🛸', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text('Nenhuma missão disponível', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Seu professor ainda não liberou os jogos.', style: TextStyle(color: Color(0xFF89B4FA), fontSize: 14)),
        ],
      ),
    );
  }
}