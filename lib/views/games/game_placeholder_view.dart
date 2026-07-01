import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/game_model.dart';

class GamePlaceholderView extends StatelessWidget {
  final String gameId;
  const GamePlaceholderView({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    final game = GameModel.allGames.firstWhere(
      (g) => g.id == gameId,
      orElse: () => const GameModel(
        id: 'unknown', title: 'Jogo', subject: '?',
        description: '', iconEmoji: '🎮', difficulty: 'Médio',
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.galaxyDeep,
      body: Stack(
        children: [
          // Animated-looking background
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppTheme.galaxyPurple.withOpacity(0.3), Colors.transparent]),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => context.go(AppRoutes.studentGameSelect),
                    ),
                  ),
                  const Spacer(),
                  Text(game.iconEmoji, style: const TextStyle(fontSize: 80)),
                  const SizedBox(height: 20),
                  Text(game.title, style: const TextStyle(
                    color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold,
                  )),
                  const SizedBox(height: 8),
                  Text(game.subject, style: const TextStyle(color: AppTheme.galaxyCyan, fontSize: 16, letterSpacing: 1)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.galaxyMid,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.galaxyPurple.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Text('🛸', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        const Text('Em desenvolvimento!', style: TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,
                        )),
                        const SizedBox(height: 8),
                        Text(game.description, textAlign: TextAlign.center, style: const TextStyle(
                          color: Color(0xFF89B4FA), fontSize: 14,
                        )),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => context.go(AppRoutes.studentGameSelect),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Voltar aos Jogos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.galaxyPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
