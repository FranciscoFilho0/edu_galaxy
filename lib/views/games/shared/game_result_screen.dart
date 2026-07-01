import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';

class GameResultScreen extends StatelessWidget {
  final String gameEmoji;
  final String gameTitle;
  final int score;
  final int total;
  final int durationSeconds;
  final VoidCallback onPlayAgain;

  const GameResultScreen({
    super.key,
    required this.gameEmoji,
    required this.gameTitle,
    required this.score,
    required this.total,
    required this.durationSeconds,
    required this.onPlayAgain,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (score / total * 100).round() : 0;
    final stars = total > 0 ? (score / total * 3).round().clamp(0, 3) : 0;
    final mins = durationSeconds ~/ 60;
    final secs = durationSeconds % 60;

    final String message;
    final String emoji;
    if (pct >= 80) {
      message = 'Incrível! Você é um verdadeiro explorador!';
      emoji = '🌟';
    } else if (pct >= 50) {
      message = 'Muito bem! Continue explorando!';
      emoji = '🚀';
    } else {
      message = 'Boa tentativa! Vamos treinar mais!';
      emoji = '🛰️';
    }

    return Scaffold(
      backgroundColor: AppTheme.galaxyDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(emoji, style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold,
              )),
              const SizedBox(height: 4),
              Text(gameTitle, style: const TextStyle(color: AppTheme.galaxyCyan, fontSize: 14)),
              const SizedBox(height: 28),
              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    color: AppTheme.galaxyStar,
                    size: 48,
                  ),
                )),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.galaxyMid,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.galaxyPurple.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn(label: 'Acertos', value: '$score/$total'),
                    _VerticalDivider(),
                    _StatColumn(label: 'Aproveitamento', value: '$pct%'),
                    _VerticalDivider(),
                    _StatColumn(label: 'Tempo', value: '${mins}m ${secs}s'),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: onPlayAgain,
                  icon: const Icon(Icons.replay),
                  label: const Text('Jogar Novamente', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.galaxyPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.studentGameSelect),
                  icon: const Icon(Icons.rocket_launch, color: Colors.white),
                  label: const Text('Outras Missões', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.galaxyCyan),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label, value;
  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF89B4FA), fontSize: 11)),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: AppTheme.galaxyPurple.withOpacity(0.3));
  }
}
